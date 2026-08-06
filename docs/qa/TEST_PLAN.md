# UniMeal QA test plan (Day 1 baseline)

## Scope and exit rule

Each completed module must have passing happy-path, validation, permission/security,
and failure-handling checks. A feature is ready for integration only when all P0/P1
cases pass and no sensitive data appears in browser, API, console, or repository logs.

## Functional test matrix

| Area | Core checks | Priority | Current dependency |
| --- | --- | --- | --- |
| Account & authentication | Register, sign in/out, invalid credentials, session expiry, password not exposed | P0 | Backend API |
| Recipe search & detail | Keyword/filter search, no-result state, detail accuracy, unavailable image/recipe | P0 | Backend API + frontend |
| Ratings & favourites | Create/update rating, add/remove favourite, duplicate prevention, access control | P1 | Backend API + frontend |
| Meal planner | Add/edit/remove meal, calendar date boundaries, personalised plan constraints | P0 | Planner API + frontend |
| Shopping list & budget | Ingredient merge/deduplication, quantity units, cost total, empty state | P0 | Backend calculation API |
| Admin dashboard | KPI totals, date filters, chart empty/error states, admin-only access | P1 | Analytics API |
| AI meal planning | API unavailable/timeout, schema validity, allergy exclusion, budget/time constraints, unsafe request response | P0 | Doubao integration + recipe data |

## Test case record format

| ID | Preconditions | Steps | Expected result | Actual result | Status |
| --- | --- | --- | --- | --- | --- |
| AI-001 | Valid local API configuration | Run health-check script | A non-empty model response is received; key is not printed | Not run | Blocked |
| AI-002 | Recipe allergen data available | Request a plan with a peanut allergy | No listed meal contains peanut; unsafe/missing data is surfaced | Not run | Blocked |
| PLAN-001 | Signed-in user and planner API | Add a recipe to a future date | Calendar displays the saved meal after refresh | Not run | Blocked |
| SHOP-001 | Meal plan contains overlapping ingredients | Generate a shopping list | Same ingredient is merged using agreed unit rules | Not run | Blocked |

## Evidence rules

- Keep test data anonymous and minimal; never commit production exports or credentials.
- Record API version, browser/device, test date, test ID, expected vs actual result,
  and a reproducible request/response summary with sensitive values removed.
- Report P0 failures to the Project Manager before requesting a merge.
