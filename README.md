# UniMeal Planner

A student meal-planning prototype built with **Vue 3, FastAPI, and MySQL**. The frontend connects to the backend and an existing database with 26 tables.

## Features

- Registration, login, and student, contributor, and administrator roles.
- Recipe browsing, publishing, favourites, ratings, and comments.
- Weekly meal planning, shopping lists, and budget tracking.
- Profile preferences, allergies, notifications, and administration.
- Local rule-based recipe suggestions (no external AI service required).

## Requirements

- Python 3.12+
- Node.js 22.18+ (22.x) or 24.12+
- MySQL 8.0.16+

## Quick Start (Windows)

1. Start MySQL. For a new database, follow the [database setup guide](docs/database/README.md). Keep your existing database if it is already configured.
2. Copy `.env.example` to `.env` and set `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME`. Use your actual database name; the current local installation uses `unimeal_planner`.
3. Double-click `Start-UniMeal.cmd`.
4. Open [UniMeal](http://127.0.0.1:8000) or the [API documentation](http://127.0.0.1:8000/docs).

The launcher installs dependencies, checks the database, builds the frontend, and starts the server. It does not create tables or import data. Keep `.env` private; the launcher generates a session secret automatically.

Register a new student or contributor account in the app. Sample account password hashes are placeholders. To create an administrator after setup:

```powershell
.\.venv\Scripts\python.exe unimeal_backend/create_local_account.py --email admin@unimeal.test --name "Administrator" --role administrator
```

For missing recipe images, ingredients, and steps, see the [recipe data completion notes](docs/database/RECIPE_DATA_COMPLETION.md).

## Development

After completing setup, stop the launcher and run these commands in separate terminals:

```powershell
# Backend: from the project root
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir unimeal_backend --reload --port 8000

# Frontend: from the project root in another terminal
cd unimeal_frontend
npm run dev
```

Open [the development frontend](http://127.0.0.1:5173). API requests are proxied to port 8000.

## Project Structure

- `unimeal_frontend/` — Vue application.
- `unimeal_backend/` — FastAPI application and tests.
- `database/` — Schema, sample data, and migrations.
- `docs/` — Database documentation and [integration verification](docs/qa/LOCAL_INTEGRATION_REPORT.md).

This is a local prototype for continued development. Budget estimates use stored ingredient prices; recipe suggestions use local rules.
