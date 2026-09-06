"""Recipe endpoints backed by Qichen Hu's normalized MySQL database."""

from __future__ import annotations

import os

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Cuisine,
    DietaryTag,
    Ingredient,
    MealPlanEntry,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    RecipeRating,
    RecipeStep,
    User,
    recipe_dietary_tags,
    saved_recipes,
)
from app.schemas import (
    IngredientResponse,
    MergedIngredient,
    RatingCreate,
    RecipeCreate,
    RecipeResponse,
    RecipeSearchParams,
    RecipeUpdate,
    ShoppingListResponse,
    ToggleSavedRecipeResponse,
)
from app.services.ingredient_service import (
    calculate_recipe_cost,
    merge_ingredients,
)
from app.services.recipe_service import get_recipe_ingredients, search_recipes

router = APIRouter(prefix="/api", tags=["recipes"])

DEFAULT_STUDENT_EMAIL = os.getenv("UNIMEAL_STUDENT_EMAIL", "student.michael@unimeal.test")
DEFAULT_CONTRIBUTOR_EMAIL = os.getenv("UNIMEAL_CONTRIBUTOR_EMAIL", "contributor.ben@unimeal.test")


def _display_difficulty(value: str | None) -> str:
    return (value or "easy").capitalize()


def _db_difficulty(value: str | None) -> str:
    return (value or "Easy").strip().lower()


def _display_status(value: str | None) -> str:
    return (value or "draft").capitalize()


def _db_status(value: str | None) -> str:
    return (value or "draft").strip().lower()


def _price_per_serving(recipe: Recipe) -> float:
    servings = int(recipe.servings or 1)
    return round(float(recipe.estimated_cost or 0) / servings, 2)


def _rating_summary(db: Session, recipe_id: int) -> tuple[float, int]:
    rating, count = (
        db.query(func.avg(RecipeRating.rating), func.count(RecipeRating.recipe_id))
        .filter(RecipeRating.recipe_id == recipe_id)
        .one()
    )
    return (round(float(rating), 1) if rating is not None else 0.0, int(count or 0))


def _get_user_by_email(db: Session, email: str, role_label: str) -> User:
    user = db.query(User).filter(User.email == email, User.is_active.is_(True)).first()
    if user is None:
        raise HTTPException(
            status_code=404,
            detail=f"{role_label} user '{email}' was not found. Run database/sample_data.sql first.",
        )
    return user


def _normalize_lookup(value: str) -> str:
    return value.strip().replace("-", " ").lower()


def _get_or_create_cuisine(db: Session, cuisine_name: str) -> Cuisine:
    cuisine_name = cuisine_name.strip()
    cuisine = db.query(Cuisine).filter(func.lower(Cuisine.cuisine_name) == cuisine_name.lower()).first()
    if cuisine is None:
        cuisine = Cuisine(cuisine_name=cuisine_name)
        db.add(cuisine)
        db.flush()
    return cuisine


def _get_or_create_tag(db: Session, tag_name: str) -> DietaryTag:
    tag_name = tag_name.strip()
    lookup = _normalize_lookup(tag_name)
    tag = (
        db.query(DietaryTag)
        .filter(func.lower(func.replace(DietaryTag.tag_name, "-", " ")) == lookup)
        .first()
    )
    if tag is None:
        tag = DietaryTag(tag_name=tag_name)
        db.add(tag)
        db.flush()
    return tag


def _unit_for_ingredient(db: Session, ingredient: Ingredient, unit_symbol: str | None) -> MeasurementUnit:
    unit = None
    if unit_symbol:
        unit = db.query(MeasurementUnit).filter(MeasurementUnit.unit_symbol == unit_symbol).first()
    if unit is None:
        unit = ingredient.default_measurement_unit
    if unit is None:
        raise HTTPException(status_code=400, detail=f"No measurement unit found for {ingredient.ingredient_name}")
    return unit


