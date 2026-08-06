"""Minimal, dependency-free connectivity check for a Doubao/Ark chat model."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Mapping
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

DEFAULT_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
DEFAULT_TIMEOUT_SECONDS = 30


def load_local_env(path: Path) -> dict[str, str]:
    """Read simple KEY=VALUE pairs without overriding environment variables."""
    values: dict[str, str] = {}
    if not path.exists():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def get_config(environ: Mapping[str, str], local_values: Mapping[str, str]) -> dict[str, str]:
    def value(name: str, default: str = "") -> str:
        return environ.get(name) or local_values.get(name) or default

    config = {
        "api_key": value("ARK_API_KEY"),
        "model": value("ARK_MODEL"),
        "base_url": value("ARK_BASE_URL", DEFAULT_BASE_URL).rstrip("/"),
        "timeout_seconds": value("ARK_TIMEOUT_SECONDS", str(DEFAULT_TIMEOUT_SECONDS)),
    }
    missing = [name for name in ("api_key", "model") if not config[name]]
    if missing:
        raise ValueError("Missing configuration: " + ", ".join(missing))
    return config


def build_payload(model: str) -> dict[str, object]:
    return {
        "model": model,
        "temperature": 0,
        "max_tokens": 40,
        "messages": [
            {"role": "system", "content": "You are a concise API health-check assistant."},
            {"role": "user", "content": "Reply with exactly: UniMeal AI connection OK"},
        ],
    }


def request_completion(config: Mapping[str, str]) -> str:
    endpoint = f"{config['base_url']}/chat/completions"
    request = Request(
        endpoint,
        data=json.dumps(build_payload(config["model"])).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {config['api_key']}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urlopen(request, timeout=float(config["timeout_seconds"])) as response:
        payload = json.loads(response.read().decode("utf-8"))

    try:
        content = payload["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, AttributeError, TypeError) as error:
        raise RuntimeError("The API returned no usable assistant message.") from error
    if not content:
        raise RuntimeError("The API returned an empty assistant message.")
    return content


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    try:
        config = get_config(os.environ, load_local_env(repo_root / ".env"))
        answer = request_completion(config)
    except ValueError as error:
        print(f"Configuration error: {error}", file=sys.stderr)
        return 2
    except HTTPError as error:
        print(f"API error: HTTP {error.code}. Check the key, model, and endpoint.", file=sys.stderr)
        return 3
    except URLError as error:
        print(f"Network error: {error.reason}", file=sys.stderr)
        return 4
    except (RuntimeError, TimeoutError, json.JSONDecodeError) as error:
        print(f"Response error: {error}", file=sys.stderr)
        return 5

    print("Doubao API health check passed.")
    print(f"Model response: {answer}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
