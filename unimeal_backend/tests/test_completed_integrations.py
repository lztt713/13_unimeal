"""Regression tests for frontend/backend integration contracts."""

from datetime import date, datetime, timedelta
import unittest

from fastapi import HTTPException
from sqlalchemy import BigInteger, SmallInteger, create_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import (
    Allergy,
    BudgetPeriod,
    Cuisine,
    Equipment,
    Ingredient,
    IngredientCategory,
    MeasurementUnit,
    Notification,
    Recipe,
    RecipeIngredient,
    Role,
    User,
    ingredient_allergens,
)
from app.routers.auth import apply_profile_update
from app.routers.notifications import delete_read_notifications, sync_notifications
from app.routers.recipes import (
    _image_extension,
    _recipe_to_response,
    create_recipe,
    list_allergies,
    list_equipment,
)
from app.schemas import ProfileUpdate, RecipeCreate
from app.services.aiRecommendation import _rank_database_recipes
from app.services.query_parser import parse_smart_query


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

    def test_recipe_response_derives_allergen_tags_from_ingredient_mapping(self):
        category = IngredientCategory(category_name="Dairy")
        unit = MeasurementUnit(unit_name="millilitre", unit_symbol="ml", unit_type="volume")
        cuisine = Cuisine(cuisine_name="European")
        allergy = Allergy(allergy_name="Dairy")
        self.db.add_all([category, unit, cuisine, allergy])
        self.db.flush()
        milk = Ingredient(
            ingredient_category_id=category.ingredient_category_id,
            ingredient_name="Milk",
            default_measurement_unit_id=unit.measurement_unit_id,
            estimated_unit_cost=0.01,
            is_active=True,
        )
        recipe = Recipe(
            author_user_id=self.contributor.user_id,
            cuisine_id=cuisine.cuisine_id,
            title="Milk recipe",
            servings=1,
            difficulty="easy",
            estimated_cost=1,
            status="published",
        )
        self.db.add_all([milk, recipe])
        self.db.flush()
        self.db.execute(
            ingredient_allergens.insert().values(
                ingredient_id=milk.ingredient_id,
                allergy_id=allergy.allergy_id,
            )
        )
        self.db.add(
            RecipeIngredient(
                recipe_id=recipe.recipe_id,
                ingredient_id=milk.ingredient_id,
                measurement_unit_id=unit.measurement_unit_id,
                quantity=100,
                sort_order=1,
            )
        )
        self.db.commit()

        response = _recipe_to_response(recipe, self.db)

        self.assertEqual(response["allergen_tags"], ["Dairy"])

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

    def test_profile_allergies_must_come_from_database_options(self):
        self.db.add(Allergy(allergy_name="Dairy"))
        self.db.commit()

        with self.assertRaises(HTTPException) as error:
            apply_profile_update(
                self.db,
                self.user,
                ProfileUpdate(allergies=["Dairy", "Unknown option"]),
            )

        self.assertEqual(error.exception.status_code, 400)
        self.assertEqual(self.db.query(Allergy).count(), 1)
        self.assertEqual(self.user.allergies, [])

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

    def test_notification_sync_removes_stale_shopping_reminder(self):
        key = f"shopping_list:{self.user.user_id}:{date.today().isoformat()}"
        self.db.add(
            Notification(
                user_id=self.user.user_id,
                notification_type="shopping_reminder",
                title="Shopping list reminder",
                message="Your shopping list still has unpurchased items.",
                dedupe_key=key,
            )
        )
        self.db.commit()

        sync_notifications(self.db, self.user.user_id)

        self.assertIsNone(
            self.db.query(Notification)
            .filter(Notification.user_id == self.user.user_id, Notification.dedupe_key == key)
            .first()
        )

    def test_notification_sync_expires_state_reminders_but_keeps_recipe_events(self):
        yesterday = date.today() - timedelta(days=1)
        recipe_update = Notification(
            user_id=self.user.user_id,
            notification_type="recipe_update",
            title="Saved recipe updated",
            message="A saved recipe changed.",
            dedupe_key=f"recipe_update:{self.user.user_id}:42:2026-09-27T10:00:00",
        )
        self.db.add_all(
            [
                Notification(
                    user_id=self.user.user_id,
                    notification_type="meal_reminder",
                    title="Tomorrow's meals",
                    message="You have meals planned for tomorrow.",
                    dedupe_key=f"meal_plan:{self.user.user_id}:{yesterday.isoformat()}",
                ),
                Notification(
                    user_id=self.user.user_id,
                    notification_type="shopping_reminder",
                    title="Shopping list reminder",
                    message="Your shopping list still has unpurchased items.",
                    dedupe_key=f"shopping_list:{self.user.user_id}:{yesterday.isoformat()}",
                ),
                recipe_update,
            ]
        )
        self.db.commit()

        sync_notifications(self.db, self.user.user_id)

        remaining = self.db.query(Notification).filter(Notification.user_id == self.user.user_id).all()
        self.assertEqual([item.notification_type for item in remaining], ["recipe_update"])

    def test_cleared_recipe_update_is_not_recreated_by_notification_sync(self):
        self.db.add(
            Notification(
                user_id=self.user.user_id,
                notification_type="recipe_update",
                title="Saved recipe updated",
                message="A saved recipe changed.",
                dedupe_key=f"recipe_update:{self.user.user_id}:42:2026-09-27T10:00:00",
                read_at=datetime.now(),
            )
        )
        self.db.commit()

        self.assertEqual(delete_read_notifications(self.db, self.user), [])
        sync_notifications(self.db, self.user.user_id)

        self.assertEqual(
            self.db.query(Notification).filter(Notification.user_id == self.user.user_id).count(),
            0,
        )

    def test_fallback_ranking_respects_explicit_query_constraints(self):
        recipes = [
            {
                "id": 1,
                "title": "Safe toast",
                "cuisine": "European",
                "estimated_cost": 3.0,
                "rating": 4.0,
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
                "rating": 4.0,
                "prep_time": 5,
                "cook_time": 10,
                "dietary_tags": ["Vegetarian"],
                "allergen_tags": ["Dairy"],
                "ingredients": ["milk", "pasta"],
                "required_equipment": [{"name": "Hob"}],
            },
        ]
        constraints = parse_smart_query("vegetarian meals under $5")
        result = _rank_database_recipes(recipes, constraints, self.user)
        self.assertEqual([recipe["id"] for recipe in result], [1, 2])

    def test_image_type_is_detected_from_bytes(self):
        self.assertEqual(_image_extension(b"\x89PNG\r\n\x1a\nrest"), ".png")
        self.assertIsNone(_image_extension(b"not-an-image"))


if __name__ == "__main__":
    unittest.main()