def _replace_recipe_tags(db: Session, recipe: Recipe, tag_names: list[str]) -> None:
    recipe.dietary_tags = [_get_or_create_tag(db, tag_name) for tag_name in tag_names if tag_name.strip()]


def _replace_recipe_ingredients(db: Session, recipe: Recipe, ingredient_details) -> None:
    db.execute(delete(RecipeIngredient).where(RecipeIngredient.recipe_id == recipe.recipe_id))
    db.flush()

    for sort_order, item in enumerate(ingredient_details or [], start=1):
        ingredient = db.get(Ingredient, item.ingredient_id)
        if ingredient is None or not ingredient.is_active:
            raise HTTPException(status_code=400, detail=f"Ingredient {item.ingredient_id} was not found")
        unit = _unit_for_ingredient(db, ingredient, item.unit)
        db.add(
            RecipeIngredient(
                recipe_id=recipe.recipe_id,
                ingredient_id=ingredient.ingredient_id,
                measurement_unit_id=unit.measurement_unit_id,
                quantity=item.quantity,
                sort_order=sort_order,
            )
        )


def _replace_recipe_steps(db: Session, recipe: Recipe, steps: list[str]) -> None:
    db.execute(delete(RecipeStep).where(RecipeStep.recipe_id == recipe.recipe_id))
    db.flush()

    for step_number, instruction in enumerate(steps or [], start=1):
        instruction = instruction.strip()
        if instruction:
            db.add(
                RecipeStep(
                    recipe_id=recipe.recipe_id,
                    step_number=step_number,
                    instruction=instruction,
                )
            )


def _recipe_to_response(recipe: Recipe, db: Session) -> dict:
    """Build a Vue-friendly response from normalized recipe tables."""
    ingredient_details = get_recipe_ingredients(db, int(recipe.recipe_id))
    rating, review_count = _rating_summary(db, int(recipe.recipe_id))
    return {
        "id": int(recipe.recipe_id),
        "title": recipe.title,
        "image_url": recipe.image_url or "",
        "cuisine": recipe.cuisine.cuisine_name if recipe.cuisine else "Unclassified",
        "difficulty": _display_difficulty(recipe.difficulty),
        "prep_time": int(recipe.preparation_minutes or 0),
        "cook_time": int(recipe.cooking_minutes or 0),
        "servings": int(recipe.servings or 1),
        "estimated_cost": _price_per_serving(recipe),
        "rating": rating,
        "review_count": review_count,
        "status": _display_status(recipe.status),
        "dietary_tags": [tag.tag_name for tag in recipe.dietary_tags],
        "ingredients": [item["name"].lower() for item in ingredient_details],
        "ingredient_details": ingredient_details,
        "steps": [step.instruction for step in recipe.steps],
        "comments": [],
    }


