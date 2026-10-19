# UniMeal Planner ERD

This is the authoritative logical ERD for the MySQL schema in [`database/master_schema.sql`](../master_schema.sql). To keep it readable, the 28 tables are shown as seven focused diagrams instead of one crowded image. Recipe authoring includes `equipment` and `recipe_equipment`.

Repeated tables are intentional: each diagram is a different view of the **same** database, not a duplicate design.

## Read the notation

- `||--o{` means one row on the left can relate to zero or many rows on the right.
- A table between two parent tables is a junction table. It models a many-to-many relationship and prevents duplicate selections.
- `PK` means primary key; `FK` means foreign key; `UK` means unique key.

## Diagram guide

| Diagram | What it explains | Current project connection |
| --- | --- | --- |
| [1. Accounts and preferences](erd/01-accounts-and-preferences.md) | Roles, user identity, dietary preferences and allergies | MySQL-backed accounts and profile data, including weekly budget. |
| [2. Ingredients and safety](erd/02-ingredients-and-safety.md) | Reusable ingredients, units, categories and allergens | Supports shared ingredient data and allergy warnings. |
| [3. Recipe authoring](erd/03-recipe-authoring.md) | Creating a recipe, its steps, ingredient quantities and equipment | Supports the contributor recipe workflow and equipment API contract. |
| [4. Recipe discovery and feedback](erd/04-recipe-discovery-and-feedback.md) | Tags, favourites, ratings and comments | Directly supports the current Recipe Library card and filters. |
| [5. Meal planning and budget](erd/05-meal-planning-and-budget.md) | Weekly plan, meal slots and budget periods | Supports the calendar, dashboard and budget pages. |
| [6. Shopping and pantry](erd/06-shopping-and-pantry.md) | Generated grocery lists, purchase state and home inventory | Supports ingredient merging, purchase history and the shopping page. |
| [7. Administration and notifications](erd/07-administration-and-notifications.md) | Reports, review status and reminders | Supports administrator review and user reminders. |


> The database is organised by user journey. First we identify the user and their food restrictions. Then recipes are built from reusable ingredients and shown through tags, ratings and favourites. A user can place recipes into a weekly plan, generate a shopping list, track spending, and finally use reporting and notifications to keep the platform safe.

## Current integration note

Vue reads data through the FastAPI/SQLAlchemy backend using MySQL. Equipment is
integrated through the ORM, request schemas and recipe endpoints; see
[the database guide](../README.md).

`vw_recipe_cards` is a read-only MySQL view for the current Recipe Library card payload. It is intentionally not shown as a physical ERD table.
