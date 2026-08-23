# Database handoff and validation guide

## Source of truth

`database/master_schema.sql` is the only schema-definition script for UniMeal Planner. Qichen Hu, Database Architect, maintains it. Propose schema changes with the affected UI/API requirement; do not modify the master script independently.

The logical design is split into readable diagrams in [`ERD.md`](ERD.md).

## Local setup

### New database

1. Install MySQL 8.0.16 or later.
2. Run `database/master_schema.sql`.
3. Run `database/sample_data.sql`.
4. Run `database/validation_queries.sql`.
5. Confirm every validation row is `PASS`.

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

The repository now has Vue Dashboard and Recipe Library views plus a FastAPI prototype. The Vue views still use mock data, and the FastAPI prototype currently uses temporary SQLite models. It must not be pointed at MySQL by changing only a connection string: the backend needs an explicit model/API mapping first.

Keep MySQL normalised during backend integration, translate database snake_case to the frontend camelCase payload, then replace mock calls after the API contract is verified.
