"""Recipe recommendation with Gemini ranking and a reliable rule-based fallback."""

from __future__ import annotations

import json
import os
import time
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.models import Recipe, User
from app.routers.recipes import _recipe_to_response
from app.services.query_parser import SmartQuery, parse_smart_query


PROJECT_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(PROJECT_ROOT / ".env")

MAX_CANDIDATES = 8
DEFAULT_TIMEOUT_SECONDS = 25
COOLDOWN_SECONDS = 60
_gemini_unavailable_until = 0.0


class GeminiSelection(BaseModel):
    recipe_ids: list[int] = Field(max_length=3)
    summary: str = Field(max_length=300)


def fallback_response_database(query: str, recipes: list[dict]) -> dict:
    """Return the response shape even when there are no published recipes."""

    return {
        "query": query,
        "mode": "rule-based",
        "summary": "No published recipes are available yet.",
        "recipes": recipes[:3],
        "cautions": ["Try again after recipes have been added to the database."],
    }


def _matches_constraints(recipe: dict, constraints: SmartQuery) -> bool:
    """Return True only when a recipe satisfies every parsed request condition."""

    recipe_tags = {tag.strip().lower() for tag in recipe["dietary_tags"]}
    requested_tags = {tag.lower() for tag in constraints.dietary_tags}
    if requested_tags and not requested_tags.issubset(recipe_tags):
        return False

    if constraints.price_max is not None and recipe["estimated_cost"] > constraints.price_max:
        return False

    total_minutes = recipe["prep_time"] + recipe["cook_time"]
    if constraints.max_minutes is not None and total_minutes > constraints.max_minutes:
        return False

    if constraints.ingredient:
        ingredient = constraints.ingredient.lower()
        if not any(ingredient in item.lower() for item in recipe["ingredients"]):
            return False

    return True


def _rank_database_recipes(
    recipes: list[dict],
    constraints: SmartQuery,
    current_user: User,
) -> list[dict]:
    """Rank matches using saved recipes, ratings, price and cooking time."""

    saved_recipes = list(current_user.saved_recipes)
    saved_recipe_ids = {int(recipe.recipe_id) for recipe in saved_recipes}
    saved_cuisines = {
        recipe.cuisine.cuisine_name.lower()
        for recipe in saved_recipes
        if recipe.cuisine is not None
    }

    ranked: list[tuple[float, dict]] = []
    for recipe in recipes:
        if not _matches_constraints(recipe, constraints):
            continue

        score = float(recipe["rating"]) / 5.0
        if recipe["id"] in saved_recipe_ids:
            score += 5.0
        if recipe["cuisine"].lower() in saved_cuisines:
            score += 1.0
        ranked.append((score, recipe))

    ranked.sort(
        key=lambda item: (
            -item[0],
            item[1]["estimated_cost"],
            item[1]["prep_time"] + item[1]["cook_time"],
            item[1]["title"].lower(),
        )
    )
    return [recipe for _, recipe in ranked]


def rule_based_response(query: str, recipes: list[dict]) -> dict:
    """Return a transparent, reliable recommendation without a live model call."""

    if recipes:
        summary = (
            "Recipes ranked by your request, saved recipes, rating, "
            "estimated cost and cooking time."
        )
        cautions = [
            "Recommendations use the current database information.",
            "Please check ingredient labels before cooking.",
        ]
    else:
        summary = "No published recipes match every condition in your request."
        cautions = [
            "Try increasing your budget, removing one condition, or using another ingredient.",
        ]

    return {
        "query": query,
        "mode": "rule-based",
        "summary": summary,
        "recipes": recipes[:3],
        "cautions": cautions,
    }


def _timeout_seconds() -> int:
    try:
        configured = int((os.getenv("GEMINI_TIMEOUT_SECONDS") or DEFAULT_TIMEOUT_SECONDS).strip())
    except ValueError:
        configured = DEFAULT_TIMEOUT_SECONDS
    return min(max(configured, 1), 25)


def _gemini_is_on_cooldown() -> bool:
    return time.monotonic() < _gemini_unavailable_until


