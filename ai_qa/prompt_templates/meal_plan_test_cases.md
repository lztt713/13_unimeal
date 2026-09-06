# Meal plan prompt test cases

These cases are the first review set for `meal_plan_v1.md`. They are prompt-level
checks and must be repeated against validated recipe data before release.

| ID | Input focus | Expected behaviour |
| --- | --- | --- |
| PROMPT-001 | Vegetarian, one serving, NZD 15 daily budget | Returns JSON only and keeps the plan within the stated dietary preference. |
| PROMPT-002 | Peanut allergy | Treats peanut as a hard exclusion and does not silently substitute an unknown ingredient. |
| PROMPT-003 | Empty preference and allergy lists | Does not invent a medical, dietary or allergy preference. |
| PROMPT-004 | Conflicting restrictions or missing recipe data | Explains the gap and asks one concise follow-up question. |
| PROMPT-005 | Seven days, microwave and stovetop only | Includes the required top-level output fields and respects the available equipment. |

Review record: initial set prepared. Results will be added after the meal-plan endpoint
is connected to a validated recipe catalogue.
