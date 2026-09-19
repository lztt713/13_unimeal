# AI metrics baseline

## Purpose

This baseline defines the first AI statistics to expose in the admin dashboard and
to use in the final evaluation. Metrics should be calculated from anonymised request
events and test records; do not store prompts containing personal data or credentials.

| Metric | Definition | Initial source | Reporting use |
| --- | --- | --- | --- |
| Total AI requests | Count of submitted meal-plan requests | AI service event | Usage volume |
| Successful requests | Requests returning a validated response | AI service event plus schema check | Reliability |
| Failed requests | Requests ending in timeout, network, HTTP or schema failure | Error category only | Defect prioritisation |
| Success rate | Successful requests divided by total requests | Derived metric | Dashboard KPI |
| Response time | Elapsed milliseconds from send to usable response | AI service event | Performance trend |
| Constraint pass rate | Test cases satisfying allergy, budget and dietary checks divided by executed constraint cases | QA test record | Recommendation quality |

## Initial event fields

Record timestamp, anonymised request ID, outcome category, response time in milliseconds,
schema-validation result and constraint-test result when available. Retain no API key,
raw authorization header or identifiable user profile in this first metrics dataset.

## First reporting rule

Show counts and rates for a selected time period. If there are no requests, display
zero counts and an unavailable success rate rather than dividing by zero.
