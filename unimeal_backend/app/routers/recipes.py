"""Recipe endpoints backed by Qichen Hu's normalized MySQL database.

Zhang Zhanhe (ZZH): Recipe permissions use the authenticated user rather than
a fixed test account. Contributors manage only their own recipes, draft and
archived recipes are hidden from other users, and comment APIs live here.
"""

from __future__ import annotations

from datetime import datetime
from email import policy
from email.parser import BytesParser
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session, joinedload

from app.auth import contributor_user, get_current_user, get_current_user_optional, student_user
from app.database import get_db
from app.models import (
    Allergy,
    Cuisine,
    DietaryTag,
    Equipment,
    Ingredient,
    MealPlanEntry,
    MeasurementUnit,
    Recipe,
    RecipeComment,
    RecipeIngredient,
    RecipeRating,
    RecipeStep,
    User,
    ingredient_allergens,
    recipe_dietary_tags,
    saved_recipes,
)
from app.schemas import (
    CommentCreate,
    AllergyResponse,
    EquipmentResponse,
    IngredientResponse,
    MergedIngredient,
    RatingCreate,
    RecipeCreate,
    RecipeResponse,
    RecipeImageUploadResponse,
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
from app.routers.notifications import notify_recipe_updated

router = APIRouter(prefix="/api", tags=["recipes"])

VALID_RECIPE_STATUSES = {"draft", "published", "archived"}
UPLOAD_DIRECTORY = Path(__file__).resolve().parents[2] / "uploads" / "recipe-images"
MAX_IMAGE_BYTES = 5 * 1024 * 1024


def _display_difficulty(value: str | None) -> str:
    return (value or "easy").capitalize()


def _db_difficulty(value: str | None) -> str:
    return (value or "Easy").strip().lower()


def _display_status(value: str | None) -> str:
    return (value or "draft").capitalize()


def _db_status(value: str | None) -> str:
    # Only these three statuses are valid; anything else is rejected.
    status = (value or "draft").strip().lower()
    if status not in VALID_RECIPE_STATUSES:
        raise HTTPException(status_code=400, detail="Recipe status must be Draft, Published, or Archived")
    return status


def _price_per_serving(recipe: Recipe, ingredient_details: list[dict]) -> float:
    servings = int(recipe.servings or 1)
    # Keep recipe cards aligned with the shopping list's ingredient pricing.
    # No-ingredient legacy recipes retain their stored estimate.
    total = (
        sum(item["quantity"] * item["unit_price"] for item in ingredient_details)
        if ingredient_details
        else float(recipe.estimated_cost or 0)
    )
    return round(total / servings, 2)


def _rating_summary(db: Session, recipe_id: int) -> tuple[float, int]:
    rating, count = (
        db.query(func.avg(RecipeRating.rating), func.count(RecipeRating.recipe_id))
        .filter(RecipeRating.recipe_id == recipe_id)
        .one()
    )
    return (round(float(rating), 1) if rating is not None else 0.0, int(count or 0))


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


def _replace_recipe_equipment(db: Session, recipe: Recipe, equipment_ids: list[int]) -> None:
    unique_ids = list(dict.fromkeys(equipment_ids or []))
    if not unique_ids:
        recipe.required_equipment = []
        return

    equipment = db.query(Equipment).filter(Equipment.equipment_id.in_(unique_ids)).all()
    found_ids = {int(item.equipment_id) for item in equipment}
    missing = sorted(set(unique_ids) - found_ids)
    if missing:
        raise HTTPException(status_code=400, detail=f"Equipment not found: {missing}")
    recipe.required_equipment = equipment


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


def _recipe_comments(db: Session, recipe_id: int) -> list[dict]:
    """Return visible (non-hidden) comments with author and timestamp.

    Comments hidden by an administrator are not visible to regular users.
    """
    comments = (
        db.query(RecipeComment)
        .options(joinedload(RecipeComment.author))
        .filter(RecipeComment.recipe_id == recipe_id, RecipeComment.is_hidden.is_(False))
        .order_by(RecipeComment.created_at.asc(), RecipeComment.recipe_comment_id.asc())
        .all()
    )
    return [
        {
            "id": int(comment.recipe_comment_id),
            "author": comment.author.display_name,
            "text": comment.comment_text,
            "rating": None,
            "created_at": comment.created_at.isoformat() if comment.created_at else None,
        }
        for comment in comments
    ]


def _recipe_allergens(db: Session, recipe_id: int) -> list[str]:
    """Return the allergen names linked to a recipe's ingredients.

    The query follows recipe ingredients through the ingredient-allergen
    junction, then deduplicates and sorts the allergen names.
    """
    rows = (
        db.query(Allergy.allergy_name)
        .join(ingredient_allergens, ingredient_allergens.c.allergy_id == Allergy.allergy_id)
        .join(RecipeIngredient, RecipeIngredient.ingredient_id == ingredient_allergens.c.ingredient_id)
        .filter(RecipeIngredient.recipe_id == recipe_id)
        .distinct()
        .order_by(Allergy.allergy_name.asc())
        .all()
    )
    return [row[0] for row in rows]


def _recipe_to_response(recipe: Recipe, db: Session, include_comments: bool = False) -> dict:
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
        "estimated_cost": _price_per_serving(recipe, ingredient_details),
        "rating": rating,
        "review_count": review_count,
        "status": _display_status(recipe.status),
        "dietary_tags": [tag.tag_name for tag in recipe.dietary_tags],
        "ingredients": [item["name"].lower() for item in ingredient_details],
        "ingredient_details": ingredient_details,
        "steps": [step.instruction for step in recipe.steps],
        "comments": _recipe_comments(db, int(recipe.recipe_id)) if include_comments else [],
        "allergen_tags": _recipe_allergens(db, int(recipe.recipe_id)),
        "required_equipment": [
            {
                "id": int(item.equipment_id),
                "name": item.equipment_name,
                "description": item.description,
            }
            for item in recipe.required_equipment
        ],
    }


