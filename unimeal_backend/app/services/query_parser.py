"""Turn a small set of meal-related English phrases into search constraints."""

from __future__ import annotations

import re
from dataclasses import dataclass, field


DIETARY_KEYWORDS = (
    ("gluten-free", "Gluten-Free"),
    ("gluten free", "Gluten-Free"),
    ("dairy-free", "Dairy-Free"),
    ("dairy free", "Dairy-Free"),
    ("vegetarian", "Vegetarian"),
    ("vegan", "Vegan"),
)


@dataclass
class SmartQuery:
    """Structured constraints extracted from a user's natural-language request."""

    original_query: str
    dietary_tags: list[str] = field(default_factory=list)
    price_max: float | None = None
    max_minutes: int | None = None
    ingredient: str | None = None


def _extract_price(text: str) -> float | None:
    """Read phrases such as 'under $5' or 'below 8 dollars'."""
    matches = re.finditer(
        r"\b(?:under|below|less than)\s+\$?\s*(\d+(?:\.\d+)?)",
        text,
    )

    for match in matches:
        # Do not mistake "under 30 minutes" for a $30 budget.
        following_text = text[match.end():].lstrip()
        if following_text.startswith(("minute", "minutes", "min", "mins")):
            continue
        return float(match.group(1))

    return None


def _extract_minutes(text: str) -> int | None:
    """Read phrases such as 'under 30 minutes'."""
    match = re.search(
        r"\b(?:under|within|less than)\s+(\d+)\s*(?:minute|minutes|min|mins)\b",
        text,
    )
    return int(match.group(1)) if match else None


def _extract_ingredient(text: str) -> str | None:
    """Read one ingredient from phrases such as 'with rice'."""
    match = re.search(
        r"\bwith\s+([a-z][a-z\s-]*?)(?=\s+(?:under|below|less than|within)\b|$)",
        text,
    )
    if not match:
        return None

    ingredient = " ".join(match.group(1).split())
    return ingredient or None


def parse_smart_query(query: str) -> SmartQuery:
    """Parse the supported natural-language meal constraints.

    Version 1 intentionally supports a small, testable vocabulary:
    dietary tags, a maximum price, a maximum cooking time, and one ingredient.
    """

    normalized = " ".join(query.lower().split())
    dietary_tags = []

    for keyword, tag in DIETARY_KEYWORDS:
        if keyword in normalized and tag not in dietary_tags:
            dietary_tags.append(tag)

    max_minutes = _extract_minutes(normalized)

    # "quick dinner" means 30 minutes when a precise time was not supplied.
    if max_minutes is None and "quick" in normalized:
        max_minutes = 30

    return SmartQuery(
        original_query=query.strip(),
        dietary_tags=dietary_tags,
        price_max=_extract_price(normalized),
        max_minutes=max_minutes,
        ingredient=_extract_ingredient(normalized),
    )