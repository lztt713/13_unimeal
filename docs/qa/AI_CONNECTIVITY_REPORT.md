# Doubao API connectivity verification record

## Purpose

Record the local verification of UniMeal's Doubao/Ark model connection. Do not include
API keys, full user prompts, personal data, or raw production responses in this file.

## Preconditions

1. Copy the repository-root `.env.example` to a local `.env` file.
2. Set `ARK_API_KEY` and `ARK_MODEL` using an enabled Ark model or endpoint ID.
3. Confirm `.env` remains ignored by Git with `git status`.

## Execution command

```text
python ai_qa/doubao_healthcheck.py
```

## Result record

| Field | Value |
| --- | --- |
| Test ID | AI-001 |
| Date/time | 9 August 2026 (NZST) |
| Tester | AI & QA Specialist |
| Model/endpoint ID | `doubao-seed-2-1-turbo-260628` |
| Endpoint host | `ark.cn-beijing.volces.com` unless configured otherwise |
| Timeout configuration | 30 seconds by default; configurable through `ARK_TIMEOUT_SECONDS` |
| Expected result | HTTP success and a non-empty assistant response; no API key printed |
| Actual result | HTTP success with a non-empty expected response: `UniMeal AI connection OK`. The API key was not printed. |
| Result | Passed |

## Error-handling checks

| Scenario | Expected behaviour | Status |
| --- | --- | --- |
| API key or model missing | Exit code 2; identify missing configuration without printing secrets | Passed (offline) |
| Invalid key/model | Exit code 3; show HTTP status and corrective hint | Passed: unavailable-model errors were reported without exposing the API key |
| Network interruption | Exit code 4; show network error | Pending live verification |
| Timeout or unusable response | Exit code 5; show response error without exposing secrets | Pending live verification |

## Completion criteria

AI-001 passed after the response was non-empty and the console output contained no
credential value. Repeat this check whenever the model, endpoint, or API-key scope changes.
