# UniMeal Planner ERD

This is the authoritative logical ERD for the MySQL schema in [`database/master_schema.sql`](../../database/master_schema.sql). To keep it readable, the 28 tables are shown as seven focused diagrams instead of one crowded image. Recipe authoring now includes `equipment` and `recipe_equipment`.

Repeated tables are intentional: each diagram is a different view of the **same** database, not a duplicate design.

## Read the notation

- `||--o{` means one row on the left can relate to zero or many rows on the right.
- A table between two parent tables is a junction table. It models a many-to-many relationship and prevents duplicate selections.
- `PK` means primary key; `FK` means foreign key; `UK` means unique key.

## Diagram guide

| Diagram | What it explains | Current project connection |
| --- | --- | --- |
| [1. Accounts and preferences](erd/01-accounts-and-preferences.md) | Roles, user identity, dietary preferences and allergies | MySQL-backed accounts and profile data, including weekly budget. |
| [2. Ingredients and safety](erd/02-ingredients-and-safety.md) | Reusable ingredients, units, categories and allergens | The prototype has ingredients; MySQL adds shared units, categories and safety data. |
| [3. Recipe authoring](erd/03-recipe-authoring.md) | Creating a recipe, its steps, ingredient quantities and equipment | Equipment storage is ready for the frontend v6 API contract. |
| [4. Recipe discovery and feedback](erd/04-recipe-discovery-and-feedback.md) | Tags, favourites, ratings and comments | Directly supports the current Recipe Library card and filters. |
| [5. Meal planning and budget](erd/05-meal-planning-and-budget.md) | Weekly plan, meal slots and budget periods | Matches the Dashboard concept and the future Calendar/Budget pages. |
| [6. Shopping and pantry](erd/06-shopping-and-pantry.md) | Generated grocery lists, purchase state and home inventory | Matches the backend ingredient-merging prototype and future Shopping List page. |
| [7. Administration and notifications](erd/07-administration-and-notifications.md) | Reports, review status and reminders | Future Admin and notification features. |


> The database is organised by user journey. First we identify the user and their food restrictions. Then recipes are built from reusable ingredients and shown through tags, ratings and favourites. A user can place recipes into a weekly plan, generate a shopping list, track spending, and finally use reporting and notifications to keep the platform safe.

## Current integration note

Vue reads data through the FastAPI/SQLAlchemy backend using MySQL. The new equipment tables need ORM and endpoint integration; see [the database guide](README.md). This database update does not implement the HTTP endpoints.

`vw_recipe_cards` is a read-only MySQL view for the current Recipe Library card payload. It is intentionally not shown as a physical ERD table.
