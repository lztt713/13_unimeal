"""Authentication, registration and profile tests (runs on MySQL, Zhang Zhanhe/ZZH)."""

import unittest

from fastapi import HTTPException

from app.auth import admin_user, contributor_user, hash_password, student_user, verify_password
from app.models import Allergy, Role, User
from app.routers.auth import (
    apply_profile_update,
    authenticate_user,
    register_user,
    user_to_response,
)
from app.schemas import ProfileUpdate
from base import MySQLTestCase


class AuthFlowTest(MySQLTestCase):
    def setUp(self):
        super().setUp()
        for name in ("student", "contributor", "administrator"):
            self.db.add(Role(role_name=name))
        self.db.commit()

    def test_password_hash_round_trip(self):
        encoded = hash_password("hunter2secret")
        self.assertTrue(encoded.startswith("pbkdf2_sha256$"))
        self.assertTrue(verify_password("hunter2secret", encoded))
        self.assertFalse(verify_password("wrong-password", encoded))

    def test_register_creates_student_and_hashes_password(self):
        user = register_user(self.db, "Alice Student", "alice@example.com", "secret123", "student")
        self.assertEqual(user.email, "alice@example.com")
        self.assertEqual(user.role.role_name, "student")
        self.assertNotEqual(user.password_hash, "secret123")
        self.assertTrue(verify_password("secret123", user.password_hash))

    def test_register_normalizes_email_and_rejects_duplicate(self):
        register_user(self.db, "Alice", "Alice@Example.com", "secret123", "student")
        with self.assertRaises(HTTPException) as error:
            register_user(self.db, "Alice Two", "alice@example.com", "secret456", "student")
        self.assertEqual(error.exception.status_code, 409)

    def test_register_rejects_administrator_role(self):
        with self.assertRaises(HTTPException) as error:
            register_user(self.db, "Bad Admin", "bad@example.com", "secret123", "administrator")
        self.assertEqual(error.exception.status_code, 400)

    def test_register_rejects_invalid_email(self):
        with self.assertRaises(HTTPException) as error:
            register_user(self.db, "No At", "not-an-email", "secret123", "student")
        self.assertEqual(error.exception.status_code, 400)

    def test_authenticate_rejects_wrong_password(self):
        register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        with self.assertRaises(HTTPException) as error:
            authenticate_user(self.db, "alice@example.com", "wrong-password")
        self.assertEqual(error.exception.status_code, 401)

    def test_authenticate_rejects_suspended_user(self):
        user = register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        user.is_active = False
        self.db.commit()
        with self.assertRaises(HTTPException) as error:
            authenticate_user(self.db, "alice@example.com", "secret123")
        self.assertEqual(error.exception.status_code, 403)

    def test_authenticate_returns_user_on_success(self):
        register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        user = authenticate_user(self.db, "alice@example.com", "secret123")
        self.assertEqual(user.display_name, "Alice")

    def test_role_dependencies_enforce_roles(self):
        student = register_user(self.db, "S", "s@example.com", "secret123", "student")
        contributor = register_user(self.db, "C", "c@example.com", "secret123", "contributor")

        self.assertEqual(student_user(user=student).user_id, student.user_id)
        self.assertEqual(contributor_user(user=contributor).user_id, contributor.user_id)
        with self.assertRaises(HTTPException) as error:
            admin_user(user=student)
        self.assertEqual(error.exception.status_code, 403)

    def test_profile_update_persists_preferences(self):
        user = register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        self.db.add_all([Allergy(allergy_name="Peanut"), Allergy(allergy_name="Dairy")])
        self.db.commit()
        payload = ProfileUpdate(
            displayName="Alice Updated",
            weeklyBudget=45.5,
            cookingSkill="Comfortable",
            kitchenAccess="Private kitchen",
            dietaryPreferences=["Vegetarian", "Vegan"],
            allergies=["Peanut", "Dairy"],
            favouriteCuisines=["Italian", "Japanese"],
        )
        response = apply_profile_update(self.db, user, payload)
        self.assertEqual(response["display_name"], "Alice Updated")
        self.assertEqual(response["weekly_budget"], 45.5)
        self.assertEqual(response["cooking_skill"], "Comfortable")
        self.assertEqual(response["kitchen_access"], "Private kitchen")
        self.assertEqual(set(response["dietary_preferences"]), {"Vegetarian", "Vegan"})
        self.assertEqual(set(response["allergies"]), {"Peanut", "Dairy"})
        self.assertEqual(response["favourite_cuisines"], ["Italian", "Japanese"])

        reloaded = self.db.get(User, user.user_id)
        self.assertEqual(reloaded.cooking_skill, "intermediate")
        self.assertEqual(reloaded.kitchen_access, "full")
        self.assertEqual({a.allergy_name for a in reloaded.allergies}, {"Peanut", "Dairy"})
        self.assertEqual({t.tag_name for t in reloaded.dietary_preferences}, {"Vegetarian", "Vegan"})

    def test_profile_update_rejects_unknown_allergy_without_creating_it(self):
        user = register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        self.db.add(Allergy(allergy_name="Dairy"))
        self.db.commit()

        with self.assertRaises(HTTPException) as error:
            apply_profile_update(
                self.db,
                user,
                ProfileUpdate(displayName="Should not persist", allergies=["Dairy", "Dragonfruit"]),
            )

        self.assertEqual(error.exception.status_code, 400)
        self.assertIn("Dragonfruit", error.exception.detail)
        self.assertIsNone(
            self.db.query(Allergy).filter(Allergy.allergy_name == "Dragonfruit").first()
        )
        self.db.refresh(user)
        self.assertEqual(user.display_name, "Alice")
        self.assertEqual(user.allergies, [])

    def test_profile_update_uses_canonical_allergy_rows_case_insensitively(self):
        user = register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        dairy = Allergy(allergy_name="Dairy")
        self.db.add(dairy)
        self.db.commit()

        response = apply_profile_update(
            self.db,
            user,
            ProfileUpdate(allergies=["dairy", " Dairy "]),
        )

        self.assertEqual(response["allergies"], ["Dairy"])
        self.assertEqual(self.db.query(Allergy).count(), 1)

    def test_user_response_shape(self):
        user = register_user(self.db, "Alice", "alice@example.com", "secret123", "student")
        self.db.add(Allergy(allergy_name="Dairy"))
        self.db.commit()
        response = user_to_response(user)
        self.assertEqual(response["role"], "student")
        self.assertEqual(response["cooking_skill"], "Beginner")
        self.assertEqual(response["kitchen_access"], "Shared kitchen")
        self.assertEqual(response["weekly_budget"], 0.0)
        self.assertEqual(response["favourite_cuisines"], [])


if __name__ == "__main__":
    unittest.main()
