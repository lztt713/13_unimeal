# Database handoff and validation guide

## Source of truth

`database/master_schema.sql` is the only schema-definition script for UniMeal Planner. Qichen Hu, Database Architect, is its maintainer. Submit proposed schema changes as a short SQL snippet plus the affected API/UI requirement; do not modify this file independently.

## Local setup

1. Install MySQL 8.0.16 or later.
2. Run `mysql -u <user> -p < database/master_schema.sql` from the repository root.
3. Run `mysql -u <user> -p unimeal_planner < database/sample_data.sql` to load development data.
4. Run `mysql -u <user> -p unimeal_planner < database/validation_queries.sql`.
5. Verify that all returned validation rows have `PASS` status.

The script is safe to re-run for structure creation and reference roles/units. It does not drop existing project data.

`sample_data.sql` is for local development and testing only. It uses `@unimeal.test` accounts and placeholder bcrypt-formatted hashes; never use these accounts or hashes in production.

`validation_queries.sql` deliberately attempts invalid operations inside SQL exception handlers. It returns one row for each database rule; every result must be `PASS` before backend integration.

## Validation ownership

| Rule | Enforced in database | Enforced in API/UI |
| --- | --- | --- |
| Email format, uniqueness, and active account | `CHECK`, unique key | Normalise email; show useful message |
| Password security | No plaintext field; minimum hash length | Hash with Argon2/bcrypt; never log password |
| Recipe quality | servings, cost, ingredient quantity, ordered steps | Required fields and friendly validation |
| Meal calendar | unique plan/week and meal/date/slot | Ensure dates belong to selected week |
| Shopping and budget | non-negative costs; purchase timestamp consistency | Aggregate equivalent ingredient/unit rows |
| Ratings, reports, relationships | foreign keys, range checks, composite keys | Enforce permissions by user role |

## This week's database work

| Day | Deliverable | Evidence to commit |
| --- | --- | --- |
| Day 1 | Confirm user stories and API fields with the team | Updated ERD decisions or issue comment |
| Day 2 | Review and approve the logical schema | `docs/database/ERD.md` |
| Day 3 | Implement schema and seed reference values | `database/master_schema.sql` |
| Day 4 | Add sample data and MySQL verification queries | `database/sample_data.sql`, `database/validation_queries.sql` |
| Day 5 | Pair with backend on CRUD payloads and migrations | API-to-table mapping plus test evidence |
| Day 6 | Test shopping aggregation, constraints, and deletes | Test results/screenshots or SQL output |
| Day 7 | Update final ERD and weekly contribution summary | Documentation and pull request summary |

## Next integration boundary

The current repository contains the initial Vue scaffold and no backend/database module. Before FastAPI integration, agree on: authentication payload fields, recipe JSON shape, normalised measurement units, and which endpoint owns shopping-list aggregation. The backend should use a dedicated MySQL application account with the minimum required privileges.