def _mark_gemini_unavailable() -> None:
    global _gemini_unavailable_until
    _gemini_unavailable_until = time.monotonic() + COOLDOWN_SECONDS


def _select_with_gemini(api_key: str, model: str, prompt: str, timeout_seconds: int):
    """Make one bounded Gemini request; never let SDK retries block the web API."""

    def request_gemini():
        from google import genai
        from google.genai import types

        client = genai.Client(
            api_key=api_key,
            http_options=types.HttpOptions(
                timeout=timeout_seconds * 1000,
                retry_options=types.HttpRetryOptions(attempts=1),
            ),
        )
        return client.interactions.create(
            model=model,
            input=prompt,
            generation_config={"thinking_level": "minimal"},
            response_format={
                "type": "text",
                "mime_type": "application/json",
                "schema": GeminiSelection.model_json_schema(),
            },
        )

    executor = ThreadPoolExecutor(max_workers=1)
    future = None
    try:
        future = executor.submit(request_gemini)
        return future.result(timeout=timeout_seconds)
    except FutureTimeoutError as error:
        if future is not None:
            future.cancel()
        raise TimeoutError("Gemini response exceeded the AI time limit") from error
    finally:
        executor.shutdown(wait=False, cancel_futures=True)


def recommend_recipes(db: Session, query: str, current_user: User) -> dict:
    """Recommend verified database recipes, with Gemini as an optional final ranker.

    The function deliberately does not read Profile preferences. It only uses
    the user's explicit query and saved recipes.
    """

    constraints = parse_smart_query(query)
    database_recipes = db.query(Recipe).filter(Recipe.status == "published").all()
    recipes = [_recipe_to_response(recipe, db) for recipe in database_recipes]
    if not recipes:
        return fallback_response_database(query, [])

    ranked_recipes = _rank_database_recipes(recipes, constraints, current_user)
    if not ranked_recipes:
        return rule_based_response(query, [])

    if _gemini_is_on_cooldown():
        return rule_based_response(query, ranked_recipes)

    candidates = [
        {
            "id": recipe["id"],
            "title": recipe["title"],
            "cuisine": recipe["cuisine"],
            "estimated_cost": recipe["estimated_cost"],
            "dietary_tags": recipe["dietary_tags"],
            "ingredients": recipe["ingredients"],
            "total_minutes": recipe["prep_time"] + recipe["cook_time"],
        }
        for recipe in ranked_recipes[:MAX_CANDIDATES]
    ]

    api_key = (os.getenv("GEMINI_API_KEY") or "").strip()
    model = (os.getenv("GEMINI_MODEL") or "").strip()
    if not api_key or not model:
        return rule_based_response(query, ranked_recipes)

    prompt = f"""
You are UniMeal's recipe-ranking assistant.
Choose up to three recipe IDs from the candidate recipes only.
Use the user's natural-language request to rank the candidates.
Do not invent recipes, ingredients, prices, dietary claims, allergy claims, or IDs.
Return JSON only.

User query:
{query}

Candidate recipes:
{json.dumps(candidates, ensure_ascii=False)}
"""

    try:
        response = _select_with_gemini(api_key, model, prompt, _timeout_seconds())
        if not response.output_text:
            raise ValueError("Gemini response is empty")
        selection = GeminiSelection.model_validate_json(response.output_text)

        recipes_by_id = {recipe["id"]: recipe for recipe in ranked_recipes}
        selected_recipes = []
        for recipe_id in selection.recipe_ids:
            if recipe_id in recipes_by_id and recipe_id not in {
                recipe["id"] for recipe in selected_recipes
            }:
                selected_recipes.append(recipes_by_id[recipe_id])

        if not selected_recipes:
            raise ValueError("Gemini did not select a valid candidate")

        return {
            "query": query,
            "mode": "live",
            "summary": selection.summary,
            "recipes": selected_recipes,
            "cautions": ["Please check ingredient labels before cooking."],
        }
    except Exception as error:
        _mark_gemini_unavailable()
        print(f"Gemini unavailable; using rule-based recommendation: {error}")
        return rule_based_response(query, ranked_recipes)
