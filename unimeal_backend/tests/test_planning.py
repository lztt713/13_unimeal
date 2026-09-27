"""Business-flow tests that do not require a running MySQL server."""

from datetime import date, timedelta
from decimal import Decimal
import unittest

from fastapi import HTTPException
from pydantic import ValidationError
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
from app.routers.recipes import _recipe_to_response
from app.routers.planning import (
    budget_summary_for_user,
    delete_meal_plan_entry,
    generate_shopping_list,
    get_meal_plan,
    planning_reminder_candidates,
    save_meal_plan_entry,
    toggle_shopping_item,
    update_meal_plan_entry,
)
from app.schemas import MealPlanEntryWrite, RecipeSearchParams, ShoppingPurchaseWrite
from app.services.recipe_service import search_recipes


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
        self.student = student
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
            self.student,
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
            self.student,
        )

        shopping = generate_shopping_list(current_week_start(), self.db, self.student)
        self.assertEqual(len(shopping["items"]), 1)
        self.assertEqual(shopping["items"][0]["total_quantity"], 800.0)
        self.assertEqual(shopping["total_estimated_cost"], 1.6)

        purchased = toggle_shopping_item(shopping["items"][0]["id"], self.db, self.student)
        self.assertTrue(purchased["items"][0]["purchased"])
        self.assertEqual(purchased["items"][0]["actual_cost"], 1.6)

        regenerated = generate_shopping_list(current_week_start(), self.db, self.student)
        self.assertEqual(len(regenerated["items"]), 1)
        self.assertTrue(regenerated["items"][0]["purchased"])

        budget = budget_summary_for_user(self.db, self.student_id)
        self.assertEqual(budget["actual_spent"], 1.6)
        self.assertEqual(budget["categories"], [{"label": "Grains", "amount": 1.6}])

        dashboard = get_dashboard(self.db, self.student)
        self.assertEqual(dashboard.spent, 1.6)
        self.assertEqual(dashboard.tonight.title, "Rice bowl")

    def test_recipe_price_matches_shopping_estimate_and_price_filter(self):
        recipe = self.db.get(Recipe, self.recipe_id)
        # The stored sample price is deliberately different from ingredient cost.
        self.assertEqual(float(recipe.estimated_cost), 2.0)
        self.assertEqual(_recipe_to_response(recipe, self.db)["estimated_cost"], 0.2)

        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        shopping = generate_shopping_list(current_week_start(), self.db, self.student)
        self.assertEqual(shopping["total_estimated_cost"], 0.2)
        self.assertEqual(
            [item.recipe_id for item in search_recipes(self.db, RecipeSearchParams(price_max=0.25))],
            [self.recipe_id],
        )
        self.assertEqual(search_recipes(self.db, RecipeSearchParams(price_max=0.19)), [])

    def test_meal_plan_entry_update_and_delete(self):
        created = save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Breakfast",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
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
            self.student,
        )
        self.assertEqual(updated["entries"][0]["meal_type"], "Lunch")
        self.assertEqual(updated["entries"][0]["planned_servings"], 3)

        emptied = delete_meal_plan_entry(entry_id, self.db, self.student)
        self.assertEqual(emptied["entries"], [])

    def test_empty_calendar_clears_active_list_but_keeps_spending(self):
        plan = save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        entry_id = plan["entries"][0]["id"]
        shopping = generate_shopping_list(current_week_start(), self.db, self.student)
        item_id = shopping["items"][0]["id"]
        purchased = toggle_shopping_item(item_id, self.db, self.student)
        purchased_cost = purchased["items"][0]["actual_cost"]

        delete_meal_plan_entry(entry_id, self.db, self.student)
        current_list = generate_shopping_list(current_week_start(), self.db, self.student)
        budget = budget_summary_for_user(self.db, self.student_id)

        self.assertEqual(current_list["items"], [])
        self.assertEqual(budget["actual_spent"], purchased_cost)
        with self.assertRaises(HTTPException) as error:
            toggle_shopping_item(item_id, self.db, self.student)
        self.assertEqual(error.exception.status_code, 404)
        self.assertEqual(budget_summary_for_user(self.db, self.student_id)["actual_spent"], purchased_cost)

    def test_saving_and_updating_plan_refreshes_existing_shopping_list(self):
        planned_date = current_week_start()
        payload = MealPlanEntryWrite(
            plannedDate=planned_date,
            mealType="Dinner",
            recipeId=self.recipe_id,
            plannedServings=1,
        )
        plan = save_meal_plan_entry(payload, self.db, self.student)
        initial = generate_shopping_list(planned_date, self.db, self.student)
        self.assertEqual(initial["items"][0]["total_quantity"], 100.0)

        save_meal_plan_entry(
            payload.model_copy(update={"planned_servings": 3}), self.db, self.student
        )
        after_save = generate_shopping_list(planned_date, self.db, self.student)
        self.assertEqual(after_save["items"][0]["total_quantity"], 300.0)

        update_meal_plan_entry(
            plan["entries"][0]["id"],
            payload.model_copy(update={"planned_servings": 4}),
            self.db,
            self.student,
        )
        after_update = generate_shopping_list(planned_date, self.db, self.student)
        self.assertEqual(after_update["items"][0]["total_quantity"], 400.0)

    def test_students_cannot_access_or_change_each_others_planning_data(self):
        second = User(
            role_id=self.student.role_id,
            email="another.student@unimeal.test",
            password_hash="test-only",
            display_name="Another Student",
        )
        self.db.add(second)
        self.db.commit()

        payload = MealPlanEntryWrite(
            plannedDate=current_week_start(),
            mealType="Dinner",
            recipeId=self.recipe_id,
            plannedServings=1,
        )
        first_plan = save_meal_plan_entry(payload, self.db, self.student)
        first_item = generate_shopping_list(current_week_start(), self.db, self.student)["items"][0]

        self.assertEqual(get_meal_plan(current_week_start(), self.db, second)["entries"], [])
        self.assertEqual(generate_shopping_list(current_week_start(), self.db, second)["items"], [])
        self.assertEqual(budget_summary_for_user(self.db, second.user_id)["actual_spent"], 0)
        self.assertIsNone(get_dashboard(self.db, second).tonight)

        entry_id = first_plan["entries"][0]["id"]
        for operation in (
            lambda: update_meal_plan_entry(entry_id, payload, self.db, second),
            lambda: delete_meal_plan_entry(entry_id, self.db, second),
            lambda: toggle_shopping_item(first_item["id"], self.db, second),
        ):
            with self.assertRaises(HTTPException) as error:
                operation()
            self.assertEqual(error.exception.status_code, 404)

        self.assertEqual(len(get_meal_plan(current_week_start(), self.db, self.student)["entries"]), 1)

    def test_spending_is_counted_without_a_budget_period(self):
        self.db.query(BudgetPeriod).filter(BudgetPeriod.user_id == self.student_id).delete()
        self.db.commit()
        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        item_id = generate_shopping_list(current_week_start(), self.db, self.student)["items"][0]["id"]
        toggle_shopping_item(item_id, self.db, self.student)

        summary = budget_summary_for_user(self.db, self.student_id)
        self.assertEqual(summary["period"]["budget_amount"], 0)
        self.assertGreater(summary["actual_spent"], 0)

        self.student.weekly_budget = Decimal("25.00")
        self.db.commit()
        summary = budget_summary_for_user(self.db, self.student_id)
        self.assertEqual(summary["period"]["budget_amount"], 25.0)
        self.assertEqual(get_dashboard(self.db, self.student).weekly_budget, 25.0)

    def test_receipt_amount_updates_budget_and_unpurchase_clears_it(self):
        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=current_week_start(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        item_id = generate_shopping_list(current_week_start(), self.db, self.student)["items"][0]["id"]
        purchased = toggle_shopping_item(
            item_id, self.db, self.student, ShoppingPurchaseWrite(actualCost="2.75")
        )
        self.assertEqual(purchased["items"][0]["actual_cost"], 2.75)
        self.assertEqual(budget_summary_for_user(self.db, self.student_id)["actual_spent"], 2.75)

        unpurchased = toggle_shopping_item(item_id, self.db, self.student)
        self.assertIsNone(unpurchased["items"][0]["actual_cost"])
        self.assertEqual(budget_summary_for_user(self.db, self.student_id)["actual_spent"], 0)

        for invalid_amount in ("-0.01", "0.001", "100000000.00"):
            with self.assertRaises(ValidationError):
                ShoppingPurchaseWrite(actualCost=invalid_amount)

    def test_dashboard_hides_dinner_after_recipe_is_archived(self):
        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=date.today(),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        self.assertIsNotNone(get_dashboard(self.db, self.student).tonight)
        recipe = self.db.get(Recipe, self.recipe_id)
        recipe.status = "archived"
        self.db.commit()
        self.assertIsNone(get_dashboard(self.db, self.student).tonight)

    def test_planning_reminder_conditions(self):
        reference_date = current_week_start()
        plan = save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=reference_date + timedelta(days=1),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        item_id = generate_shopping_list(reference_date, self.db, self.student)["items"][0]["id"]
        reminders = planning_reminder_candidates(self.db, self.student_id, reference_date)
        self.assertEqual({item["type"] for item in reminders}, {"meal_plan", "shopping_list"})
        self.assertEqual(
            len({item["dedupe_key"] for item in reminders}), len(reminders)
        )

        toggle_shopping_item(item_id, self.db, self.student)
        self.assertEqual(
            [item["type"] for item in planning_reminder_candidates(self.db, self.student_id, reference_date)],
            ["meal_plan"],
        )
        delete_meal_plan_entry(plan["entries"][0]["id"], self.db, self.student)
        self.assertEqual(planning_reminder_candidates(self.db, self.student_id, reference_date), [])

    def test_old_active_shopping_list_does_not_trigger_current_week_reminder(self):
        current_week = current_week_start()
        old_week = current_week - timedelta(days=7)
        save_meal_plan_entry(
            MealPlanEntryWrite(
                plannedDate=old_week + timedelta(days=1),
                mealType="Dinner",
                recipeId=self.recipe_id,
                plannedServings=1,
            ),
            self.db,
            self.student,
        )
        old_list = generate_shopping_list(old_week, self.db, self.student)
        self.assertTrue(any(not item["purchased"] for item in old_list["items"]))

        reminders = planning_reminder_candidates(self.db, self.student_id, current_week)

        self.assertNotIn("shopping_list", {item["type"] for item in reminders})

if __name__ == "__main__":
    unittest.main()
