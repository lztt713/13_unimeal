# Database handoff and validation guide

## Source of truth

`database/master_schema.sql` is the only schema-definition script for UniMeal Planner. Qichen Hu, Database Architect, maintains it. Propose schema changes with the affected UI/API requirement; do not modify the master script independently.

The logical design is split into readable diagrams in [`ERD.md`](ERD.md).

## Local setup

### New database

1. Install MySQL 8.0.16 or later.
2. Run `database/master_schema.sql`.
3. Run `database/sample_data.sql`.
4. Run `database/migrations/20260923_frontend_equipment_and_allergens.sql`.
5. Optionally run `database/validation_queries.sql` against a disposable development database with the seed fixtures present. Confirm every validation row is `PASS`.

The current schema has 28 base tables. `users.weekly_budget` and
`notifications.dedupe_key` are included in fresh installations. If optional recipe
detail/demo migrations are needed, apply them before the 20260923 migration so
their known recipes and ingredients can receive the reference mappings.

### Frontend v6: existing database

Back up the target database, then run only
`database/migrations/20260923_frontend_equipment_and_allergens.sql` for this update.
Do not re-import `sample_data.sql` over real development data: that older seed
script updates existing recipes. The new migration adds `equipment` and
`recipe_equipment`, fills missing profile/notification columns, and adds missing
equipment/allergen reference data. It leaves existing accounts, passwords,
budgets, recipe content, and non-empty equipment selections intact.

The migration is repeatable. Re-running restores its missing reference rows and
known ingredient mappings; it only seeds recipe equipment when the list is empty.
If an author intentionally clears a seeded recipe's equipment, re-running this
data migration will populate that empty list again. This is an installation /
upgrade step, not something to run on every application startup. MySQL DDL is
not transactionally reversible; use the backup to recover a failed upgrade.

The backend must expose equipment as `{id, name}`, persist `requiredEquipmentIds`
through `recipe_equipment`, and return `requiredEquipment` on recipe details.
SQL changes alone do not implement those endpoints.

### Existing database created before the frontend alignment update

1. Run `database/migrations/20260823_frontend_alignment.sql`.
2. Run `database/sample_data.sql` to update/load current preview records.
3. Run `database/validation_queries.sql` and confirm every row is `PASS`.

The migration is safe to rerun: it adds `recipes.image_url`, `ingredients.estimated_unit_cost`, the corresponding non-negative check and the `vw_recipe_cards` read view only when necessary.

`sample_data.sql` is for local development and testing only. It uses `@unimeal.test` accounts and placeholder bcrypt-formatted hashes; never use these accounts or hashes in production.

## Validation ownership

| Rule | Enforced in database | Enforced in API/UI |
| --- | --- | --- |
| Email format, uniqueness and active account | `CHECK`, unique key | Normalise email and show a useful message. |
| Password security | No plaintext field; minimum hash length | Hash with Argon2/bcrypt; never log a password. |
| Recipe quality | Servings, costs, quantities and ordered steps | Required fields and friendly validation. |
| Recipe-card data | Image URL, normalised tags, calculated time/rating | Return the agreed camelCase API payload. |
| Meal calendar | Unique plan/week and meal/date/slot | Ensure dates belong to the selected week. |
| Shopping and budget | Non-negative reference/actual costs; purchase timestamp consistency | Aggregate equivalent ingredient/unit rows. |
| Ratings and relationships | Foreign keys, range checks and composite keys | Enforce permissions by user role. |
| Report review state | Exactly one reported target is enforced by a `CHECK` | Require reviewer and review time when resolving or dismissing. |

## Current integration boundary

The application uses Vue and a FastAPI/SQLAlchemy backend with a MySQL connection.
Frontend v6 already requests equipment/allergy options and image uploads. The
new equipment tables still require backend ORM/schema/endpoint integration;
this database update does not modify Python or Vue source files.

Keep MySQL normalised and translate database snake_case to the frontend camelCase
payload. Allergy links express known positive mappings; no link does not certify
an ingredient or recipe as allergen-free. Compound products require label review.
