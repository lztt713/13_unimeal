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

## Frontend-alignment follow-up

The later frontend-alignment update adds `recipes.image_url`, `ingredients.estimated_unit_cost`, a recipe-card read view, and a sixth validation rule for a negative ingredient reference cost. This Week 4 record remains historical evidence for the original five checks; run the migration and the current validation script again before recording a new runtime result.
