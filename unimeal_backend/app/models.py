"""SQLAlchemy ORM models mapped to Qichen Hu's MySQL schema."""

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    BigInteger,
    Numeric,
    SmallInteger,
    String,
    Table,
    Text,
    text,
)
from sqlalchemy.orm import relationship

from app.database import Base


recipe_dietary_tags = Table(
    "recipe_dietary_tags",
    Base.metadata,
    Column("recipe_id", BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), primary_key=True),
    Column(
        "dietary_tag_id",
        SmallInteger,
        ForeignKey("dietary_tags.dietary_tag_id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


saved_recipes = Table(
    "saved_recipes",
    Base.metadata,
    Column("user_id", BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True),
    Column("recipe_id", BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), primary_key=True),
    Column("saved_at", DateTime),
)


# ZZH: 用户饮食偏好 / 过敏原关联表（对应胡启辰 master_schema 里的两张多对多表）。
# Many-to-many junction tables for user dietary preferences and allergies.
user_dietary_preferences = Table(
    "user_dietary_preferences",
    Base.metadata,
    Column("user_id", BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True),
    Column(
        "dietary_tag_id",
        SmallInteger,
        ForeignKey("dietary_tags.dietary_tag_id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


user_allergies = Table(
    "user_allergies",
    Base.metadata,
    Column("user_id", BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True),
    Column(
        "allergy_id",
        SmallInteger,
        ForeignKey("allergies.allergy_id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


# ZZH: 食材 ↔ 过敏原关联表（对应 master_schema 的 ingredient_allergens）。
# Ingredient-to-allergen junction table, e.g. Milk -> Dairy.
ingredient_allergens = Table(
    "ingredient_allergens",
    Base.metadata,
    Column(
        "ingredient_id",
        BigInteger,
        ForeignKey("ingredients.ingredient_id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "allergy_id",
        SmallInteger,
        ForeignKey("allergies.allergy_id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


class Role(Base):
    """Application role such as student, contributor, or administrator."""

    __tablename__ = "roles"

    role_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    role_name = Column(String(30), nullable=False, unique=True)

    users = relationship("User", back_populates="role")


class User(Base):
    """A real UniMeal user from the shared MySQL database."""

    __tablename__ = "users"

    user_id = Column(BigInteger, primary_key=True, autoincrement=True)
    role_id = Column(SmallInteger, ForeignKey("roles.role_id"), nullable=False)
    email = Column(String(254), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    display_name = Column(String(80), nullable=False)
    cooking_skill = Column(String(20), nullable=False, default="beginner")
    kitchen_access = Column(String(20), nullable=False, default="shared")
    favourite_cuisines_note = Column(String(255))
    weekly_budget = Column(Numeric(10, 2), nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    role = relationship("Role", back_populates="users")
    saved_recipes = relationship("Recipe", secondary=saved_recipes, back_populates="saved_by")
    ratings = relationship("RecipeRating", back_populates="user", cascade="all, delete-orphan")
    budget_periods = relationship("BudgetPeriod", back_populates="user")
    meal_plans = relationship("MealPlan", back_populates="user", cascade="all, delete-orphan")
    shopping_lists = relationship("ShoppingList", back_populates="user", cascade="all, delete-orphan")
    allergies = relationship("Allergy", secondary=user_allergies, back_populates="users")
    dietary_preferences = relationship(
        "DietaryTag", secondary=user_dietary_preferences, back_populates="users_with_preference"
    )
    comments = relationship("RecipeComment", back_populates="author", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")


class Cuisine(Base):
    """Recipe cuisine lookup table."""

    __tablename__ = "cuisines"

    cuisine_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    cuisine_name = Column(String(60), nullable=False, unique=True)

    recipes = relationship("Recipe", back_populates="cuisine")


class DietaryTag(Base):
    """Dietary tag lookup table."""

    __tablename__ = "dietary_tags"

    dietary_tag_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    tag_name = Column(String(60), nullable=False, unique=True)
    description = Column(String(255))

    recipes = relationship("Recipe", secondary=recipe_dietary_tags, back_populates="dietary_tags")
    users_with_preference = relationship(
        "User", secondary=user_dietary_preferences, back_populates="dietary_preferences"
    )


class Allergy(Base):
    """Allergen lookup table used by user profile allergy preferences."""

    __tablename__ = "allergies"

    allergy_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    allergy_name = Column(String(80), nullable=False, unique=True)

    users = relationship("User", secondary=user_allergies, back_populates="allergies")


class IngredientCategory(Base):
    """Ingredient category lookup table."""

    __tablename__ = "ingredient_categories"

    ingredient_category_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    category_name = Column(String(60), nullable=False, unique=True)

    ingredients = relationship("Ingredient", back_populates="category")


class MeasurementUnit(Base):
    """Measurement unit lookup table."""

    __tablename__ = "measurement_units"

    measurement_unit_id = Column(SmallInteger, primary_key=True, autoincrement=True)
    unit_name = Column(String(40), nullable=False, unique=True)
    unit_symbol = Column(String(12), nullable=False, unique=True)
    unit_type = Column(String(20), nullable=False)

    ingredients = relationship("Ingredient", back_populates="default_measurement_unit")
    recipe_ingredients = relationship("RecipeIngredient", back_populates="measurement_unit")
    shopping_list_items = relationship("ShoppingListItem", back_populates="measurement_unit")


class Ingredient(Base):
    """Master ingredient with default unit and estimated reference price."""

    __tablename__ = "ingredients"

    ingredient_id = Column(BigInteger, primary_key=True, autoincrement=True)
    ingredient_category_id = Column(
        SmallInteger,
        ForeignKey("ingredient_categories.ingredient_category_id"),
        nullable=False,
    )
    ingredient_name = Column(String(120), nullable=False, unique=True)
    default_measurement_unit_id = Column(SmallInteger, ForeignKey("measurement_units.measurement_unit_id"))
    estimated_unit_cost = Column(Numeric(12, 4), nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)

    category = relationship("IngredientCategory", back_populates="ingredients")
    default_measurement_unit = relationship("MeasurementUnit", back_populates="ingredients")
    recipe_ingredients = relationship("RecipeIngredient", back_populates="ingredient")
    shopping_list_items = relationship("ShoppingListItem", back_populates="ingredient")


class Recipe(Base):
    """Recipe entity from the normalized MySQL schema."""

    __tablename__ = "recipes"

    recipe_id = Column(BigInteger, primary_key=True, autoincrement=True)
    author_user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    cuisine_id = Column(SmallInteger, ForeignKey("cuisines.cuisine_id", ondelete="SET NULL"))
    title = Column(String(160), nullable=False)
    image_url = Column(String(500))
    description = Column(Text)
    preparation_minutes = Column(SmallInteger, nullable=False, default=0)
    cooking_minutes = Column(SmallInteger, nullable=False, default=0)
    servings = Column(SmallInteger, nullable=False)
    difficulty = Column(String(20), nullable=False, default="easy")
    estimated_cost = Column(Numeric(10, 2), nullable=False, default=0)
    status = Column(String(20), nullable=False, default="draft")
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    author = relationship("User")
    cuisine = relationship("Cuisine", back_populates="recipes")
    dietary_tags = relationship("DietaryTag", secondary=recipe_dietary_tags, back_populates="recipes")
    recipe_ingredients = relationship(
        "RecipeIngredient",
        back_populates="recipe",
        cascade="all, delete-orphan",
        order_by="RecipeIngredient.sort_order",
    )
    steps = relationship(
        "RecipeStep",
        back_populates="recipe",
        cascade="all, delete-orphan",
        order_by="RecipeStep.step_number",
    )
    saved_by = relationship("User", secondary=saved_recipes, back_populates="saved_recipes")
    ratings = relationship("RecipeRating", back_populates="recipe", cascade="all, delete-orphan")
    comments = relationship("RecipeComment", back_populates="recipe", cascade="all, delete-orphan")


class RecipeIngredient(Base):
    """Junction table line: ingredient quantity and unit for one recipe."""

    __tablename__ = "recipe_ingredients"

    recipe_ingredient_id = Column(BigInteger, primary_key=True, autoincrement=True)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), nullable=False)
    ingredient_id = Column(BigInteger, ForeignKey("ingredients.ingredient_id"), nullable=False)
    measurement_unit_id = Column(SmallInteger, ForeignKey("measurement_units.measurement_unit_id"), nullable=False)
    quantity = Column(Numeric(10, 3), nullable=False)
    preparation_note = Column(String(160))
    sort_order = Column(SmallInteger, nullable=False, default=1)

    recipe = relationship("Recipe", back_populates="recipe_ingredients")
    ingredient = relationship("Ingredient", back_populates="recipe_ingredients")
    measurement_unit = relationship("MeasurementUnit", back_populates="recipe_ingredients")


class RecipeStep(Base):
    """Ordered recipe instruction."""

    __tablename__ = "recipe_steps"

    recipe_step_id = Column(BigInteger, primary_key=True, autoincrement=True)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), nullable=False)
    step_number = Column(SmallInteger, nullable=False)
    instruction = Column(Text, nullable=False)

    recipe = relationship("Recipe", back_populates="steps")


class RecipeRating(Base):
    """A user's rating for a recipe."""

    __tablename__ = "recipe_ratings"

    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), primary_key=True)
    rating = Column(SmallInteger, nullable=False)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    user = relationship("User", back_populates="ratings")
    recipe = relationship("Recipe", back_populates="ratings")


class BudgetPeriod(Base):
    """User budget period for dashboard budget summary."""

    __tablename__ = "budget_periods"

    budget_period_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    budget_amount = Column(Numeric(10, 2), nullable=False)

    user = relationship("User", back_populates="budget_periods")


class MealPlan(Base):
    """Weekly meal plan."""

    __tablename__ = "meal_plans"

    meal_plan_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    week_start_date = Column(Date, nullable=False)
    plan_name = Column(String(100), nullable=False, default="Weekly meal plan")
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    user = relationship("User", back_populates="meal_plans")
    entries = relationship("MealPlanEntry", back_populates="meal_plan", cascade="all, delete-orphan")
    shopping_lists = relationship("ShoppingList", back_populates="meal_plan")


class MealPlanEntry(Base):
    """A planned recipe in a meal slot."""

    __tablename__ = "meal_plan_entries"

    meal_plan_entry_id = Column(BigInteger, primary_key=True, autoincrement=True)
    meal_plan_id = Column(BigInteger, ForeignKey("meal_plans.meal_plan_id", ondelete="CASCADE"), nullable=False)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id"), nullable=False)
    planned_date = Column(Date, nullable=False)
    meal_type = Column(String(20), nullable=False)
    servings = Column(SmallInteger, nullable=False)
    notes = Column(String(500))

    meal_plan = relationship("MealPlan", back_populates="entries")
    recipe = relationship("Recipe")


class ShoppingList(Base):
    """Persisted shopping list generated from a meal plan."""

    __tablename__ = "shopping_lists"

    shopping_list_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    meal_plan_id = Column(BigInteger, ForeignKey("meal_plans.meal_plan_id", ondelete="SET NULL"))
    list_name = Column(String(100), nullable=False, default="Shopping list")
    status = Column(String(20), nullable=False, default="active")
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    user = relationship("User", back_populates="shopping_lists")
    meal_plan = relationship("MealPlan", back_populates="shopping_lists")
    items = relationship(
        "ShoppingListItem",
        back_populates="shopping_list",
        cascade="all, delete-orphan",
        order_by="ShoppingListItem.shopping_list_item_id",
    )


class ShoppingListItem(Base):
    """One merged ingredient line in a persisted shopping list."""

    __tablename__ = "shopping_list_items"

    shopping_list_item_id = Column(BigInteger, primary_key=True, autoincrement=True)
    shopping_list_id = Column(
        BigInteger,
        ForeignKey("shopping_lists.shopping_list_id", ondelete="CASCADE"),
        nullable=False,
    )
    ingredient_id = Column(BigInteger, ForeignKey("ingredients.ingredient_id", ondelete="SET NULL"))
    measurement_unit_id = Column(
        SmallInteger,
        ForeignKey("measurement_units.measurement_unit_id"),
        nullable=False,
    )
    item_name = Column(String(160), nullable=False)
    quantity = Column(Numeric(10, 3), nullable=False)
    estimated_unit_cost = Column(Numeric(10, 2))
    actual_cost = Column(Numeric(10, 2))
    is_purchased = Column(Boolean, nullable=False, default=False)
    purchased_at = Column(DateTime)

    shopping_list = relationship("ShoppingList", back_populates="items")
    ingredient = relationship("Ingredient", back_populates="shopping_list_items")
    measurement_unit = relationship("MeasurementUnit", back_populates="shopping_list_items")


class RecipeComment(Base):
    """A user's comment on a recipe.

    对应 master_schema 的 recipe_comments 表（is_hidden 标记被管理员隐藏的评论）。
    """

    __tablename__ = "recipe_comments"

    recipe_comment_id = Column(BigInteger, primary_key=True, autoincrement=True)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    comment_text = Column(Text, nullable=False)
    is_hidden = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    recipe = relationship("Recipe", back_populates="comments")
    author = relationship("User", back_populates="comments")


class Notification(Base):
    """A user notification (meal plan, shopping list, recipe update or system).

    dedupe_key 用于去重（本模块新增，见迁移脚本）；read_at 为空表示未读。
    """

    __tablename__ = "notifications"

    notification_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    notification_type = Column(String(30), nullable=False)
    title = Column(String(160), nullable=False)
    message = Column(Text, nullable=False)
    dedupe_key = Column(String(255))
    scheduled_for = Column(DateTime)
    read_at = Column(DateTime)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    user = relationship("User", back_populates="notifications")


class ContentReport(Base):
    """A report against one recipe or one comment, reviewed by an administrator.

    recipe_id 和 recipe_comment_id 二选一（数据库有 CHECK 约束保证）。
    """

    __tablename__ = "content_reports"

    content_report_id = Column(BigInteger, primary_key=True, autoincrement=True)
    reporter_user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    recipe_id = Column(BigInteger, ForeignKey("recipes.recipe_id", ondelete="CASCADE"))
    recipe_comment_id = Column(BigInteger, ForeignKey("recipe_comments.recipe_comment_id", ondelete="CASCADE"))
    reason = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False, default="open")
    reviewed_by_user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="SET NULL"))
    reviewed_at = Column(DateTime)
    created_at = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

    reporter = relationship("User", foreign_keys=[reporter_user_id])
    reviewer = relationship("User", foreign_keys=[reviewed_by_user_id])
    recipe = relationship("Recipe")
    comment = relationship("RecipeComment")
