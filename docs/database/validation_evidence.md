# Database validation evidence - Week 4

Date: 2026-08-06
Database: local MySQL Community Server 26.7.0
Schema: `unimeal_planner`

## Execution record

The following scripts were run in order against the local MySQL instance:

1. `database/master_schema.sql`
2. `database/sample_data.sql`
3. `database/validation_queries.sql`

The schema contains 26 base tables after the import, including `content_reports`.

## Constraint results

| Rule | Result |
| --- | --- |
| Duplicate user email is rejected | PASS |
| Preference with a missing user is rejected | PASS |
| Recipe rating outside 1-5 is rejected | PASS |
| Recipe ingredient quantity of zero is rejected | PASS |
| Purchased shopping item without a timestamp is rejected | PASS |

## Compatibility fix

Initial import on MySQL 26.7.0 identified a conflict between the report-review `CHECK` rule and the reviewer's `ON DELETE SET NULL` foreign-key action. The incompatible `CHECK` was removed from the master script. The database still enforces exactly one reported target, while the API is responsible for requiring reviewer and review-time fields when a report is resolved or dismissed.

No credentials or real user data are included in this evidence.

## Frontend-alignment runtime validation

- Date: 2026-08-23
- Database: local MySQL Community Server 26.7.0
- Schema: `unimeal_planner`

The following scripts were run successfully against the existing local database:

1. `database/migrations/20260823_frontend_alignment.sql`
2. `database/sample_data.sql`
3. `database/validation_queries.sql`

### Upgrade result

- The database still contains 26 base tables.
- `recipes.image_url` was added.
- `ingredients.estimated_unit_cost` was added with a non-negative `CHECK` constraint.
- `vw_recipe_cards` was created successfully.
- The view returned 8 published recipe cards, including the six records used by the current frontend preview.

### Constraint results

| Rule | Result |
| --- | --- |
| Duplicate user email is rejected | PASS |
| Preference with a missing user is rejected | PASS |
| Recipe rating outside 1-5 is rejected | PASS |
| Recipe ingredient quantity of zero is rejected | PASS |
| Ingredient reference unit cost below zero is rejected | PASS |
| Purchased shopping item without a timestamp is rejected | PASS |

No credentials or real user data are included in this evidence.
