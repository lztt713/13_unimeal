# AI & QA workspace

This folder is owned by the AI & QA Specialist. It contains local AI validation tools,
prompt specifications, and test documentation; it must not contain API keys, personal
data, or production database credentials.

## Day 1: verify the Doubao connection

1. Copy the repository-root `.env.example` to `.env`.
2. Set `ARK_API_KEY` and an enabled `ARK_MODEL` in your local `.env` file.
3. Run `python ai_qa/doubao_healthcheck.py` from the repository root.

The script sends only a fixed, non-personal prompt and reports whether a usable text
response was returned. It does not log the API key. A successful response is only a
connectivity check, not evidence that meal-plan quality is acceptable.

Run its offline checks with:

```text
python -m unittest discover -s ai_qa/tests -v
```

## Contents

- `doubao_healthcheck.py` – minimal, dependency-free API connectivity check.
- `prompt_templates/meal_plan_v1.md` – initial meal-plan prompt contract.
- `tests/` – offline unit tests for request/configuration behaviour.
