"""Pydantic schemas for request/response validation."""

from __future__ import annotations

from pydantic import BaseModel, Field


# ── Ingredient ──────────────────────────────────────────────────────────────

class IngredientBase(BaseModel):
    name: str
    unit: str = "g"
    unit_price: float = 0.0

    model_config = {"from_attributes": True}


class IngredientResponse(IngredientBase):
    id: int


# ── Recipe Ingredient (junction) ─────────────────────────────────────────────

class RecipeIngredientBase(BaseModel):
    ingredient_id: int
    quantity: float = 1.0

    model_config = {"from_attributes": True}


class RecipeIngredientDetail(BaseModel):
    """What the frontend sees: ingredient name + quantity + cost contribution."""

    ingredient_id: int
    name: str
    quantity: float
    unit: str
    unit_price: float
    cost: float  # quantity × unit_price

    model_config = {"from_attributes": True}


# ── Recipe ──────────────────────────────────────────────────────────────────

class RecipeBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    image_url: str = ""
    cuisine: str = Field(..., min_length=1, max_length=50)
    difficulty: str = Field(default="Easy", pattern=r"^(Easy|Medium|Hard)$")
    cook_time: int = Field(default=20, ge=0)
    rating: float = Field(default=0.0, ge=0.0, le=5.0)
    review_count: int = Field(default=0, ge=0)
    dietary_tags: list[str] = []
    steps: list[str] = []

    model_config = {"from_attributes": True}


class RecipeCreate(RecipeBase):
    """Schema for creating a new recipe — includes ingredient list."""

    ingredients: list[RecipeIngredientItem] = []


class RecipeIngredientItem(BaseModel):
    """A single ingredient entry in a recipe-create payload."""

    ingredient_id: int
    quantity: float = 1.0


class RecipeResponse(RecipeBase):
    id: int
    estimated_cost: float = 0.0
    ingredients: list[RecipeIngredientItem] = []
    ingredient_details: list[RecipeIngredientDetail] = []


# ── Dashboard ────────────────────────────────────────────────────────────────

class StudentResponse(BaseModel):
    name: str
    weekly_budget: float
    spent: float

    model_config = {"from_attributes": True}


class DashboardResponse(BaseModel):
    student: StudentResponse
    weekly_budget: float
    spent: float
    tonight: RecipeResponse | None = None
    favourites: list[RecipeResponse] = []


# ── Search / Filter ──────────────────────────────────────────────────────────

class RecipeSearchParams(BaseModel):
    """Query parameters for multi-condition recipe search."""

    search: str | None = None  # free-text across title, cuisine, ingredients
    cuisine: str | None = None
    difficulty: str | None = None
    price_max: float | None = None  # e.g. 4.0 for "under $4"
    dietary_tags: list[str] | None = None
    sort_by: str | None = None  # "rating", "cost", "cook_time"
    sort_order: str = "asc"  # "asc" or "desc"


# ── Shopping List / Procurement ──────────────────────────────────────────────

class MergedIngredient(BaseModel):
    """A deduplicated ingredient entry in a shopping list."""

    ingredient_id: int
    name: str
    unit: str
    total_quantity: float
    unit_price: float
    total_cost: float  # total_quantity × unit_price


class ShoppingListResponse(BaseModel):
    """Shopping list with merged ingredients and total procurement cost."""

    recipe_ids: list[int]
    items: list[MergedIngredient]
    total_procurement_cost: float