@router.get("/ingredients", response_model=list[IngredientResponse])
def list_ingredients(db: Session = Depends(get_db)):
    """Return active ingredient options from the shared MySQL database."""
    rows = (
        db.query(Ingredient)
        .outerjoin(Ingredient.default_measurement_unit)
        .outerjoin(Ingredient.category)
        .filter(Ingredient.is_active.is_(True))
        .order_by(Ingredient.ingredient_name.asc())
        .all()
    )

    return [
        {
            "id": int(ingredient.ingredient_id),
            "name": ingredient.ingredient_name,
            "default_unit": ingredient.default_measurement_unit.unit_symbol
            if ingredient.default_measurement_unit
            else "",
            "unit_price": float(ingredient.estimated_unit_cost),
            "category": ingredient.category.category_name if ingredient.category else None,
        }
        for ingredient in rows
    ]


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
    """Multi-condition recipe search over published recipes."""
    params = RecipeSearchParams(
        search=search,
        cuisine=cuisine,
        difficulty=difficulty,
        price_max=price_max,
        dietary_tags=[tag.strip() for tag in dietary_tags.split(",") if tag.strip()] if dietary_tags else None,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    recipes = search_recipes(db, params)
    return [_recipe_to_response(recipe, db) for recipe in recipes]


@router.get("/my-recipes", response_model=list[RecipeResponse])
def list_my_recipes(db: Session = Depends(get_db)):
    """Return every recipe owned by the default contributor, including drafts."""
    contributor = _get_user_by_email(db, DEFAULT_CONTRIBUTOR_EMAIL, "Contributor")
    recipes = (
        db.query(Recipe)
        .filter(Recipe.author_user_id == contributor.user_id)
        .order_by(Recipe.updated_at.desc(), Recipe.recipe_id.desc())
        .all()
    )
    return [_recipe_to_response(recipe, db) for recipe in recipes]


@router.get("/recipes/{recipe_id}", response_model=RecipeResponse)
def get_recipe(recipe_id: int, db: Session = Depends(get_db)):
    """Get a single recipe with ingredients and method steps."""
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return _recipe_to_response(recipe, db)


@router.post("/recipes", response_model=RecipeResponse, status_code=201)
def create_recipe(payload: RecipeCreate, db: Session = Depends(get_db)):
    """Create a contributor recipe in the normalized MySQL tables."""
    author = _get_user_by_email(db, DEFAULT_CONTRIBUTOR_EMAIL, "Contributor")
    cuisine = _get_or_create_cuisine(db, payload.cuisine)

    recipe = Recipe(
        author_user_id=author.user_id,
        cuisine_id=cuisine.cuisine_id,
        title=payload.title.strip(),
        image_url=payload.image_url or None,
        description=None,
        preparation_minutes=payload.prep_time,
        cooking_minutes=payload.cook_time,
        servings=payload.servings,
        difficulty=_db_difficulty(payload.difficulty),
        estimated_cost=payload.estimated_cost,
        status="draft",
    )
    db.add(recipe)
    db.flush()

    _replace_recipe_tags(db, recipe, payload.dietary_tags)
    _replace_recipe_ingredients(db, recipe, payload.ingredient_details)
    _replace_recipe_steps(db, recipe, payload.steps)
    if payload.ingredient_details:
        recipe.estimated_cost = calculate_recipe_cost(db, int(recipe.recipe_id))

    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db)


@router.put("/recipes/{recipe_id}", response_model=RecipeResponse)
def update_recipe(recipe_id: int, payload: RecipeUpdate, db: Session = Depends(get_db)):
    """Update a recipe while preserving Qichen's normalized table layout."""
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    if payload.title is not None:
        recipe.title = payload.title.strip()
    if payload.image_url is not None:
        recipe.image_url = payload.image_url or None
    if payload.cuisine is not None:
        recipe.cuisine = _get_or_create_cuisine(db, payload.cuisine)
    if payload.difficulty is not None:
        recipe.difficulty = _db_difficulty(payload.difficulty)
    if payload.prep_time is not None:
        recipe.preparation_minutes = payload.prep_time
    if payload.cook_time is not None:
        recipe.cooking_minutes = payload.cook_time
    if payload.servings is not None:
        recipe.servings = payload.servings
    if payload.status is not None:
        recipe.status = _db_status(payload.status)
    if payload.dietary_tags is not None:
        _replace_recipe_tags(db, recipe, payload.dietary_tags)
    if payload.ingredient_details is not None:
        _replace_recipe_ingredients(db, recipe, payload.ingredient_details)
    if payload.steps is not None:
        _replace_recipe_steps(db, recipe, payload.steps)

    if payload.ingredient_details is not None:
        recipe.estimated_cost = calculate_recipe_cost(db, int(recipe.recipe_id))
    elif payload.estimated_cost is not None:
        recipe.estimated_cost = payload.estimated_cost

    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db)