def _can_manage_recipe(recipe: Recipe, user: User | None) -> bool:
    """Only the recipe author or an administrator may manage a non-public recipe."""
    if user is None:
        return False
    return recipe.author_user_id == user.user_id or user.role.role_name == "administrator"


def _image_extension(content: bytes) -> str | None:
    if content.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if content.startswith((b"GIF87a", b"GIF89a")):
        return ".gif"
    if len(content) >= 12 and content[:4] == b"RIFF" and content[8:12] == b"WEBP":
        return ".webp"
    return None


@router.post("/uploads/recipe-image", response_model=RecipeImageUploadResponse, status_code=201)
async def upload_recipe_image(
    request: Request,
    _contributor: User = Depends(contributor_user),
):
    """Store one validated recipe image without trusting the supplied filename."""
    content_type = request.headers.get("content-type", "")
    if not content_type.lower().startswith("multipart/form-data"):
        raise HTTPException(status_code=415, detail="Upload must use multipart/form-data")

    body = await request.body()
    if len(body) > MAX_IMAGE_BYTES + 512 * 1024:
        raise HTTPException(status_code=413, detail="Recipe image must be 5 MB or smaller")

    message = BytesParser(policy=policy.default).parsebytes(
        f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode("utf-8") + body
    )
    image_bytes = None
    for part in message.iter_parts() if message.is_multipart() else []:
        if part.get_param("name", header="content-disposition") == "file":
            image_bytes = part.get_payload(decode=True)
            break

    if not image_bytes:
        raise HTTPException(status_code=400, detail="A recipe image file is required")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Recipe image must be 5 MB or smaller")

    extension = _image_extension(image_bytes)
    if extension is None:
        raise HTTPException(status_code=415, detail="Only JPEG, PNG, GIF, or WebP images are supported")

    UPLOAD_DIRECTORY.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid4().hex}{extension}"
    (UPLOAD_DIRECTORY / filename).write_bytes(image_bytes)
    return {"image_url": str(request.url_for("recipe-images", path=filename))}


