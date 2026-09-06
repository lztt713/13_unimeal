"""Business-flow tests that do not require a running MySQL server."""

from datetime import date, timedelta
from decimal import Decimal
import unittest

from sqlalchemy import BigInteger, SmallInteger, create_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import (
    BudgetPeriod,
    Cuisine,
    Ingredient,
    IngredientCategory,
    MeasurementUnit,
    Recipe,
    RecipeIngredient,
    Role,
    User,
)
from app.routers.dashboard import get_dashboard
from app.routers.planning import (
    budget_summary_for_user,
    delete_meal_plan_entry,
    generate_shopping_list,
    save_meal_plan_entry,
    toggle_shopping_item,
    update_meal_plan_entry,
)
from app.schemas import MealPlanEntryWrite


@compiles(BigInteger, "sqlite")
def _compile_big_integer_as_integer(_type, _compiler, **_kwargs):
    """Let SQLite autoincrement IDs that are BIGINT in production MySQL."""
    return "INTEGER"


@compiles(SmallInteger, "sqlite")
def _compile_small_integer_as_integer(_type, _compiler, **_kwargs):
    return "INTEGER"


def current_week_start() -> date:
    today = date.today()
    return today - timedelta(days=today.weekday())


class PlanningFlowTest(unittest.TestCase):
    def setUp(self):
        engine = create_engine("sqlite+pysqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()

        student_role = Role(role_name="student")
        contributor_role = Role(role_name="contributor")
        self.db.add_all([student_role, contributor_role])
        self.db.flush()
        student = User(
            role_id=student_role.role_id,
            email="student.michael@unimeal.test",
            password_hash="test-only",
            display_name="Michael Student",
        )
        contributor = User(
            role_id=contributor_role.role_id,
            email="contributor.ben@unimeal.test",
            password_hash="test-only",
            display_name="Ben Contributor",
        )
        category = IngredientCategory(category_name="Grains")
        unit = MeasurementUnit(unit_name="gram", unit_symbol="g", unit_type="weight")
        cuisine = Cuisine(cuisine_name="Test cuisine")
        self.db.add_all([student, contributor, category, unit, cuisine])
        self.db.flush()
        ingredient = Ingredient(
            ingredient_category_id=category.ingredient_category_id,
            ingredient_name="Rice",
            default_measurement_unit_id=unit.measurement_unit_id,
            estimated_unit_cost=Decimal("0.0020"),
        )
        self.db.add(ingredient)
        self.db.flush()
        recipe = Recipe(
            author_user_id=contributor.user_id,
            cuisine_id=cuisine.cuisine_id,
            title="Rice bowl",
            preparation_minutes=5,
            cooking_minutes=15,
            servings=2,
            difficulty="easy",
            estimated_cost=Decimal("2.00"),
            status="published",
        )
        self.db.add(recipe)
        self.db.flush()
        self.db.add(
            RecipeIngredient(
                recipe_id=recipe.recipe_id,
                ingredient_id=ingredient.ingredient_id,
                measurement_unit_id=unit.measurement_unit_id,
                quantity=Decimal("200"),
                sort_order=1,
            )
        )
        week_start = current_week_start()
        self.db.add(
            BudgetPeriod(
                user_id=student.user_id,
                period_start=week_start,
                period_end=week_start + timedelta(days=6),
                budget_amount=Decimal("50.00"),
            )
        )
        self.db.commit()
        self.student_id = student.user_id
        self.recipe_id = recipe.recipe_id

    def tearDown(self):
        self.db.close()

    def test_meal_plan_to_budget_and_dashboard_flow(self):
        plan = save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=date.today(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=4,
            ),
            self.db,
        )
        self.assertEqual(plan["entries"][0]["meal_type"], "Dinner")

        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Lunch",
                recipeId=self.recipe_id,
                plannedServings=4,
            ),
            self.db,
        )

        shopping = generate_shopping_list(current_week_start(), self.db)
        self.assertEqual(len(shopping["items"]), 1)
        self.assertEqual(shopping["items"][0]["total_quantity"], 800.0)
        self.assertEqual(shopping["total_estimated_cost"], 1.6)

        purchased = toggle_shopping_item(shopping["items"][0]["id"], self.db)
        self.assertTrue(purchased["items"][0]["purchased"])
        self.assertEqual(purchased["items"][0]["actual_cost"], 1.6)

        regenerated = generate_shopping_list(current_week_start(), self.db)
        self.assertEqual(len(regenerated["items"]), 1)
        self.assertTrue(regenerated["items"][0]["purchased"])

        budget = budget_summary_for_user(self.db, self.student_id)
        self.assertEqual(budget["actual_spent"], 1.6)
        self.assertEqual(budget["categories"], [{"label": "Grains", "amount": 1.6}])

        dashboard = get_dashboard(self.db)
        self.assertEqual(dashboard.spent, 1.6)
        self.assertEqual(dashboard.tonight.title, "Rice bowl")

    def test_meal_plan_entry_update_and_delete(self):
        created = save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Breakfast",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
        )
        entry_id = created["entries"][0]["id"]
        updated = update_meal_plan_entry(
            entry_id,
            MealPlanEntryWrite(
                id=entry_id,
                plannedDate=current_week_start() + timedelta(days=1),
                mealType="Lunch",
                recipeId=self.recipe_id,
                plannedServings=3,
            ),
            self.db,
        )
        self.assertEqual(updated["entries"][0]["meal_type"], "Lunch")
        self.assertEqual(updated["entries"][0]["planned_servings"], 3)

        emptied = delete_meal_plan_entry(entry_id, self.db)
        self.assertEqual(emptied["entries"], [])


if __name__ == "__main__":
    unittest.main()
