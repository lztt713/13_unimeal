"""Recipe search and read helpers for the real MySQL schema."""

from __future__ import annotations

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models import (
    Cuisine,
    DietaryTag,
    Ingredient,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeRating,
    recipe_dietary_tags,
)
from app.schemas import RecipeSearchParams


def _tag_search_value(tag: str) -> str:
    return tag.strip().replace("-", " ")


def search_recipes(
    db: Session,
    params: RecipeSearchParams,
) -> list[Recipe]:
    """Search published recipes in Qichen's normalized MySQL schema."""
    query = db.query(Recipe).outerjoin(Recipe.cuisine).filter(Recipe.status == "published")

    if params.search:
        needle = f"%{params.search.strip()}%"
        matching_ingredient_recipe_ids = (
            select(RecipeIngredient.recipe_id)
            .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.ingredient_id)
            .where(Ingredient.ingredient_name.ilike(needle))
        )

        query = query.filter(
            or_(
                Recipe.title.ilike(needle),
                Recipe.description.ilike(needle),
                Cuisine.cuisine_name.ilike(needle),
                Recipe.recipe_id.in_(matching_ingredient_recipe_ids),
            )
        )

    if params.cuisine:
        query = query.filter(Cuisine.cuisine_name == params.cuisine)

    if params.difficulty:
        query = query.filter(Recipe.difficulty == params.difficulty.lower())

    if params.price_max is not None:
        price_per_serving = Recipe.estimated_cost / func.nullif(Recipe.servings, 0)
        query = query.filter(price_per_serving <= params.price_max)

    if params.dietary_tags:
        for tag in params.dietary_tags:
            tag_value = _tag_search_value(tag)
            matching_tag_recipe_ids = (
                select(recipe_dietary_tags.c.recipe_id)
                .join(DietaryTag, DietaryTag.dietary_tag_id == recipe_dietary_tags.c.dietary_tag_id)
                .where(func.replace(DietaryTag.tag_name, "-", " ").ilike(tag_value))
            )
            query = query.filter(Recipe.recipe_id.in_(matching_tag_recipe_ids))

    rating_subquery = (
        select(func.coalesce(func.avg(RecipeRating.rating), 0))
        .where(RecipeRating.recipe_id == Recipe.recipe_id)
        .scalar_subquery()
    )
    cost_per_serving = Recipe.estimated_cost / func.nullif(Recipe.servings, 0)
    cook_time = Recipe.preparation_minutes + Recipe.cooking_minutes
    sort_column = {
        "rating": rating_subquery,
        "cost": cost_per_serving,
        "cook_time": cook_time,
    }.get(params.sort_by)

    if sort_column is None:
        sort_column = rating_subquery
        sort_desc = True
    else:
        sort_desc = params.sort_order == "desc"

    query = query.order_by(sort_column.desc() if sort_desc else sort_column.asc(), Recipe.title.asc())
    return query.all()


def get_recipe_ingredients(db: Session, recipe_id: int) -> list[dict]:
    """Return detailed ingredient info for a recipe, including cost breakdown."""
    rows = (
        db.query(RecipeIngredient, Ingredient, MeasurementUnit)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.ingredient_id)
        .join(MeasurementUnit, RecipeIngredient.measurement_unit_id == MeasurementUnit.measurement_unit_id)
        .filter(RecipeIngredient.recipe_id == recipe_id)
        .order_by(RecipeIngredient.sort_order.asc())
        .all()
    )

    result = []
    for recipe_ingredient, ingredient, unit in rows:
        quantity = float(recipe_ingredient.quantity)
        unit_price = float(ingredient.estimated_unit_cost)
        result.append(
            {
                "ingredient_id": int(ingredient.ingredient_id),
                "name": ingredient.ingredient_name,
                "quantity": quantity,
                "unit": unit.unit_symbol,
                "unit_price": unit_price,
                "cost": round(quantity * unit_price, 2),
            }
        )
    return result