@router.get("/equipment", response_model=list[EquipmentResponse])
def list_equipment(
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    rows = db.query(Equipment).order_by(Equipment.equipment_name.asc()).all()
    return [
        {"id": int(item.equipment_id), "name": item.equipment_name, "description": item.description}
        for item in rows
    ]


@router.get("/allergies", response_model=list[AllergyResponse])
def list_allergies(
    db: Session = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    rows = db.query(Allergy).order_by(Allergy.allergy_name.asc()).all()
    return [{"id": int(item.allergy_id), "name": item.allergy_name} for item in rows]


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
    """Multi-condition recipe search over published recipes only."""
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


# Only the current contributor's own recipes are returned, drafts included.
@router.get("/my-recipes", response_model=list[RecipeResponse])
def list_my_recipes(db: Session = Depends(get_db), contributor: User = Depends(contributor_user)):
    """Return every recipe owned by the current contributor, including drafts."""
    recipes = (
        db.query(Recipe)
        .filter(Recipe.author_user_id == contributor.user_id)
        .order_by(Recipe.updated_at.desc(), Recipe.recipe_id.desc())
        .all()
    )
    return [_recipe_to_response(recipe, db) for recipe in recipes]


@router.get("/recipes/{recipe_id}", response_model=RecipeResponse)
def get_recipe(
    recipe_id: int,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_current_user_optional),
):
    """Get a single recipe; drafts and archived recipes are only visible to their owner or an admin."""
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    # Non-public recipes are 404 for everyone except the author or an admin.
    if recipe.status != "published" and not _can_manage_recipe(recipe, user):
        raise HTTPException(status_code=404, detail="Recipe not found")
    return _recipe_to_response(recipe, db, include_comments=True)


@router.post("/recipes", response_model=RecipeResponse, status_code=201)
def create_recipe(
    payload: RecipeCreate,
    db: Session = Depends(get_db),
    contributor: User = Depends(contributor_user),
):
    """Create a recipe owned by the current contributor, starting as a draft.

    Ownership comes from the authenticated contributor rather than a fixed
    test account, and every new recipe starts in draft status.
    """
    cuisine = _get_or_create_cuisine(db, payload.cuisine)

    recipe = Recipe(
        author_user_id=contributor.user_id,
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
    _replace_recipe_equipment(db, recipe, payload.required_equipment_ids)
    _replace_recipe_ingredients(db, recipe, payload.ingredient_details)
    _replace_recipe_steps(db, recipe, payload.steps)
    if payload.ingredient_details:
        recipe.estimated_cost = calculate_recipe_cost(db, int(recipe.recipe_id))

    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db, include_comments=True)


@router.put("/recipes/{recipe_id}", response_model=RecipeResponse)
def update_recipe(
    recipe_id: int,
    payload: RecipeUpdate,
    db: Session = Depends(get_db),
    contributor: User = Depends(contributor_user),
):
    """Update a recipe owned by the current contributor.

    The query includes author_user_id so another contributor's recipe is
    treated as missing instead of allowing an unauthorized update.
    """
    recipe = (
        db.query(Recipe)
        .filter(Recipe.recipe_id == recipe_id, Recipe.author_user_id == contributor.user_id)
        .first()
    )
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
    if payload.required_equipment_ids is not None:
        _replace_recipe_equipment(db, recipe, payload.required_equipment_ids)
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
    # Notify students who saved this recipe whenever the contributor edits it.
    notify_recipe_updated(db, recipe)
    return _recipe_to_response(recipe, db, include_comments=True)


@router.delete("/recipes/{recipe_id}")
def delete_recipe(
    recipe_id: int,
    db: Session = Depends(get_db),
    contributor: User = Depends(contributor_user),
):
    """Delete a recipe owned by the current contributor, unless still used by a meal plan.

    Filtering by author_user_id ensures contributors can delete only their own recipes.
    """
    recipe = (
        db.query(Recipe)
        .filter(Recipe.recipe_id == recipe_id, Recipe.author_user_id == contributor.user_id)
        .first()
    )
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    # Return 409 to protect existing meal-plan references.
    if db.query(MealPlanEntry).filter(MealPlanEntry.recipe_id == recipe_id).first() is not None:
        raise HTTPException(
            status_code=409,
            detail="Remove this recipe from meal plans before deleting it",
        )
    db.delete(recipe)
    db.commit()
    return {"id": recipe_id}


@router.post("/recipes/{recipe_id}/ratings", response_model=RecipeResponse)
def add_recipe_rating(
    recipe_id: int,
    payload: RatingCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Create or update the current user's rating for a published recipe."""
    recipe = (
        db.query(Recipe)
        .filter(Recipe.recipe_id == recipe_id, Recipe.status == "published")
        .first()
    )
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    rating = db.get(RecipeRating, {"user_id": user.user_id, "recipe_id": recipe.recipe_id})
    if rating is None:
        db.add(RecipeRating(user_id=user.user_id, recipe_id=recipe.recipe_id, rating=payload.rating))
    else:
        rating.rating = payload.rating

    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db, include_comments=True)


@router.post("/recipes/{recipe_id}/comments", response_model=RecipeResponse)
def add_recipe_comment(
    recipe_id: int,
    payload: CommentCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Post a comment on a published recipe, associated with the current user.

    Blank comments receive 400, while CommentCreate enforces the maximum
    length. The author comes from the authenticated user and the recipe ID
    comes from the request path.
    """
    recipe = (
        db.query(Recipe)
        .filter(Recipe.recipe_id == recipe_id, Recipe.status == "published")
        .first()
    )
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Comment cannot be empty")

    db.add(
        RecipeComment(
            recipe_id=recipe.recipe_id,
            user_id=user.user_id,
            comment_text=text,
            is_hidden=False,
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
    )
    db.commit()
    db.refresh(recipe)
    return _recipe_to_response(recipe, db, include_comments=True)


@router.get("/saved-recipes", response_model=list[int])
def get_saved_recipe_ids(db: Session = Depends(get_db), user: User = Depends(student_user)):
    """Return recipe IDs saved by the current user."""
    rows = db.execute(select(saved_recipes.c.recipe_id).where(saved_recipes.c.user_id == user.user_id)).all()
    return [int(row[0]) for row in rows]


@router.post("/recipes/{recipe_id}/saved", response_model=ToggleSavedRecipeResponse)
def toggle_saved_recipe(
    recipe_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(student_user),
):
    """Toggle whether the current user has saved a published recipe."""
    recipe = (
        db.query(Recipe)
        .filter(Recipe.recipe_id == recipe_id, Recipe.status == "published")
        .first()
    )
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
    _student: User = Depends(student_user),
):
    """Generate a deduplicated shopping list for selected recipes."""
    try:
        ids = list(dict.fromkeys(int(x.strip()) for x in recipe_ids.split(",") if x.strip()))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Recipe IDs must be integers") from exc
    if not ids:
        raise HTTPException(status_code=400, detail="At least one recipe ID is required")

    existing = (
        db.query(Recipe.recipe_id)
        .filter(Recipe.recipe_id.in_(ids), Recipe.status == "published")
        .all()
    )
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
