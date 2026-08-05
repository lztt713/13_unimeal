"""SQLAlchemy ORM models for UniMeal."""

from sqlalchemy import Column, Float, ForeignKey, Integer, String, Table, Text
from sqlalchemy.orm import relationship

from app.database import Base


class Student(Base):
    """A student user with a weekly food budget."""

    __tablename__ = "students"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    weekly_budget = Column(Float, default=45.0)
    spent = Column(Float, default=0.0)

    favourite_recipes = relationship(
        "Recipe",
        secondary="student_favourites",
        back_populates="favourited_by",
    )


# Join table: student ↔ recipe favourites (many-to-many)
student_favourites = Table(
    "student_favourites",
    Base.metadata,
    Column("student_id", ForeignKey("students.id", ondelete="CASCADE"), primary_key=True),
    Column("recipe_id", ForeignKey("recipes.id", ondelete="CASCADE"), primary_key=True),
)


class Recipe(Base):
    """A recipe with ingredients, steps, and dietary metadata."""

    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(200), nullable=False)
    image_url = Column(String(500), default="")
    cuisine = Column(String(50), nullable=False, index=True)
    difficulty = Column(String(20), nullable=False, default="Easy", index=True)
    estimated_cost = Column(Float, default=0.0, index=True)
    cook_time = Column(Integer, default=20)
    rating = Column(Float, default=0.0)
    review_count = Column(Integer, default=0)
    dietary_tags = Column(String(200), default="")  # comma-separated: "Vegetarian,Vegan"
    steps = Column(Text, default="")  # newline-separated steps

    # Which recipe is tonight's suggestion for the dashboard
    is_tonight = Column(Integer, default=0)  # 0 or 1 (SQLite has no boolean)

    recipe_ingredients = relationship(
        "RecipeIngredient",
        back_populates="recipe",
        cascade="all, delete-orphan",
    )
    favourited_by = relationship(
        "Student",
        secondary="student_favourites",
        back_populates="favourite_recipes",
    )


class Ingredient(Base):
    """A master ingredient with a standard unit price for procurement."""

    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True, index=True)
    unit = Column(String(20), nullable=False, default="g")  # g, ml, piece, etc.
    unit_price = Column(Float, nullable=False, default=0.0)  # price per unit

    recipe_ingredients = relationship(
        "RecipeIngredient",
        back_populates="ingredient",
    )


class RecipeIngredient(Base):
    """Junction table: how much of each ingredient a recipe needs."""

    __tablename__ = "recipe_ingredients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    recipe_id = Column(Integer, ForeignKey("recipes.id", ondelete="CASCADE"), nullable=False)
    ingredient_id = Column(Integer, ForeignKey("ingredients.id", ondelete="CASCADE"), nullable=False)
    quantity = Column(Float, nullable=False, default=1.0)

    recipe = relationship("Recipe", back_populates="recipe_ingredients")
    ingredient = relationship("Ingredient", back_populates="recipe_ingredients")
