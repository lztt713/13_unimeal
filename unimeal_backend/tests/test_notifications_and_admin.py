"""Notification and administrator management tests (runs on MySQL, 张展赫 ZZH)."""

import unittest
from datetime import date, timedelta

from fastapi import HTTPException

from app.models import (
    Cuisine,
    Ingredient,
    IngredientCategory,
    MeasurementUnit,
    MealPlan,
    MealPlanEntry,
    Notification,
    Recipe,
    RecipeComment,
    Role,
    ShoppingList,
    ShoppingListItem,
    User,
)
from app.routers.admin import (
    add_ingredient_category,
    admin_management,
    admin_overview,
    create_report,
    delete_ingredient_category,
    list_ingredient_categories,
    update_recipe_status,
    update_report_status,
    update_user,
)
from app.routers.notifications import (
    list_notifications,
    mark_all_notifications_read,
    mark_notification_read,
    sync_notifications,
)
from base import MySQLTestCase


class NotificationFlowTest(MySQLTestCase):
    def setUp(self):
        super().setUp()
        for name in ("student", "contributor", "administrator"):
            self.db.add(Role(role_name=name))
        self.db.flush()
        student_role = self.db.query(Role).filter(Role.role_name == "student").first()
        self.student = User(
            role_id=student_role.role_id, email="s@example.com", password_hash="x", display_name="S"
        )
        cuisine = Cuisine(cuisine_name="Chinese")
        unit = MeasurementUnit(unit_name="gram", unit_symbol="g", unit_type="weight")
        self.db.add_all([self.student, cuisine, unit])
        self.db.flush()
        recipe = Recipe(
            author_user_id=self.student.user_id,
            cuisine_id=cuisine.cuisine_id,
            title="Rice",
            servings=1,
            difficulty="easy",
            estimated_cost=2,
            status="published",
        )
        self.db.add(recipe)
        self.db.flush()
        plan = MealPlan(user_id=self.student.user_id, week_start_date=date.today(), plan_name="Week")
        self.db.add(plan)
        self.db.flush()
        self.db.add(
            MealPlanEntry(
                meal_plan_id=plan.meal_plan_id,
                recipe_id=recipe.recipe_id,
                planned_date=date.today() + timedelta(days=1),
                meal_type="dinner",
                servings=1,
            )
        )
        shopping = ShoppingList(user_id=self.student.user_id, meal_plan_id=plan.meal_plan_id, status="active")
        self.db.add(shopping)
        self.db.flush()
        self.db.add(
            ShoppingListItem(
                shopping_list_id=shopping.shopping_list_id,
                ingredient_id=None,
                measurement_unit_id=unit.measurement_unit_id,
                item_name="Rice",
                quantity=1,
                is_purchased=False,
            )
        )
        self.db.commit()
        self.student_id = self.student.user_id

    def test_sync_creates_and_deduplicates_reminders(self):
        sync_notifications(self.db, self.student_id)
        first = self.db.query(Notification).filter(Notification.user_id == self.student_id).all()
        self.assertEqual({n.notification_type for n in first}, {"meal_reminder", "shopping_reminder"})

        sync_notifications(self.db, self.student_id)
        second = self.db.query(Notification).filter(Notification.user_id == self.student_id).all()
        self.assertEqual(len(second), len(first))

    def test_list_and_read_flow(self):
        notifications = list_notifications(self.db, self.student)
        self.assertEqual(len(notifications), 2)
        self.assertTrue(all(n["read"] is False for n in notifications))
        self.assertTrue(all(n["created_at"] for n in notifications))

        one = notifications[0]
        updated = mark_notification_read(self.db, self.student, one["id"])
        self.assertTrue(updated["read"])

        all_read = mark_all_notifications_read(self.db, self.student)
        self.assertTrue(all(n["read"] for n in all_read))

    def test_user_cannot_read_another_users_notification(self):
        second = User(
            role_id=self.student.role_id, email="s2@example.com", password_hash="x", display_name="S2"
        )
        self.db.add(second)
        self.db.commit()
        self.assertEqual(list_notifications(self.db, second), [])
        with self.assertRaises(HTTPException) as error:
            mark_notification_read(self.db, second, 999999)
        self.assertEqual(error.exception.status_code, 404)


