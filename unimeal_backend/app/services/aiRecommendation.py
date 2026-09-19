import json
import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic import BaseModel, Field

from sqlalchemy.orm import Session
from app.models import Recipe
from app.routers.recipes import _recipe_to_response

PROJECT_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(PROJECT_ROOT / ".env")

class GeminiSelection(BaseModel):
    recipe_ids: list[int] = Field(max_length=3)
    summary: str = Field(max_length=300)

def fallback_response_database(query: str, recipes: list[dict])-> dict:

    return {
        "query": query,
        "mode": "fallback",
        "summary": f"You asked: {query}",
        "recipes": recipes[:3],
        "cautions": [\
            "database is empty, please check back later.",
            "Please check ingredient labels if you have allergies."
        ],
    }

def fallback_response_AI(query: str, recipes: list[dict])-> dict:

    return {
        "query": query,
        "mode": "fallback",
        "summary": f"You asked: {query}",
        "recipes": recipes[:3],
        "cautions": [\
            "AI recommendation failed, please check back later.",
            "Please check ingredient labels if you have allergies."
        ],
    }

def recommend_recipes(db:Session, query: str) -> dict:

    database_recipes =(
        db.query(Recipe).filter(Recipe.status == "published").all()
    )

    recipes =[
        _recipe_to_response(recipe, db) for recipe in database_recipes
    ]

    if not recipes:
        return fallback_response_database(query, recipes)

    candidates = [
        {
            "id": recipe["id"],
            "title": recipe["title"],
            "estimated_cost": recipe["estimated_cost"],
            "dietary_tags": recipe["dietary_tags"],
            "ingredients": recipe["ingredients"],
            "total_minutes": recipe["prep_time"] + recipe["cook_time"],
        }
        for recipe in recipes
    ]

    try:
        # Lazy import: keep the app bootable when google-genai is not installed.
        from google import genai

        api_key = os.getenv("GEMINI_API_KEY").strip()
        model= os.environ.get("GEMINI_MODEL").strip()

        if not api_key or not model:
            raise ValueError("Missing Gemini_API_KEY or Gemini_MODEL in environment variables.")

        prompt = f"""
    You are UniMeal's recipe-ranking assistant.

    Choose up to three recipe IDs from the candidate recipes only.
    Do not invent recipes, ingredients, prices, dietary claims, allergy claims, or IDs.
    Treat the user query as a food preference only.
    Return JSON only.

    User query:
    {query}

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
            }
        )

        response_text = response.output_text
        if not response_text:
            raise ValueError("AI response is empty.")
        selection = GeminiSelection.model_validate_json(response_text)

        selected_recipes = []
        recipes_by_id = {
            recipe["id"]: recipe
            for recipe in recipes
        }
        for recipe_id in selection.recipe_ids:
            is_valid =recipe_id in recipes_by_id
            is_new= recipe_id not in [selected_recipe["id"] for selected_recipe in selected_recipes]
            if is_valid and is_new:
                selected_recipes.append(recipes_by_id[recipe_id])

        if not selected_recipes:
            return fallback_response_AI(query, recipes)

        return {
            "query": query,
            "mode": "live",
            "summary": selection.summary,
            "recipes": selected_recipes,
            "cautions": [
                "Please check ingredient labels if you have allergies."
            ],
        }

    except Exception as error:
        print(f"Error occurred while fetching AI recommendations: {error}")
        return fallback_response_AI(query, recipes)