"""Recipe endpoints: CRUD, search, and ingredient/cost operations."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Ingredient, Recipe, RecipeIngredient
from app.schemas import (
    MergedIngredient,
    RecipeCreate,
    RecipeIngredientDetail,
    RecipeIngredientItem,
    RecipeResponse,
    RecipeSearchParams,
    ShoppingListResponse,
)
from app.services.ingredient_service import (
    calculate_recipe_cost,
    merge_ingredients,
)
from app.services.recipe_service import get_recipe_ingredients, search_recipes

router = APIRouter(prefix="/api", tags=["recipes"])


# ── Helper: convert a Recipe ORM object → RecipeResponse dict ─────────────

def _recipe_to_response(recipe: Recipe, db: Session) -> dict:
    """Build a full RecipeResponse-like dict from a Recipe ORM object."""
    ingredient_details = get_recipe_ingredients(db, recipe.id)
    ingredient_items = [
        {"ingredient_id": d["ingredient_id"], "quantity": d["quantity"]}
        for d in ingredient_details
    ]
    dietary_tags = (
        [t.strip() for t in recipe.dietary_tags.split(",") if t.strip()]
        if recipe.dietary_tags
        else []
    )
    steps = (
        [s.strip() for s in recipe.steps.split("\n") if s.strip()]
        if recipe.steps
        else []
    )
    return {
        "id": recipe.id,
        "title": recipe.title,
        "image_url": recipe.image_url,
        "cuisine": recipe.cuisine,
        "difficulty": recipe.difficulty,
        "estimated_cost": recipe.estimated_cost,
        "cook_time": recipe.cook_time,
        "rating": recipe.rating,
        "review_count": recipe.review_count,
        "dietary_tags": dietary_tags,
        "steps": steps,
        "ingredients": ingredient_items,
        "ingredient_details": ingredient_details,
    }


# ── GET /api/recipes — list/search ───────────────────────────────────────

@router.get("/recipes", response_model=list[RecipeResponse])
def list_recipes(
    search: str | None = Query(None, description="Free-text search across title, cuisine, ingredients"),
    cuisine: str | None = Query(None, description="Filter by cuisine type"),
    difficulty: str | None = Query(None, description="Filter by difficulty (Easy, Medium, Hard)"),
    price_max: float | None = Query(None, description="Max estimated cost per serving"),
    dietary_tags: str | None = Query(None, description="Comma-separated dietary tags"),
    sort_by: str | None = Query(None, description="Sort by: rating, cost, cook_time"),
    sort_order: str = Query("asc", description="Sort order: asc or desc"),
    db: Session = Depends(get_db),
):
    """Multi-condition recipe search.

    Supports all filter combinations the frontend uses:
    - Text search (title, cuisine, ingredient names)
    - Cuisine, difficulty, price ceiling, dietary tags
    - Sorting by rating, cost, or cook time
    """
    params = RecipeSearchParams(
        search=search,
        cuisine=cuisine,
        difficulty=difficulty,
        price_max=price_max,
        dietary_tags=[t.strip() for t in dietary_tags.split(",") if t.strip()] if dietary_tags else None,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    recipes = search_recipes(db, params)
    return [_recipe_to_response(r, db) for r in recipes]


# ── GET /api/recipes/{recipe_id} — detail ────────────────────────────────

@router.get("/recipes/{recipe_id}", response_model=RecipeResponse)
def get_recipe(recipe_id: int, db: Session = Depends(get_db)):
    """Get a single recipe with full ingredient details."""
    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return _recipe_to_response(recipe, db)


# ── POST /api/recipes — create ───────────────────────────────────────────

@router.post("/recipes", response_model=RecipeResponse, status_code=201)
def create_recipe(payload: RecipeCreate, db: Session = Depends(get_db)):
    """Create a new recipe with ingredients.

    The estimated_cost is calculated automatically from ingredient prices.
    """
    dietary_tags_str = ", ".join(payload.dietary_tags)
    steps_str = "\n".join(payload.steps)

    recipe = Recipe(
        title=payload.title,
        image_url=payload.image_url,
        cuisine=payload.cuisine,
        difficulty=payload.difficulty,
        cook_time=payload.cook_time,
        rating=payload.rating,
        review_count=payload.review_count,
        dietary_tags=dietary_tags_str,
        steps=steps_str,
        estimated_cost=0.0,  # calculated below
    )
    db.add(recipe)
    db.flush()  # get recipe.id

    # Attach ingredients
    for item in payload.ingredients:
        db.add(
            RecipeIngredient(
                recipe_id=recipe.id,
                ingredient_id=item.ingredient_id,
                quantity=item.quantity,
            )
        )

    # Auto-calculate cost from ingredient prices
    recipe.estimated_cost = calculate_recipe_cost(db, recipe.id)
    db.commit()
    db.refresh(recipe)

    return _recipe_to_response(recipe, db)


# ── GET /api/shopping-list — ingredient dedup + procurement cost ─────────

@router.get("/shopping-list", response_model=ShoppingListResponse)
def get_shopping_list(
    recipe_ids: str = Query(..., description="Comma-separated recipe IDs, e.g. 1,2,3"),
    db: Session = Depends(get_db),
):
    """Generate a deduplicated shopping list with total procurement cost.

    This is the core "ingredient deduplication and merging" endpoint.
    Identical ingredients across multiple recipes are merged into a single
    line item with summed quantities. The total procurement cost is
    calculated from the merged list.

    Example: If Recipe #1 needs 200g chicken and Recipe #2 needs 150g chicken,
    the merged list shows 350g chicken with the combined cost.
    """
    ids = [int(x.strip()) for x in recipe_ids.split(",") if x.strip()]
    if not ids:
        raise HTTPException(status_code=400, detail="At least one recipe ID is required")

    # Verify all recipes exist
    existing = db.query(Recipe.id).filter(Recipe.id.in_(ids)).all()
    existing_ids = {r[0] for r in existing}
    missing = set(ids) - existing_ids
    if missing:
        raise HTTPException(
            status_code=404,
            detail=f"Recipes not found: {sorted(missing)}",
        )

    merged_items, total_cost = merge_ingredients(db, ids)

    return ShoppingListResponse(
        recipe_ids=ids,
        items=[MergedIngredient(**item) for item in merged_items],
        total_procurement_cost=total_cost,
    )
