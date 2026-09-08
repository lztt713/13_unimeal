"""Pydantic schemas for the UniMeal API contract."""

from __future__ import annotations

from datetime import date

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
    quantity: float = Field(default=1.0, gt=0, le=9999999)
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
    allergen_tags: list[str] = Field(default_factory=list, alias="allergenTags")
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


class MealPlanEntryWrite(BaseModel):
    """Create or update one meal-plan slot."""

    model_config = api_model_config

    id: int | None = None
    planned_date: date = Field(alias="plannedDate")
    meal_type: str = Field(alias="mealType", min_length=1, max_length=20)
    recipe_id: int = Field(alias="recipeId", gt=0)
    planned_servings: int = Field(default=1, alias="plannedServings", ge=1, le=50)
    notes: str | None = Field(default=None, max_length=500)


class MealPlanEntryResponse(BaseModel):
    """Vue-friendly representation of a planned meal."""

    model_config = api_model_config

    id: int
    planned_date: date = Field(alias="plannedDate")
    meal_type: str = Field(alias="mealType")
    recipe_id: int = Field(alias="recipeId")
    planned_servings: int = Field(alias="plannedServings")
    notes: str | None = None


class MealPlanResponse(BaseModel):
    """Current week plan used by the calendar and dashboard."""

    model_config = api_model_config

    id: int | None = None
    week_start_date: date = Field(alias="weekStartDate")
    plan_name: str = Field(default="Weekly meal plan", alias="planName")
    entries: list[MealPlanEntryResponse] = Field(default_factory=list)


class PersistedShoppingItemResponse(BaseModel):
    """A generated shopping-list line persisted in MySQL."""

    model_config = api_model_config

    id: int
    ingredient_id: int | None = Field(default=None, alias="ingredientId")
    name: str
    unit: str
    total_quantity: float = Field(alias="totalQuantity")
    unit_price: float = Field(alias="unitPrice")
    estimated_cost: float = Field(alias="estimatedCost")
    actual_cost: float | None = Field(default=None, alias="actualCost")
    purchased: bool
    category: str | None = None


class PersistedShoppingListResponse(BaseModel):
    """Current meal plan's generated and persisted shopping list."""

    model_config = api_model_config

    id: int | None = None
    recipe_ids: list[int] = Field(default_factory=list, alias="recipeIds")
    status: str = "active"
    items: list[PersistedShoppingItemResponse] = Field(default_factory=list)
    total_estimated_cost: float = Field(default=0.0, alias="totalEstimatedCost")


class BudgetPeriodResponse(BaseModel):
    """Budget dates and amount returned to the summary page."""

    model_config = api_model_config

    start_date: date = Field(alias="startDate")
    end_date: date = Field(alias="endDate")
    budget_amount: float = Field(alias="budgetAmount")


class BudgetCategoryResponse(BaseModel):
    label: str
    amount: float


class BudgetSummaryResponse(BaseModel):
    """Purchased shopping-list cost compared with the active budget."""

    model_config = api_model_config

    period: BudgetPeriodResponse
    actual_spent: float = Field(alias="actualSpent")
    categories: list[BudgetCategoryResponse] = Field(default_factory=list)
