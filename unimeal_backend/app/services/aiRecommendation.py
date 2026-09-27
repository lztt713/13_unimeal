"""Profile-aware AI and deterministic recipe recommendations."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.models import Recipe, User
from app.routers.recipes import _recipe_to_response


PROJECT_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(PROJECT_ROOT / ".env")


class GeminiSelection(BaseModel):
    recipe_ids: list[int] = Field(max_length=3)
    summary: str = Field(max_length=300)


LIMITED_KITCHEN_EQUIPMENT = {"microwave", "kettle", "toaster"}


def _profile_context(user: User | None) -> dict:
    if user is None:
        return {
            "weekly_budget": 0.0,
            "dietary_preferences": [],
            "allergies": [],
            "cooking_skill": None,
            "kitchen_access": None,
            "favourite_cuisines": [],
            "saved_recipe_ids": [],
        }
    return {
        "weekly_budget": float(user.weekly_budget or 0),
        "dietary_preferences": [tag.tag_name for tag in user.dietary_preferences],
        "allergies": [allergy.allergy_name for allergy in user.allergies],
        "cooking_skill": user.cooking_skill,
        "kitchen_access": user.kitchen_access,
        "favourite_cuisines": [
            item.strip() for item in (user.favourite_cuisines_note or "").split(",") if item.strip()
        ],
        "saved_recipe_ids": [int(recipe.recipe_id) for recipe in user.saved_recipes],
    }


def _query_number(pattern: str, query: str) -> float | None:
    match = re.search(pattern, query, flags=re.IGNORECASE)
    if not match:
        return None
    value = next((group for group in match.groups() if group is not None), None)
    return float(value) if value is not None else None


def _safe_for_profile(recipe: dict, profile: dict) -> bool:
    allergens = {item.lower() for item in recipe.get("allergen_tags", [])}
    if allergens.intersection(item.lower() for item in profile["allergies"]):
        return False

    required = {item["name"].lower() for item in recipe.get("required_equipment", [])}
    kitchen_access = profile.get("kitchen_access")
    if kitchen_access == "none" and required:
        return False
    if kitchen_access == "limited" and not required.issubset(LIMITED_KITCHEN_EQUIPMENT):
        return False
    return True


def _filter_and_rank(recipes: list[dict], query: str, profile: dict) -> list[dict]:
    query_lower = query.lower()
    safe = [recipe for recipe in recipes if _safe_for_profile(recipe, profile)]

    preferences = {item.lower() for item in profile["dietary_preferences"]}
    if preferences:
        safe = [
            recipe
            for recipe in safe
            if preferences.issubset({tag.lower() for tag in recipe.get("dietary_tags", [])})
        ]

    explicit_budget = _query_number(
        r"(?:under|below|less than|max(?:imum)?|up to)\s*\$?\s*(\d+(?:\.\d+)?)|\$(\d+(?:\.\d+)?)",
        query,
    )
    budget_limit = explicit_budget or (profile["weekly_budget"] if profile["weekly_budget"] > 0 else None)
    if budget_limit is not None:
        safe = [recipe for recipe in safe if float(recipe.get("estimated_cost", 0)) <= budget_limit]

    time_limit = _query_number(
        r"(?:under|below|less than|max(?:imum)?|up to)\s*(\d+)\s*(?:minutes?|mins?)",
        query,
    )
    if time_limit is not None:
        safe = [
            recipe
            for recipe in safe
            if int(recipe.get("prep_time", 0)) + int(recipe.get("cook_time", 0)) <= time_limit
        ]

    known_tags = {tag.lower() for recipe in recipes for tag in recipe.get("dietary_tags", [])}
    requested_tags = {tag for tag in known_tags if tag in query_lower}
    if requested_tags:
        safe = [
            recipe
            for recipe in safe
            if requested_tags.issubset({tag.lower() for tag in recipe.get("dietary_tags", [])})
        ]

    known_cuisines = {recipe.get("cuisine", "").lower() for recipe in recipes}
    requested_cuisines = {cuisine for cuisine in known_cuisines if cuisine and cuisine in query_lower}
    if requested_cuisines:
        safe = [recipe for recipe in safe if recipe.get("cuisine", "").lower() in requested_cuisines]

    known_ingredients = {
        ingredient.lower()
        for recipe in recipes
        for ingredient in recipe.get("ingredients", [])
        if len(ingredient) >= 3
    }
    requested_ingredients = {ingredient for ingredient in known_ingredients if ingredient in query_lower}
    if requested_ingredients:
        safe = [
            recipe
            for recipe in safe
            if requested_ingredients.intersection(item.lower() for item in recipe.get("ingredients", []))
        ]

    favourites = {item.lower() for item in profile["favourite_cuisines"]}
    saved_ids = set(profile["saved_recipe_ids"])
    saved_recipes = [recipe for recipe in recipes if recipe["id"] in saved_ids]
    saved_tags = {tag.lower() for recipe in saved_recipes for tag in recipe.get("dietary_tags", [])}
    saved_cuisines = {recipe.get("cuisine", "").lower() for recipe in saved_recipes}

    def score(recipe: dict) -> tuple:
        tags = {tag.lower() for tag in recipe.get("dietary_tags", [])}
        cuisine = recipe.get("cuisine", "").lower()
        preference_score = len(tags.intersection(preferences))
        affinity_score = len(tags.intersection(saved_tags)) + int(cuisine in saved_cuisines)
        favourite_score = int(cuisine in favourites)
        return (-preference_score, -favourite_score, -affinity_score, float(recipe["estimated_cost"]), recipe["id"])

    return sorted(safe, key=score)


def _fallback_response(query: str, recipes: list[dict], reason: str) -> dict:
    if recipes:
        summary = "Here are the best database matches for your request and saved profile."
        cautions = [reason, "Please check ingredient labels before cooking."]
    else:
        summary = "No recipes match your query and saved safety preferences."
        cautions = [
            "Try a broader query or update your budget, dietary preferences, allergies, or kitchen access.",
            "Please check ingredient labels before cooking.",
        ]
    return {
        "query": query,
        "mode": "fallback",
        "summary": summary,
        "recipes": recipes[:3],
        "cautions": cautions,
    }


def recommend_recipes(db: Session, query: str, user: User | None = None) -> dict:
    database_recipes = db.query(Recipe).filter(Recipe.status == "published").all()
    all_recipes = [_recipe_to_response(recipe, db) for recipe in database_recipes]
    profile = _profile_context(user)
    recipes = _filter_and_rank(all_recipes, query, profile)

    if not all_recipes:
        return _fallback_response(query, [], "The recipe database is empty.")
    if not recipes:
        return _fallback_response(query, [], "No safe database match was found.")

    candidates = [
        {
            "id": recipe["id"],
            "title": recipe["title"],
            "cuisine": recipe["cuisine"],
            "estimated_cost": recipe["estimated_cost"],
            "dietary_tags": recipe["dietary_tags"],
            "allergen_tags": recipe["allergen_tags"],
            "ingredients": recipe["ingredients"],
            "required_equipment": [item["name"] for item in recipe["required_equipment"]],
            "total_minutes": recipe["prep_time"] + recipe["cook_time"],
        }
        for recipe in recipes
    ]

    try:
        from google import genai

        api_key = (os.getenv("GEMINI_API_KEY") or "").strip()
        model = (os.getenv("GEMINI_MODEL") or "").strip()
        if not api_key or not model:
            raise ValueError("Gemini is not configured")

        prompt = f"""
