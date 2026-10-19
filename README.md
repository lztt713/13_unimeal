# UniMeal Planner

UniMeal Planner is the group project for 159.333 Programming Project. It is a
local full-stack application that helps students discover recipes, plan meals,
create shopping lists and track a weekly food budget.

Software repository: https://github.com/lztt713/13_unimeal

## Project status

The planned coursework workflows are implemented and integrated. The repository
is being prepared as the final coursework version. UniMeal is verified as a
local application; production hosting is outside the assessed scope.

## Interface preview

| Contributor recipe management | Administrator overview |
| --- | --- |
| ![Contributor recipe management](assets/screenshots/contributor-recipes.png) | ![Administrator overview](assets/screenshots/admin-dashboard.png) |

### Completed work

- Student registration, sign-in, profile and dietary preferences
- Published recipe search, filters, details, ratings, comments and saved recipes
- Contributor recipe creation, editing, equipment and ingredient management
- Weekly meal calendar with serving quantities
- Generated shopping lists, purchase state and actual purchase prices
- Weekly budget summary and student dashboard
- Request-driven reminders and recipe-update notifications
- Administrator overview, user/recipe management and report review
- Smart Recipe Search and Meal Recommendation with an optional Gemini reranker
- Database-backed AI fallback when Gemini is not configured or unavailable
- MySQL schema, migrations, sample data and validation queries
- Backend tests for the main permissions and cross-module workflows

## Main workflows

- **Students** browse recipes, save favourites, plan a week of meals, generate a
  shopping list, record purchases and review budget information.
- **Contributors** create, update, publish and archive their own recipes.
- **Administrators** review overview counts, users, recipes, reports and ingredient
  categories. Backend role checks remain authoritative when the UI hides an action.
- **AI Helper** reads explicit dietary, price, time and ingredient constraints.
  Gemini may rerank valid candidates; otherwise the database fallback is used.

## Technology stack

| Layer | Technology |
| --- | --- |
| Frontend | Vue 3, Vue Router, Axios, Bootstrap, Chart.js and Vite |
| Backend | Python, FastAPI, Pydantic and SQLAlchemy |
| Database | MySQL |
| Optional AI | Google Gemini with a deterministic database fallback |
| Testing | Python `unittest`, backend integration tests and frontend production build |

## Team responsibilities

The table shows each member's primary area. Integration and final testing were
shared across the team.

| Team member | Primary responsibility | Main repository area |
| --- | --- | --- |
| Michael Zhao | Vue frontend, routes, role flows, responsive UI and frontend integration | `unimeal_frontend/` |
| Qichen Hu | MySQL schema, ERDs, migrations, validation queries and database evidence | `database/` |
| Zhanhe Zhang | FastAPI foundation, authentication, permissions, recipes, administration, notifications and backend tests | `unimeal_backend/app/`, `unimeal_backend/tests/` |
| Zihao Liang | Project coordination; meal planning, shopping, purchases, budgets, dashboard, reminders and integration tests | Planning routes, services and tests |
| Jiyuan Li | AI/QA work, Gemini integration, query parsing and fallback design | `ai_qa/`, AI services and `qa/` |

Commit history and merged pull requests retain the detailed contribution record.

## Key decisions

| Decision | Reason |
| --- | --- |
| Use Vue 3 rather than plain JavaScript views | Declarative components and reactive state avoid repeated manual DOM updates across the student, contributor and administrator workflows. |
| Use FastAPI with Pydantic | Modular routers, reusable dependencies, validated request contracts and automatic OpenAPI documentation made the API easier to integrate. |
| Use MySQL rather than keeping the early SQLite prototype | The shared schema needed MySQL-specific foreign keys, constraints, defaults, timestamps and migrations. |
| Keep permissions in the backend | Hiding a button is only a UI decision; every protected operation must still check the current user's role and ownership. |
| Preserve purchased shopping records | Rebuilding a list must not erase actual prices or spending history already used by the budget and dashboard. |
| Make Gemini optional | The main application should remain usable when no API key is present or an external model is unavailable. |
| Define the final scope as a local coursework application | The evidence covers local setup and testing, while production hosting, hardening, monitoring and recovery were not implemented or verified. |

## Scope changes

- Early AI connectivity work used Doubao/Ark. The final implementation uses
  Gemini and keeps a database-backed fallback. The old connectivity record is
  retained only in `ai_qa/docs/archive/` as historical evidence.
- Equipment and allergy data began as a database update and were later completed
  across SQLAlchemy models, FastAPI schemas/endpoints and Vue forms.
- Notifications are generated from application requests and state changes rather
  than a continuously running background scheduler.

