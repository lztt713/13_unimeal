"""Pydantic schemas for the UniMeal API contract."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


api_model_config = ConfigDict(
    from_attributes=True,
    populate_by_name=True,
)


class IngredientResponse(BaseModel):
    """Ingredient option returned to the recipe submission form."""

    model_config = api_model_config

    id: int
    name: str
    default_unit: str = Field(alias="defaultUnit")
    unit_price: float = Field(alias="unitPrice")
    category: str | None = None


class RecipeIngredientItem(BaseModel):
    """Minimal ingredient reference used by older API clients."""

    model_config = api_model_config

    ingredient_id: int = Field(alias="ingredientId")
    quantity: float = 1.0
    unit: str | None = None


class RecipeIngredientDetail(RecipeIngredientItem):
    """Full ingredient line returned on recipe detail responses."""

    name: str
    unit: str
    unit_price: float = Field(default=0.0, alias="unitPrice")
    cost: float = 0.0


class RecipeCommentResponse(BaseModel):
    """Placeholder-friendly response shape for recipe feedback."""

    model_config = api_model_config

    id: int
    author: str
    text: str
    rating: int | None = None
    created_at: str | None = Field(default=None, alias="createdAt")


class RecipeBase(BaseModel):
    """Fields shared by create, update, and response payloads."""

    model_config = api_model_config

    title: str = Field(..., min_length=1, max_length=160)
    image_url: str = Field(default="", alias="imageUrl")
    cuisine: str = Field(..., min_length=1, max_length=60)
    difficulty: str = Field(default="Easy", pattern=r"^(Easy|Medium|Hard)$")
    prep_time: int = Field(default=0, ge=0, alias="prepTime")
    cook_time: int = Field(default=20, ge=0, alias="cookTime")
    servings: int = Field(default=1, ge=1, le=50)
    estimated_cost: float = Field(default=0.0, ge=0.0, alias="estimatedCost")
    dietary_tags: list[str] = Field(default_factory=list, alias="dietaryTags")
    ingredients: list[str] = Field(default_factory=list)
    ingredient_details: list[RecipeIngredientDetail] = Field(default_factory=list, alias="ingredientDetails")
    steps: list[str] = Field(default_factory=list)


class RecipeCreate(RecipeBase):
    """Schema for creating a recipe against the normalized MySQL tables."""


class RecipeUpdate(BaseModel):
    """Partial update schema for contributor recipe edits."""

    model_config = api_model_config

    title: str | None = Field(default=None, min_length=1, max_length=160)
    image_url: str | None = Field(default=None, alias="imageUrl")
    cuisine: str | None = Field(default=None, min_length=1, max_length=60)
    difficulty: str | None = Field(default=None, pattern=r"^(Easy|Medium|Hard)$")
    prep_time: int | None = Field(default=None, ge=0, alias="prepTime")
    cook_time: int | None = Field(default=None, ge=0, alias="cookTime")
    servings: int | None = Field(default=None, ge=1, le=50)
    estimated_cost: float | None = Field(default=None, ge=0.0, alias="estimatedCost")
    dietary_tags: list[str] | None = Field(default=None, alias="dietaryTags")
    ingredients: list[str] | None = None
    ingredient_details: list[RecipeIngredientDetail] | None = Field(default=None, alias="ingredientDetails")
    steps: list[str] | None = None
    status: str | None = None


class RecipeResponse(RecipeBase):
    """Recipe response shaped for the Vue frontend."""

    id: int
    rating: float = 0.0
    review_count: int = Field(default=0, alias="reviewCount")
    status: str = "Draft"
    comments: list[RecipeCommentResponse] = Field(default_factory=list)


class StudentResponse(BaseModel):
    """Dashboard student summary."""

    model_config = api_model_config

    name: str
    weekly_budget: float = Field(alias="weeklyBudget")
    spent: float


class DashboardResponse(BaseModel):
    """Dashboard response kept intentionally small for this backend handoff."""

    model_config = api_model_config

    student: StudentResponse
    weekly_budget: float = Field(alias="weeklyBudget")
    spent: float
    tonight: RecipeResponse | None = None
    favourites: list[RecipeResponse] = Field(default_factory=list)


class RecipeSearchParams(BaseModel):
    """Query parameters for multi-condition recipe search."""

    search: str | None = None
    cuisine: str | None = None
    difficulty: str | None = None
    price_max: float | None = None
    dietary_tags: list[str] | None = None
    sort_by: str | None = None
    sort_order: str = "asc"


class MergedIngredient(BaseModel):
    """A deduplicated ingredient entry in a shopping list."""

    model_config = api_model_config

    ingredient_id: int = Field(alias="ingredientId")
    name: str
    unit: str
    total_quantity: float = Field(alias="totalQuantity")
    unit_price: float = Field(alias="unitPrice")
    total_cost: float = Field(alias="totalCost")


class ShoppingListResponse(BaseModel):
    """Shopping list with merged ingredients and total procurement cost."""

    model_config = api_model_config

    recipe_ids: list[int] = Field(alias="recipeIds")
    items: list[MergedIngredient]
    total_procurement_cost: float = Field(alias="totalProcurementCost")


class RatingCreate(BaseModel):
    """Request body for creating or updating a recipe rating."""

    rating: int = Field(..., ge=1, le=5)


class ToggleSavedRecipeResponse(BaseModel):
    """Response returned after toggling a saved recipe."""

    saved: bool
