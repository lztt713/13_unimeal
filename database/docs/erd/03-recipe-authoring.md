# ERD 3 — Recipe authoring

## What this part does

It describes how a contributor creates a complete recipe with a cuisine, ordered steps and measured ingredients.

```mermaid
erDiagram
  USERS ||--o{ RECIPES : authors
  CUISINES ||--o{ RECIPES : classifies
  RECIPES ||--o{ RECIPE_STEPS : contains
  RECIPES ||--o{ RECIPE_INGREDIENTS : requires
  INGREDIENTS ||--o{ RECIPE_INGREDIENTS : appears_in
  MEASUREMENT_UNITS ||--o{ RECIPE_INGREDIENTS : measures
  RECIPES ||--o{ RECIPE_EQUIPMENT : requires
  EQUIPMENT ||--o{ RECIPE_EQUIPMENT : selected_in
```

## Simple explanation

> A recipe is the centre of this diagram. One contributor can write many recipes; every recipe can have many ordered steps and many ingredients. Quantity and unit are stored in `recipe_ingredients` because 200 grams of rice belongs to a particular recipe, not to rice in general.

## Key design points

| Table | Important keys / fields | Why it exists |
| --- | --- | --- |
| `recipes` | author/cuisine FKs, `image_url`, time, servings, difficulty, status | Holds the main recipe-card and detail-page data. |
| `recipe_steps` | `(recipe_id, step_number)` (UK) | Keeps instructions ordered and prevents two step 1 records. |
| `recipe_ingredients` | recipe/ingredient/unit FKs, quantity, `sort_order` | Records the exact measured ingredients required for a recipe. |
| `equipment` | `equipment_id` (PK), `equipment_name` (UK), `is_active` | Defines selectable cooking equipment; names must not be blank. |
| `recipe_equipment` | `(recipe_id, equipment_id)` (composite PK), two FKs | Stores each requirement once; recipe deletion cascades, equipment deletion is restricted while referenced. |

## Current status

The frontend has recipe submission/detail pages and consumes `requiredEquipmentIds` / `requiredEquipment`. Database storage is ready; the equipment API/ORM integration remains backend work. `recipes.image_url` stores the URL or path, not image bytes.

[Back to ERD guide](../ERD.md)