class AdminFlowTest(MySQLTestCase):
    def setUp(self):
        super().setUp()
        for name in ("student", "contributor", "administrator"):
            self.db.add(Role(role_name=name))
        self.db.flush()
        student_role = self.db.query(Role).filter(Role.role_name == "student").first()
        admin_role = self.db.query(Role).filter(Role.role_name == "administrator").first()
        self.reporter = User(
            role_id=student_role.role_id, email="r@example.com", password_hash="x", display_name="Reporter"
        )
        self.admin = User(
            role_id=admin_role.role_id, email="admin@example.com", password_hash="x", display_name="Admin"
        )
        cuisine = Cuisine(cuisine_name="Italian")
        self.db.add_all([self.reporter, self.admin, cuisine])
        self.db.flush()
        self.recipe = Recipe(
            author_user_id=self.admin.user_id,
            cuisine_id=cuisine.cuisine_id,
            title="Pasta",
            servings=1,
            difficulty="easy",
            estimated_cost=3,
            status="published",
        )
        self.db.add(self.recipe)
        self.db.flush()
        self.comment = RecipeComment(
            recipe_id=self.recipe.recipe_id,
            user_id=self.reporter.user_id,
            comment_text="bad comment",
        )
        self.db.add(self.comment)
        self.db.commit()

    def test_report_recipe_and_comment(self):
        recipe_report = create_report(self.db, self.reporter, "Recipe", self.recipe.recipe_id, "Spam")
        comment_report = create_report(self.db, self.reporter, "Comment", self.comment.recipe_comment_id, "Rude")
        self.assertEqual(recipe_report["status"], "Open")
        self.assertEqual(comment_report["status"], "Open")

        with self.assertRaises(HTTPException) as error:
            create_report(self.db, self.reporter, "Recipe", 999999, "Missing")
        self.assertEqual(error.exception.status_code, 404)

    def test_overview_statistics_and_report_status(self):
        create_report(self.db, self.reporter, "Recipe", self.recipe.recipe_id, "Spam")
        overview = admin_overview(self.db)
        labels = {stat["label"]: stat for stat in overview["statistics"]}
        self.assertEqual(labels["Open reports"]["value"], 1)
        self.assertEqual(labels["Active users"]["value"], 2)
        self.assertEqual(labels["Published recipes"]["value"], 1)
        self.assertEqual(len(overview["reports"]), 1)
        report = overview["reports"][0]
        self.assertEqual(report["targetType"], "Recipe")
        self.assertEqual(report["targetTitle"], "Pasta")
        self.assertEqual(report["status"], "Open")

        updated = update_report_status(self.db, self.admin, report["id"], "In review")
        self.assertEqual(updated["reports"][0]["status"], "In review")

    def test_update_user_role_and_self_suspension_guard(self):
        management = update_user(self.db, self.admin, self.reporter.user_id, role="administrator", status=None)
        reporter_row = next(u for u in management["users"] if u["id"] == self.reporter.user_id)
        self.assertEqual(reporter_row["role"], "administrator")

        with self.assertRaises(HTTPException) as error:
            update_user(self.db, self.admin, self.admin.user_id, role=None, status="Suspended")
        self.assertEqual(error.exception.status_code, 400)

        suspended = update_user(self.db, self.admin, self.reporter.user_id, role=None, status="Suspended")
        reporter_row = next(u for u in suspended["users"] if u["id"] == self.reporter.user_id)
        self.assertEqual(reporter_row["status"], "Suspended")

    def test_update_recipe_status(self):
        management = update_recipe_status(self.db, self.recipe.recipe_id, "Archived")
        recipe_row = next(r for r in management["recipes"] if r["id"] == self.recipe.recipe_id)
        self.assertEqual(recipe_row["status"], "Archived")

    def test_ingredient_category_lifecycle(self):
        self.assertEqual(list_ingredient_categories(self.db), [])
        added = add_ingredient_category(self.db, "Dairy")
        self.assertEqual(added[0]["name"], "Dairy")

        with self.assertRaises(HTTPException) as error:
            add_ingredient_category(self.db, "dairy")
        self.assertEqual(error.exception.status_code, 409)

        category_id = added[0]["id"]
        self.db.add(Ingredient(ingredient_category_id=category_id, ingredient_name="Milk"))
        self.db.commit()
        with self.assertRaises(HTTPException) as error:
            delete_ingredient_category(self.db, category_id)
        self.assertEqual(error.exception.status_code, 409)

    def test_management_lists_users_and_recipes(self):
        management = admin_management(self.db)
        self.assertEqual(len(management["users"]), 2)
        self.assertEqual(len(management["recipes"]), 1)
        self.assertEqual(management["recipes"][0]["status"], "Published")


if __name__ == "__main__":
    unittest.main()
