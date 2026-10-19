# AI and QA notes

UniMeal's final AI Helper uses Gemini to rerank validated recipe candidates when
a Gemini API key is available. If Gemini is not configured or is temporarily
unavailable, the application returns a deterministic database-backed result so
the main recipe workflow remains usable.

## Relevant implementation

- `unimeal_backend/app/routers/aiHelper.py` exposes the AI Helper endpoint.
- `unimeal_backend/app/services/query_parser.py` extracts explicit constraints.
- `unimeal_backend/app/services/recipe_service.py` reads eligible recipes.
- `unimeal_backend/app/services/aiRecommendation.py` handles Gemini and fallback ranking.
- `unimeal_frontend/src/views/AiHelperView.vue` provides the user interface.
- `ai_qa/docs/AI_METRICS_BASELINE.md` defines the planned evaluation metrics.

The early Doubao connectivity record is retained only as historical evidence in
`ai_qa/docs/archive/AI_CONNECTIVITY_REPORT_Doubao.md`.

## Gemini health check

1. Complete the repository setup described in the root `README.md`.
2. Add `GEMINI_API_KEY` and, if required, `GEMINI_MODEL` to the local `.env`.
3. From the repository root, run:

```powershell
.\.venv\Scripts\python.exe ai_qa\healthyCheck.py
```

The check must never print or commit the API key. Gemini is optional for normal
application use because the database-backed fallback does not require a key.
