"""Recipe ownership, visibility and comment permissions (runs on MySQL, 张展赫 ZZH)."""

import unittest

from fastapi import HTTPException

from app.models import (
    Cuisine,
    Notification,
    Recipe,
    RecipeComment,
    RecipeRating,
    Role,
    User,
)
from app.routers.recipes import (
    _recipe_to_response,
    add_recipe_comment,
    add_recipe_rating,
    create_recipe,
    delete_recipe,
    get_recipe,
    get_saved_recipe_ids,
    list_my_recipes,
    toggle_saved_recipe,
    update_recipe,
)
from app.schemas import CommentCreate, RatingCreate, RecipeCreate, RecipeUpdate
from base import MySQLTestCase


class RecipePermissionTest(MySQLTestCase):
    def setUp(self):
        super().setUp()
        for name in ("student", "contributor", "administrator"):
            self.db.add(Role(role_name=name))
        self.db.flush()

        self.ben = User(
            role_id=self._role_id("contributor"),
            email="ben@example.com",
            password_hash="test-only",
            display_name="Ben Contributor",
        )
        self.eve = User(
            role_id=self._role_id("contributor"),
            email="eve@example.com",
            password_hash="test-only",
            display_name="Eve Contributor",
        )
        self.student = User(
            role_id=self._role_id("student"),
            email="student@example.com",
            password_hash="test-only",
            display_name="Student Alice",
        )
        self.admin = User(
            role_id=self._role_id("administrator"),
            email="admin@example.com",
            password_hash="test-only",
            display_name="The Admin",
        )
        self.cuisine = Cuisine(cuisine_name="Italian")
        self.db.add_all([self.ben, self.eve, self.student, self.admin, self.cuisine])
        self.db.flush()

        self.published = Recipe(
            author_user_id=self.ben.user_id,
            cuisine_id=self.cuisine.cuisine_id,
            title="Published Pasta",
            servings=2,
            difficulty="easy",
            estimated_cost=4.0,
            status="published",
        )
        self.draft = Recipe(
            author_user_id=self.ben.user_id,
            cuisine_id=self.cuisine.cuisine_id,
            title="Draft Soup",
            servings=1,
            difficulty="easy",
            estimated_cost=3.0,
            status="draft",
        )
        self.archived = Recipe(
            author_user_id=self.ben.user_id,
            cuisine_id=self.cuisine.cuisine_id,
            title="Archived Toast",
            servings=1,
            difficulty="easy",
            estimated_cost=2.0,
            status="archived",
        )
        self.db.add_all([self.published, self.draft, self.archived])
        self.db.commit()

    def _role_id(self, name):
        return self.db.query(Role).filter(Role.role_name == name).first().role_id

    def test_create_recipe_uses_current_contributor(self):
        recipe = create_recipe(
            RecipeCreate(title="My Recipe", cuisine="Chinese"), self.db, self.ben
        )
        self.assertEqual(recipe["status"], "Draft")
        stored = self.db.get(Recipe, recipe["id"])
        self.assertEqual(stored.author_user_id, self.ben.user_id)

    def test_my_recipes_only_returns_own(self):
        create_recipe(RecipeCreate(title="Mine", cuisine="Chinese"), self.db, self.ben)
        ben_recipes = list_my_recipes(self.db, self.ben)
        eve_recipes = list_my_recipes(self.db, self.eve)
        self.assertTrue(any(r["title"] == "Mine" for r in ben_recipes))
        self.assertEqual(eve_recipes, [])

    def test_update_and_delete_require_ownership(self):
        with self.assertRaises(HTTPException) as error:
            update_recipe(self.published.recipe_id, RecipeUpdate(title="Stolen"), self.db, self.eve)
        self.assertEqual(error.exception.status_code, 404)
        with self.assertRaises(HTTPException) as error:
            delete_recipe(self.published.recipe_id, self.db, self.eve)
        self.assertEqual(error.exception.status_code, 404)

        updated = update_recipe(self.published.recipe_id, RecipeUpdate(title="Renamed"), self.db, self.ben)
        self.assertEqual(updated["title"], "Renamed")

    def test_invalid_status_rejected(self):
        with self.assertRaises(HTTPException) as error:
            update_recipe(self.published.recipe_id, RecipeUpdate(status="invisible"), self.db, self.ben)
        self.assertEqual(error.exception.status_code, 400)

    def test_draft_and_archived_hidden_from_other_users(self):
        self.assertIsNotNone(get_recipe(self.published.recipe_id, self.db, None))
        self.assertIsNotNone(get_recipe(self.published.recipe_id, self.db, self.student))

        for user in (None, self.student, self.eve):
            with self.assertRaises(HTTPException) as error:
                get_recipe(self.draft.recipe_id, self.db, user)
            self.assertEqual(error.exception.status_code, 404)
            with self.assertRaises(HTTPException) as error:
                get_recipe(self.archived.recipe_id, self.db, user)
            self.assertEqual(error.exception.status_code, 404)

        self.assertEqual(get_recipe(self.draft.recipe_id, self.db, self.ben)["title"], "Draft Soup")
        self.assertEqual(get_recipe(self.archived.recipe_id, self.db, self.admin)["title"], "Archived Toast")

    def test_rating_uses_current_user(self):
        add_recipe_rating(self.published.recipe_id, RatingCreate(rating=4), self.db, self.student)
        rating = self.db.get(RecipeRating, {"user_id": self.student.user_id, "recipe_id": self.published.recipe_id})
        self.assertEqual(rating.rating, 4)

    def test_saving_and_reading_saved_recipes(self):
        self.assertEqual(get_saved_recipe_ids(self.db, self.student), [])
        result = toggle_saved_recipe(self.published.recipe_id, self.db, self.student)
        self.assertTrue(result.saved)
        self.assertEqual(get_saved_recipe_ids(self.db, self.student), [self.published.recipe_id])
        self.assertEqual(get_saved_recipe_ids(self.db, self.eve), [])

    def test_comment_requires_published_and_non_empty(self):
        with self.assertRaises(HTTPException) as error:
            add_recipe_comment(self.draft.recipe_id, CommentCreate(text="hi"), self.db, self.student)
        self.assertEqual(error.exception.status_code, 404)
        with self.assertRaises(HTTPException) as error:
            add_recipe_comment(self.published.recipe_id, CommentCreate(text="   "), self.db, self.student)
        self.assertEqual(error.exception.status_code, 400)

    def test_comment_appears_on_detail_and_links_author(self):
        response = add_recipe_comment(
            self.published.recipe_id, CommentCreate(text="Tastes great"), self.db, self.student
        )
        comments = response["comments"]
        self.assertEqual(len(comments), 1)
        self.assertEqual(comments[0]["author"], "Student Alice")
        self.assertEqual(comments[0]["text"], "Tastes great")

    def test_hidden_comments_are_not_returned(self):
        self.db.add(
            RecipeComment(
                recipe_id=self.published.recipe_id,
                user_id=self.student.user_id,
                comment_text="hidden",
                is_hidden=True,
            )
        )
        self.db.commit()
        response = _recipe_to_response(self.published, self.db, include_comments=True)
        self.assertEqual(response["comments"], [])

    def test_recipe_update_notifies_students_who_saved_it(self):
        # A student saves the recipe, then the contributor edits it.
        toggle_saved_recipe(self.published.recipe_id, self.db, self.student)
        update_recipe(self.published.recipe_id, RecipeUpdate(title="Renamed"), self.db, self.ben)

        notifications = (
            self.db.query(Notification)
            .filter(Notification.user_id == self.student.user_id)
            .all()
        )
        self.assertTrue(
            any(n.notification_type == "recipe_update" for n in notifications),
            "expected a recipe_update notification for the saver",
        )
        self.assertTrue(any(n.title == "Saved recipe updated" for n in notifications))

    def test_recipe_update_skips_users_who_did_not_save(self):
        # Eve (a contributor who did not save the recipe) gets no notification.
        update_recipe(self.published.recipe_id, RecipeUpdate(title="Renamed again"), self.db, self.ben)
        notifications = (
            self.db.query(Notification)
            .filter(Notification.user_id == self.eve.user_id)
            .all()
        )
        self.assertEqual(notifications, [])


if __name__ == "__main__":
    unittest.main()
