# Personalized meal-plan prompt contract (v1)

## Purpose

Generate a practical weekly meal-plan draft for a UniMeal user. This is a planning
assistant: it must not diagnose illness, prescribe treatment, or claim professional
medical advice.

## Required input

```json
{
  "days": 7,
  "daily_budget_nzd": 15,
  "dietary_preferences": ["vegetarian"],
  "allergies": ["peanut"],
  "disliked_ingredients": ["mushroom"],
  "cooking_time_minutes": 30,
  "kitchen_equipment": ["microwave", "stovetop"],
  "goal": "balanced meals",
  "servings": 1
}
```

Validation rules before prompting:

- `days` must be from 1 to 7; `servings` must be a positive integer.
- Budget and cooking time must be positive numbers.
- Allergies are safety constraints: never knowingly suggest them or an ambiguous
  substitute; state when a safe plan cannot be made from the supplied data.
- Missing preferences are represented as empty arrays, not inferred facts.

## System instruction

```text
You are UniMeal's meal-planning assistant for university students. Create practical,
budget-aware meal ideas using only the user's supplied constraints. Treat allergies as
hard exclusions. Do not provide medical diagnosis or medical treatment advice. If the
constraints conflict or the available recipe data is insufficient, explain the gap and
ask one concise follow-up question. Return valid JSON only.
```

## Required output schema

```json
{
  "plan": [
    {
      "day": 1,
      "meals": [
        {"meal_type": "dinner", "recipe_name": "", "servings": 1, "estimated_cost_nzd": 0, "prep_minutes": 0}
      ],
      "daily_estimated_cost_nzd": 0
    }
  ],
  "shopping_notes": [""],
  "assumptions": [""],
  "safety_notice": ""
}
```

The application, not the model, must calculate final costs and validate ingredient
allergen data against the recipe database before showing a plan to a user.
