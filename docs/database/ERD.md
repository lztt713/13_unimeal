# UniMeal Planner ERD

This is the authoritative logical ERD for the MySQL schema in `database/master_schema.sql`. The Database Architect owns schema changes; other team members should propose changes rather than editing the master script directly.

```mermaid
erDiagram
  ROLES ||--o{ USERS : assigns
  USERS ||--o{ USER_DIETARY_PREFERENCES : sets
  DIETARY_TAGS ||--o{ USER_DIETARY_PREFERENCES : selected_by
  USERS ||--o{ USER_ALLERGIES : declares
  ALLERGIES ||--o{ USER_ALLERGIES : selected_by
  INGREDIENT_CATEGORIES ||--o{ INGREDIENTS : groups
  MEASUREMENT_UNITS ||--o{ INGREDIENTS : defaults_to
  INGREDIENTS ||--o{ INGREDIENT_ALLERGENS : contains
  ALLERGIES ||--o{ INGREDIENT_ALLERGENS : maps
  USERS ||--o{ RECIPES : authors
  CUISINES ||--o{ RECIPES : classifies
  RECIPES ||--o{ RECIPE_DIETARY_TAGS : labelled
  DIETARY_TAGS ||--o{ RECIPE_DIETARY_TAGS : labels
  RECIPES ||--o{ RECIPE_INGREDIENTS : requires
  INGREDIENTS ||--o{ RECIPE_INGREDIENTS : appears_in
  MEASUREMENT_UNITS ||--o{ RECIPE_INGREDIENTS : measures
  RECIPES ||--o{ RECIPE_STEPS : contains
  USERS ||--o{ SAVED_RECIPES : saves
  RECIPES ||--o{ SAVED_RECIPES : saved
  USERS ||--o{ RECIPE_RATINGS : rates
  RECIPES ||--o{ RECIPE_RATINGS : rated
  USERS ||--o{ RECIPE_COMMENTS : writes
  RECIPES ||--o{ RECIPE_COMMENTS : receives
  USERS ||--o{ BUDGET_PERIODS : owns
  USERS ||--o{ MEAL_PLANS : owns
  MEAL_PLANS ||--o{ MEAL_PLAN_ENTRIES : schedules
  RECIPES ||--o{ MEAL_PLAN_ENTRIES : planned
  USERS ||--o{ SHOPPING_LISTS : owns
  MEAL_PLANS ||--o{ SHOPPING_LISTS : generates
  SHOPPING_LISTS ||--o{ SHOPPING_LIST_ITEMS : contains
  INGREDIENTS ||--o{ SHOPPING_LIST_ITEMS : aggregates
  USERS ||--o{ PANTRY_ITEMS : tracks
  INGREDIENTS ||--o{ PANTRY_ITEMS : stocked
  USERS ||--o{ NOTIFICATIONS : receives
  USERS ||--o{ CONTENT_REPORTS : files
  RECIPES ||--o{ CONTENT_REPORTS : reported
  RECIPE_COMMENTS ||--o{ CONTENT_REPORTS : reported
```

## Design decisions

- All many-to-many relationships use junction tables with composite primary keys, preventing duplicate selections, tags, favourites, ratings, or allergen declarations.
- `recipe_ingredients` carries quantity and unit because they belong to the recipe-ingredient relationship, not to either parent entity.
- Meal-plan entries are unique per meal slot, and shopping lists retain generated quantities and actual purchase costs to preserve spending history.
- Passwords are represented only by `password_hash`; the database rejects values shorter than 20 characters. The API must apply Argon2 or bcrypt before insertion.
- The user and ingredient preference tables support the AI recommendation module without exposing user passwords or unnecessary personal data.
