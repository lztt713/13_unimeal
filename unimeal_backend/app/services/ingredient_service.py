"""Ingredient deduplication, merging, and procurement cost calculation."""

from collections import defaultdict

from sqlalchemy.orm import Session

from app.models import Ingredient, Recipe, RecipeIngredient


def merge_ingredients(
    db: Session,
    recipe_ids: list[int],
) -> tuple[list[dict], float]:
    """Merge identical ingredients across multiple recipes and calculate total cost.

    This is the core "ingredient deduplication and merging" logic — when a
    student adds several recipes to their meal plan, identical ingredients
    (e.g. "chicken" appearing in two different recipes) are merged into one
    line item with the summed quantity, so the shopping list is clean and
    the procurement cost is accurate.

    Returns:
        (merged_items, total_procurement_cost)
        merged_items: list of dicts with keys
            ingredient_id, name, unit, total_quantity, unit_price, total_cost
    """
    if not recipe_ids:
        return [], 0.0

    # Fetch all recipe-ingredient rows for the requested recipes
    recipe_ingredients = (
        db.query(RecipeIngredient)
        .filter(RecipeIngredient.recipe_id.in_(recipe_ids))
        .all()
    )

    # Aggregate quantities by ingredient_id
    quantity_map: dict[int, float] = defaultdict(float)
    ingredient_ids: set[int] = set()

    for ri in recipe_ingredients:
        quantity_map[ri.ingredient_id] += ri.quantity
        ingredient_ids.add(ri.ingredient_id)

    if not ingredient_ids:
        return [], 0.0

    # Fetch ingredient master data (names, units, prices)
    ingredients = (
        db.query(Ingredient)
        .filter(Ingredient.id.in_(ingredient_ids))
        .all()
    )
    ingredient_map: dict[int, Ingredient] = {i.id: i for i in ingredients}

    merged: list[dict] = []
    total_cost = 0.0

    for ing_id, total_qty in quantity_map.items():
        ing = ingredient_map.get(ing_id)
        if ing is None:
            continue
        item_cost = round(total_qty * ing.unit_price, 2)
        total_cost += item_cost
        merged.append(
            {
                "ingredient_id": ing.id,
                "name": ing.name,
                "unit": ing.unit,
                "total_quantity": round(total_qty, 2),
                "unit_price": ing.unit_price,
                "total_cost": item_cost,
            }
        )

    # Sort alphabetically by name for readability
    merged.sort(key=lambda x: x["name"])
    total_cost = round(total_cost, 2)

    return merged, total_cost


def calculate_recipe_cost(db: Session, recipe_id: int) -> float:
    """Calculate the estimated cost of a single recipe from its ingredient prices.

    Used when creating or updating a recipe to set recipe.estimated_cost.
    """
    recipe_ingredients = (
        db.query(RecipeIngredient)
        .filter(RecipeIngredient.recipe_id == recipe_id)
        .all()
    )

    total = 0.0
    for ri in recipe_ingredients:
        ingredient = db.query(Ingredient).filter(Ingredient.id == ri.ingredient_id).first()
        if ingredient:
            total += ri.quantity * ingredient.unit_price

    return round(total, 2)
