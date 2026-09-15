"""Recipe search and business logic."""

from __future__ import annotations

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models import Ingredient, Recipe, RecipeIngredient
from app.schemas import RecipeSearchParams


def search_recipes(
    db: Session,
    params: RecipeSearchParams,
) -> list[Recipe]:
    """Multi-condition recipe search.

    Supports filtering by:
    - Free-text search on title, cuisine, and ingredient names
    - Cuisine type
    - Difficulty level
    - Max price per serving
    - Dietary tags
    - Sort by rating / cost / cook time
    """
    query = db.query(Recipe)

    # ── Free-text search across title, cuisine, ingredients ─────────────────
    if params.search:
        needle = f"%{params.search.strip()}%"
        # Subquery: find recipe IDs whose ingredients match the search term
        matching_ingredient_recipe_ids = (
            db.query(RecipeIngredient.recipe_id)
            .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.id)
            .filter(Ingredient.name.ilike(needle))
            .subquery()
        )

        query = query.filter(
            or_(
                Recipe.title.ilike(needle),
                Recipe.cuisine.ilike(needle),
                Recipe.id.in_(matching_ingredient_recipe_ids),
            )
        )

    # ── Cuisine filter ──────────────────────────────────────────────────────
    if params.cuisine:
        query = query.filter(Recipe.cuisine == params.cuisine)

    # ── Difficulty filter ───────────────────────────────────────────────────
    if params.difficulty:
        query = query.filter(Recipe.difficulty == params.difficulty)

    # ── Price ceiling filter ────────────────────────────────────────────────
    if params.price_max is not None:
        query = query.filter(Recipe.estimated_cost <= params.price_max)

    # ── Dietary tags filter ─────────────────────────────────────────────────
    if params.dietary_tags:
        for tag in params.dietary_tags:
            # dietary_tags stored as comma-separated string; use LIKE
            query = query.filter(Recipe.dietary_tags.contains(tag))

    # ── Sorting ─────────────────────────────────────────────────────────────
    sort_column = {
        "rating": Recipe.rating,
        "cost": Recipe.estimated_cost,
        "cook_time": Recipe.cook_time,
    }.get(params.sort_by)

    if sort_column is not None:
        if params.sort_order == "desc":
            query = query.order_by(sort_column.desc())
        else:
            query = query.order_by(sort_column.asc())
    else:
        # Default: highest rated first
        query = query.order_by(Recipe.rating.desc())

    return query.all()


def get_recipe_ingredients(db: Session, recipe_id: int) -> list[dict]:
    """Return detailed ingredient info for a recipe, including cost breakdown."""
    rows = (
        db.query(RecipeIngredient, Ingredient)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.id)
        .filter(RecipeIngredient.recipe_id == recipe_id)
        .all()
    )

    result = []
    for ri, ing in rows:
        result.append(
            {
                "ingredient_id": ing.id,
                "name": ing.name,
                "quantity": ri.quantity,
                "unit": ing.unit,
                "unit_price": ing.unit_price,
                "cost": round(ri.quantity * ing.unit_price, 2),
            }
        )
    return result