@router.delete("/recipes/{recipe_id}")
def delete_recipe(recipe_id: int, db: Session = Depends(get_db)):
    """Delete a recipe owned by the default contributor."""
    contributor = _get_user_by_email(db, DEFAULT_CONTRIBUTOR_EMAIL, "Contributor")
    recipe = (
        db.query(Recipe)
        .filter(
            Recipe.recipe_id == recipe_id,
            Recipe.author_user_id == contributor.user_id,
        )
        .first()
    )
    if recipe is None:
        raise HTTPException(status_code=404, detail="Contributor recipe not found")
    if db.query(MealPlanEntry).filter(MealPlanEntry.recipe_id == recipe_id).first() is not None:
        raise HTTPException(
            status_code=409,
            detail="Remove this recipe from meal plans before deleting it",
        )
    db.delete(recipe)
    db.commit()
    return {"id": recipe_id}


@router.post("/recipes/{recipe_id}/ratings", response_model=RecipeResponse)
def add_recipe_rating(recipe_id: int, payload: RatingCreate, db: Session = Depends(get_db)):
    """Create or update the default student's rating for a recipe."""
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    user = _get_user_by_email(db, DEFAULT_STUDENT_EMAIL, "Student")
    rating = db.get(RecipeRating, {"user_id": user.user_id, "recipe_id": recipe.recipe_id})
    if rating is None:
        db.add(RecipeRating(user_id=user.user_id, recipe_id=recipe.recipe_id, rating=payload.rating))
    else:
        rating.rating = payload.rating

    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db)


@router.get("/saved-recipes", response_model=list[int])
def get_saved_recipe_ids(db: Session = Depends(get_db)):
    """Return recipe IDs saved by the default student account."""
    user = _get_user_by_email(db, DEFAULT_STUDENT_EMAIL, "Student")
    rows = db.execute(select(saved_recipes.c.recipe_id).where(saved_recipes.c.user_id == user.user_id)).all()
    return [int(row[0]) for row in rows]


@router.post("/recipes/{recipe_id}/saved", response_model=ToggleSavedRecipeResponse)
def toggle_saved_recipe(recipe_id: int, db: Session = Depends(get_db)):
    """Toggle whether the default student has saved a recipe."""
    user = _get_user_by_email(db, DEFAULT_STUDENT_EMAIL, "Student")
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    existing = db.execute(
        select(saved_recipes.c.recipe_id).where(
            saved_recipes.c.user_id == user.user_id,
            saved_recipes.c.recipe_id == recipe_id,
        )
    ).first()

    if existing:
        db.execute(
            delete(saved_recipes).where(
                saved_recipes.c.user_id == user.user_id,
                saved_recipes.c.recipe_id == recipe_id,
            )
        )
        saved = False
    else:
        db.execute(saved_recipes.insert().values(user_id=user.user_id, recipe_id=recipe_id))
        saved = True

    db.commit()
    return ToggleSavedRecipeResponse(saved=saved)


@router.get("/shopping-list", response_model=ShoppingListResponse)
def get_shopping_list(
    recipe_ids: str = Query(..., description="Comma-separated recipe IDs, e.g. 1,2,3"),
    db: Session = Depends(get_db),
):
    """Generate a deduplicated shopping list for selected recipes."""
    ids = [int(x.strip()) for x in recipe_ids.split(",") if x.strip()]
    if not ids:
        raise HTTPException(status_code=400, detail="At least one recipe ID is required")

    existing = db.query(Recipe.recipe_id).filter(Recipe.recipe_id.in_(ids)).all()
    existing_ids = {int(row[0]) for row in existing}
    missing = set(ids) - existing_ids
    if missing:
        raise HTTPException(status_code=404, detail=f"Recipes not found: {sorted(missing)}")

    merged_items, total_cost = merge_ingredients(db, ids)

    return ShoppingListResponse(
        recipe_ids=ids,
        items=[MergedIngredient(**item) for item in merged_items],
        total_procurement_cost=total_cost,
    )
