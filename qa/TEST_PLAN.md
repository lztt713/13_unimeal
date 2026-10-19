# UniMeal final QA test plan

## Scope and release rule

The final check covers the main student, contributor and administrator workflows.
A release is ready when the backend suite passes against the dedicated test
database, the frontend production build succeeds, the P0 manual workflows have
no unresolved failures, and no credential or personal data is committed.

## Current test coverage

| Area | Main checks | Priority | Evidence |
| --- | --- | --- | --- |
| Account and profile | Registration, email validation, password hashing, roles, suspension and profile preferences | P0 | `unimeal_backend/tests/test_auth.py` |
| Recipe authoring | Contributor ownership, create/update/delete, equipment, ingredients, images and publication state | P0 | `test_recipe_permissions.py`, `test_completed_integrations.py` |
| Recipe discovery | Search constraints, ratings, saved recipes, comments and allergen tags | P1 | `test_recipe_permissions.py`, `test_completed_integrations.py` |
| Meal planning | Add, update and remove entries; date and user isolation rules | P0 | `test_planning.py` |
| Shopping and budget | Ingredient quantities, regeneration, purchase history, receipt amount and dashboard totals | P0 | `test_planning.py` |
| Notifications and administration | Reminder lifecycle, reports, management lists and administrator-only changes | P1 | `test_notifications_and_admin.py`, `test_completed_integrations.py` |
| AI Helper | Explicit-query filtering, validated candidates, optional Gemini reranking and database fallback | P1 | `test_completed_integrations.py`, `ai_qa/healthyCheck.py` |

## Final verification commands

From the repository root:

```powershell
.\test.ps1

cd unimeal_frontend
npm run build
```

`test.ps1` uses a dedicated `unimeal_test` MySQL database. If Gemini is
configured, also run the health check documented in `ai_qa/README.md`. A live
Gemini result is supplementary because the final application supports an
offline database-backed fallback.

## Repository cleanup verification - 19 October 2026

| Check | Result | Note |
| --- | --- | --- |
| `npm run build` | Passed | Vite created the production bundle. |
| `npx oxlint .` | Passed | No frontend lint findings were reported. |
| `npx eslint .` | Passed | No frontend lint findings were reported. |
| Local Markdown links | Passed | Every relative Markdown link resolved after the documentation move. |
| Common committed-secret patterns | Passed | No common API-key or private-key pattern was found in tracked text. |
| Fresh backend suite | Not run in this cleanup environment | This workstation has no working Python/MySQL command or project `.venv`; earlier evidence must not be presented as a fresh rerun. |

## Manual P0 checklist

| ID | Workflow | Expected result | Final status |
| --- | --- | --- | --- |
| AUTH-001 | Register and sign in as a student | The new account can sign in and only student actions are available | Not recorded |
| PLAN-001 | Add, update and remove a meal | The calendar persists each change after refresh | Not recorded |
| SHOP-001 | Generate a list from meals with shared ingredients | Equivalent items merge and quantities reflect planned servings | Not recorded |
| BUDGET-001 | Mark an item purchased with an actual price | Spending and remaining budget update without losing purchase history | Not recorded |
| CONTRIB-001 | Create and edit a contributor-owned recipe | The recipe and its ingredients/equipment persist; another contributor cannot edit it | Not recorded |
| ADMIN-001 | Review users, recipes and reports as an administrator | Management data loads and non-administrators are rejected | Not recorded |

Update `Final status` only from an observed run. Do not convert an unexecuted
case into a pass simply because the automated suite covers related business logic.

## Evidence rules

- Use anonymous local test data and never commit `.env`, API keys or real user data.
- Record the date, environment, command, expected result and actual result.
- Keep a concise failure description and the fixing commit when a P0/P1 case fails.
- Treat the backend as the authority for permissions even when the frontend hides an action.
