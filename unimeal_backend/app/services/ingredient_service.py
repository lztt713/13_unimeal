"""Ingredient merging and procurement cost calculation."""

from collections import defaultdict

from sqlalchemy.orm import Session

from app.models import Ingredient, MeasurementUnit, RecipeIngredient


def merge_ingredients(
    db: Session,
    recipe_ids: list[int],
) -> tuple[list[dict], float]:
    """Merge equivalent ingredient/unit rows across multiple recipes."""
    if not recipe_ids:
        return [], 0.0

    rows = (
        db.query(RecipeIngredient, Ingredient, MeasurementUnit)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.ingredient_id)
        .join(MeasurementUnit, RecipeIngredient.measurement_unit_id == MeasurementUnit.measurement_unit_id)
        .filter(RecipeIngredient.recipe_id.in_(recipe_ids))
        .all()
    )

    grouped: dict[tuple[int, int], dict] = {}
    quantity_map: dict[tuple[int, int], float] = defaultdict(float)

    for recipe_ingredient, ingredient, unit in rows:
        key = (int(ingredient.ingredient_id), int(unit.measurement_unit_id))
        quantity_map[key] += float(recipe_ingredient.quantity)
        grouped[key] = {
            "ingredient_id": int(ingredient.ingredient_id),
            "name": ingredient.ingredient_name,
            "unit": unit.unit_symbol,
            "unit_price": float(ingredient.estimated_unit_cost),
        }

    merged: list[dict] = []
    total_cost = 0.0

    for key, total_quantity in quantity_map.items():
        item = grouped[key]
        item_cost = round(total_quantity * item["unit_price"], 2)
        total_cost += item_cost
        merged.append(
            {
                **item,
                "total_quantity": round(total_quantity, 2),
                "total_cost": item_cost,
            }
        )

    merged.sort(key=lambda item: item["name"].lower())
    return merged, round(total_cost, 2)


def calculate_recipe_cost(db: Session, recipe_id: int) -> float:
    """Calculate a recipe's whole-recipe cost from ingredient reference prices."""
    rows = (
        db.query(RecipeIngredient, Ingredient)
        .join(Ingredient, RecipeIngredient.ingredient_id == Ingredient.ingredient_id)
        .filter(RecipeIngredient.recipe_id == recipe_id)
        .all()
    )

    total = 0.0
    for recipe_ingredient, ingredient in rows:
        total += float(recipe_ingredient.quantity) * float(ingredient.estimated_unit_cost)

    return round(total, 2)
