# Doubao API integration baseline

## Purpose

This note records the minimum interface agreed for the first AI integration step.
The existing `doubao_healthcheck.py` verifies that the configured Ark chat endpoint
can return a usable response without exposing credentials.

## Configuration

| Setting | Required | Description |
| --- | --- | --- |
| `ARK_API_KEY` | Yes | Secret API credential. Keep it only in the local environment or `.env`. |
| `ARK_MODEL` | Yes | Enabled Ark model or endpoint ID. |
| `ARK_BASE_URL` | No | Defaults to `https://ark.cn-beijing.volces.com/api/v3`. |
| `ARK_TIMEOUT_SECONDS` | No | Defaults to 30 seconds. |

## First service contract

The client sends a JSON request to `POST /chat/completions` with a Bearer token and
expects a non-empty `choices[0].message.content` value. The application must convert
network, HTTP and unusable-response failures into safe user-facing errors; API keys
and raw Authorization headers must never be logged.

## Baseline verification

Run `python ai_qa/doubao_healthcheck.py` from the repository root after setting local
configuration. A successful run confirms connectivity only; it does not validate
meal-plan quality or recipe constraints.
