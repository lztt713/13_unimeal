"""Regression tests for frontend/backend integration contracts."""

from datetime import date, datetime, timedelta
import unittest

from sqlalchemy import BigInteger, SmallInteger, create_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import Allergy, BudgetPeriod, Equipment, Notification, Role, User
from app.routers.auth import apply_profile_update
from app.routers.notifications import delete_read_notifications
from app.routers.recipes import _image_extension, create_recipe, list_allergies, list_equipment
from app.schemas import ProfileUpdate, RecipeCreate
from app.services.aiRecommendation import _filter_and_rank


@compiles(BigInteger, "sqlite")
def _compile_big_integer_as_integer(_type, _compiler, **_kwargs):
    return "INTEGER"


@compiles(SmallInteger, "sqlite")
def _compile_small_integer_as_integer(_type, _compiler, **_kwargs):
    return "INTEGER"


class CompletedIntegrationTest(unittest.TestCase):
    def setUp(self):
        engine = create_engine("sqlite+pysqlite:///:memory:")
        Base.metadata.create_all(engine)
        self.db = sessionmaker(bind=engine)()
        role = Role(role_name="student")
        contributor_role = Role(role_name="contributor")
        self.db.add_all([role, contributor_role])
        self.db.flush()
        self.user = User(
            role_id=role.role_id,
            email="student@example.com",
            password_hash="test-only",
            display_name="Student",
            weekly_budget=25,
        )
        self.db.add(self.user)
        self.contributor = User(
            role_id=contributor_role.role_id,
            email="contributor@example.com",
            password_hash="test-only",
            display_name="Contributor",
        )
        self.db.add(self.contributor)
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_equipment_and_allergy_lookup_contracts(self):
        self.db.add_all(
            [
                Equipment(equipment_name="Hob", description="Stovetop"),
                Allergy(allergy_name="Dairy"),
            ]
        )
        self.db.commit()
        self.assertEqual(list_equipment(self.db, self.user)[0]["name"], "Hob")
        self.assertEqual(list_allergies(self.db, self.user)[0]["name"], "Dairy")

    def test_recipe_create_persists_and_returns_required_equipment(self):
        hob = Equipment(equipment_name="Hob", description="Stovetop")
        self.db.add(hob)
        self.db.commit()
        result = create_recipe(
            RecipeCreate(
                title="Equipment recipe",
                cuisine="European",
                requiredEquipmentIds=[hob.equipment_id],
            ),
            self.db,
            self.contributor,
        )
        self.assertEqual(result["required_equipment"][0]["name"], "Hob")

    def test_profile_budget_update_syncs_active_budget_period(self):
        today = date.today()
        period = BudgetPeriod(
            user_id=self.user.user_id,
            period_start=today - timedelta(days=today.weekday()),
            period_end=today + timedelta(days=6 - today.weekday()),
            budget_amount=25,
        )
        self.db.add(period)
        self.db.commit()

        apply_profile_update(self.db, self.user, ProfileUpdate(weeklyBudget=60))
        self.db.refresh(period)
        self.assertEqual(float(period.budget_amount), 60.0)
        self.assertEqual(float(self.user.weekly_budget), 60.0)

    def test_clear_read_notifications_keeps_unread(self):
        self.db.add_all(
            [
                Notification(
                    user_id=self.user.user_id,
                    notification_type="system",
                    title="Read",
                    message="Read message",
                    read_at=datetime.now(),
                ),
                Notification(
                    user_id=self.user.user_id,
                    notification_type="system",
                    title="Unread",
                    message="Unread message",
                ),
            ]
        )
        self.db.commit()
        remaining = delete_read_notifications(self.db, self.user)
        self.assertEqual([item["title"] for item in remaining], ["Unread"])

    def test_fallback_ranking_respects_allergy_kitchen_and_query_budget(self):
        recipes = [
            {
                "id": 1,
                "title": "Safe toast",
                "cuisine": "European",
                "estimated_cost": 3.0,
                "prep_time": 5,
                "cook_time": 5,
                "dietary_tags": ["Vegetarian"],
                "allergen_tags": [],
                "ingredients": ["bread"],
                "required_equipment": [{"name": "Toaster"}],
            },
            {
                "id": 2,
                "title": "Milk pasta",
                "cuisine": "Italian",
                "estimated_cost": 4.0,
                "prep_time": 5,
                "cook_time": 10,
                "dietary_tags": ["Vegetarian"],
                "allergen_tags": ["Dairy"],
                "ingredients": ["milk", "pasta"],
                "required_equipment": [{"name": "Hob"}],
            },
        ]
        profile = {
            "weekly_budget": 20.0,
            "dietary_preferences": ["Vegetarian"],
            "allergies": ["Dairy"],
            "cooking_skill": "beginner",
            "kitchen_access": "limited",
            "favourite_cuisines": [],
            "saved_recipe_ids": [],
        }
        result = _filter_and_rank(recipes, "vegetarian meals under $5", profile)
        self.assertEqual([recipe["id"] for recipe in result], [1])

    def test_image_type_is_detected_from_bytes(self):
        self.assertEqual(_image_extension(b"\x89PNG\r\n\x1a\nrest"), ".png")
        self.assertIsNone(_image_extension(b"not-an-image"))


if __name__ == "__main__":
    unittest.main()