## Repository structure

```text
13_unimeal/
├── ai_qa/                 # AI notes, health check, metrics and archive
├── database/              # Schema, sample data, migrations and database docs
├── qa/                    # Final test plan and manual verification checklist
├── unimeal_backend/       # FastAPI application and backend tests
├── unimeal_frontend/      # Vue application and static recipe images
├── setup.ps1              # First-time local setup
├── run.ps1                # Normal local startup
└── test.ps1               # Backend test runner
```

## First-time setup

Follow these steps when downloading UniMeal for the first time.

### 1. Clone the repository

Install Git if it is not already available, then open PowerShell and run:

```powershell
git clone https://github.com/lztt713/13_unimeal.git
cd 13_unimeal
```

Run the remaining commands from this repository root unless another directory
is shown.

### 2. Check the prerequisites

- Git
- MySQL 8.0.16 or later, with the MySQL service running
- The `mysql` command-line client on `PATH`
- Python 3
- Node.js `^22.18.0` or `>=24.12.0`, with npm

If MySQL or Python is installed outside `PATH`, set `UNIMEAL_MYSQL_EXE` or
`UNIMEAL_PYTHON_EXE` to the corresponding executable before running setup.

### 3. Run the setup script

Run this once for a fresh checkout:

```powershell
.\setup.ps1
```

The script asks for the local MySQL root password, applies the schema, sample
data and migrations, creates the root `.venv`, installs backend dependencies and
runs `npm ci` for the frontend. The password is used only by that process and is
not written to the repository.

Do not run `setup.ps1` only to restart an existing installation because it
reapplies the database setup.

### 4. Start the application

```powershell
.\run.ps1
```

If `.env` does not contain `DATABASE_URL`, the script asks for the MySQL root
password for that run. Keep the two service windows open, then visit:

- Frontend: http://127.0.0.1:5173
- Backend: http://127.0.0.1:8000
- Health check: http://127.0.0.1:8000/api/health
- OpenAPI documentation: http://127.0.0.1:8000/docs

## Start an existing installation

For later starts, open PowerShell in the repository root and run:

```powershell
.\run.ps1
```

You do not need to run `setup.ps1` again if the checkout already has a working
`.venv`, frontend dependencies and database.

The services can also be started manually in separate PowerShell terminals:

```powershell
# From the repository root
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000 --app-dir unimeal_backend

# In a second terminal
cd unimeal_frontend
npm run dev
```

## If PowerShell blocks scripts

Only if PowerShell reports that script execution is disabled, run the following
command in the same PowerShell window, then retry `run.ps1` or `setup.ps1`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

This setting lasts only for that PowerShell session and its child processes. It
does not change the user-wide or machine-wide policy.

## Configuration

Configuration and secrets belong in a local `.env` file, which is ignored by
Git. The supplied `.env.example` contains optional Gemini settings only and no
database password.

```dotenv
DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@127.0.0.1:3306/unimeal_planner?charset=utf8mb4
TEST_DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@127.0.0.1:3306/unimeal_test?charset=utf8mb4
SESSION_SECRET=replace-with-a-long-random-value
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.5-flash-lite
GEMINI_TIMEOUT_SECONDS=30
```

Gemini is optional. Never commit `.env`, passwords or API keys.

## Test and build

The backend suite uses a dedicated `unimeal_test` MySQL database. The test setup
rebuilds its tables between tests and does not modify `unimeal_planner`.

```powershell
# From the repository root
.\test.ps1

# Frontend production build
cd unimeal_frontend
npm run build
```

If `.env` does not contain `TEST_DATABASE_URL`, `test.ps1` asks for the MySQL root
password and constructs the test connection for that run. The complete QA matrix
and manual checklist are in [`qa/TEST_PLAN.md`](qa/TEST_PLAN.md).

## Sample data and database documents

`database/sample_data.sql` supplies local demonstration data. Its sample account
passwords are placeholder hashes, not documented plaintext passwords. Register a
new student or contributor when a working login is needed.

For an existing database, back up populated data and apply migrations in filename
order. See the [`database/README.md`](database/README.md), logical
[`ERD`](database/docs/ERD.md) and
[`validation evidence`](database/docs/validation_evidence.md).

## Known limitations

- The final evidence covers local use rather than production deployment.
- Notifications are refreshed by application requests, not background jobs.
- Recipe costs are estimates until a user records an actual purchase price.
- Gemini output depends on an external service, so the database fallback remains
  the reliable default when the service or key is unavailable.
- Formal accessibility, cross-browser, performance and concurrency testing are
  outside the current evidence.
