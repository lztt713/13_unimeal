# UniMeal Planner

UniMeal Planner is the group project for 159.333 Programming Project. It is a
local full-stack coursework application with a Vue 3 frontend, a FastAPI backend,
and a shared MySQL database.

Software repository: https://github.com/lztt713/13_unimeal

## First-time setup

Follow these steps when downloading UniMeal for the first time.

### 1. Clone the repository

Install Git if it is not already available, then open PowerShell and run:

```powershell
git clone https://github.com/lztt713/13_unimeal.git
cd 13_unimeal
```

All commands below should be run from this repository root unless another
directory is shown.

### 2. Check the prerequisites

- Git
- MySQL 8.0.16 or later, with the MySQL service running
- The `mysql` command-line client on `PATH`
- Python 3
- Node.js `^22.18.0` or `>=24.12.0`, with npm

If MySQL or Python is installed outside `PATH`, set `UNIMEAL_MYSQL_EXE` or
`UNIMEAL_PYTHON_EXE` to the corresponding executable before running setup.

### 3. Run the setup script

Run this command once for a fresh checkout:

```powershell
.\setup.ps1
```

The script asks for the local MySQL root password, applies the database schema,
sample data, and migrations, creates the root `.venv`, installs the backend
dependencies, and runs `npm ci` for the frontend. The password is used only by
that process and is not written to the repository.

Do not run `setup.ps1` only to restart an existing installation because it
reapplies the database setup.

### 4. Start the application

After setup finishes, run:

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

You do **not** need to run `setup.ps1` again if the checkout already has a
working `.venv`, frontend dependencies, and database. A missing system Python
on `PATH` does not stop `run.ps1` from using the existing `.venv`.

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
command in the **same PowerShell window**, then retry `run.ps1` or `setup.ps1`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

This setting lasts only for that PowerShell session and its child processes.
Repeat it in a new window if scripts are blocked again; it does not change the
user-wide or machine-wide policy. See [Microsoft's execution-policy guide](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

## Configuration

Configuration and secrets belong in a local `.env` file, which is ignored by
Git. The supplied `.env.example` contains optional Gemini settings only and does
not contain a database connection.

The following values are supported:

```dotenv
DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@127.0.0.1:3306/unimeal_planner?charset=utf8mb4
TEST_DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@127.0.0.1:3306/unimeal_test?charset=utf8mb4
SESSION_SECRET=replace-with-a-long-random-value
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.5-flash-lite
GEMINI_TIMEOUT_SECONDS=30
```

Gemini is optional. Without a key, the AI Helper uses its deterministic
database-backed fallback. Never commit `.env` or any credentials.

## Test and build

The complete backend suite uses a dedicated `unimeal_test` MySQL database. The
test setup creates that database when needed and rebuilds its tables between
tests; it does not modify `unimeal_planner`.

```powershell
# From the repository root
.\test.ps1

# Frontend production build
cd unimeal_frontend
npm run build
```

If `.env` does not contain `TEST_DATABASE_URL`, `test.ps1` asks for the MySQL
root password and constructs the test connection for that run.

## Main workflows

- Students register, complete their profile, browse and save published recipes,
  plan weekly meals with serving quantities, generate shopping lists, record
  purchases, review budgets and dashboard data, and receive reminders.
- Contributors create, revise, publish, and remove their own recipes.
- Administrators review overview counts, reports, users, recipes, and ingredient
  categories. Backend role checks remain authoritative even when the frontend
  hides an action.
- Smart Recipe Search parses dietary tags, a maximum price, a maximum cooking
  time, and an ingredient phrase from the explicit query.
- Meal Recommendation ranks matching published recipes using saved recipe and
  cuisine signals, ratings, estimated cost, and cooking time. Gemini may rerank
  validated candidates when configured; otherwise the database fallback is used.

## Sample data and accounts

`database/sample_data.sql` supplies local demonstration data. Its sample account
passwords are placeholder hashes, not a documented plaintext password. Register
a new student or contributor through the application or `POST /api/auth/register`
when a working login is needed.

For an existing database, review and apply the migration files in
`database/migrations` in filename order. Back up populated databases before
applying schema changes.

## Current scope

UniMeal has been verified as a local coursework application, not a production
deployment. Notifications are request-driven, costs are estimates, Gemini is
optional, and formal accessibility, cross-browser, performance, concurrency,
backup, and recovery testing remain outside the current evidence.