You are UniMeal's recipe-ranking assistant.
Choose up to three recipe IDs from the supplied candidates only.
Respect the user's allergies, dietary preferences, budget, kitchen access, and query.
Do not invent recipes, ingredients, prices, dietary claims, allergy claims, or IDs.
Return JSON only.

User query:
{query}

Saved profile constraints:
{json.dumps(profile)}

Candidate recipes:
{json.dumps(candidates)}
"""
        client = genai.Client(api_key=api_key)
        response = client.interactions.create(
            model=model,
            input=prompt,
            response_format={
                "type": "text",
                "mime_type": "application/json",
                "schema": GeminiSelection.model_json_schema(),
            },
        )
        if not response.output_text:
            raise ValueError("AI response is empty")
        selection = GeminiSelection.model_validate_json(response.output_text)

        recipes_by_id = {recipe["id"]: recipe for recipe in recipes}
        selected = []
        for recipe_id in selection.recipe_ids:
            if recipe_id in recipes_by_id and recipe_id not in {item["id"] for item in selected}:
                selected.append(recipes_by_id[recipe_id])
        if not selected:
            raise ValueError("AI did not select a valid candidate")

        return {
            "query": query,
            "mode": "live",
            "summary": selection.summary,
            "recipes": selected,
            "cautions": ["Please check ingredient labels before cooking."],
        }
    except Exception:
        return _fallback_response(query, recipes, "Live AI was unavailable, so database ranking was used.")
