# UniMeal Planner

UniMeal Planner is the group project for 159.333 Programming Project. The repository contains a Vue 3 frontend, a FastAPI backend, and the shared MySQL schema.

## Local setup

1. Create the database with `database/master_schema.sql`, then load `database/sample_data.sql`.
2. Copy `.env.example` to `.env` and set `DATABASE_URL`.
3. From `unimeal_backend`, create a virtual environment, install `requirements.txt`, and run:

   ```powershell
   uvicorn app.main:app --reload
   ```

4. From `unimeal_frontend`, install the locked packages and run:

   ```powershell
   npm ci
   npm run dev
   ```

The Vite development server proxies `/api` to `http://127.0.0.1:8000`.

## Implemented backend flow

- Recipe search, detail, create, edit, delete, publication, saved recipes, and ratings
- Weekly meal-plan entry create/update/delete
- Shopping-list generation with ingredient/unit merging and serving scaling
- Persisted purchased state and purchase timestamps
- Budget summary calculated from purchased shopping-list items
- Dashboard budget, today's dinner, and saved-recipe integration

Authentication, administrator management, and the Doubao AI integration remain separate team modules. Until authentication is connected, backend development users are selected with `UNIMEAL_STUDENT_EMAIL` and `UNIMEAL_CONTRIBUTOR_EMAIL`.

## Checks

```powershell
cd unimeal_backend
python -m unittest discover -s tests -v

cd ..\unimeal_frontend
npm run build
```
