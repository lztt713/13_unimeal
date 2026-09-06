import json
import unittest
from pathlib import Path


SCHEMA_PATH = Path(__file__).resolve().parents[1] / "recommendation_schema.json"


class RecommendationSchemaTests(unittest.TestCase):
    def test_schema_declares_required_response_and_meal_fields(self):
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

        self.assertEqual(
            schema["required"],
            ["plan", "shopping_notes", "assumptions", "safety_notice"],
        )
        meal = schema["properties"]["plan"]["items"]["properties"]["meals"]["items"]
        self.assertEqual(
            meal["required"],
            ["meal_type", "recipe_name", "servings", "estimated_cost_nzd", "prep_minutes"],
        )
        self.assertEqual(meal["properties"]["meal_type"]["enum"], ["breakfast", "lunch", "dinner", "snack"])


if __name__ == "__main__":
    unittest.main()
