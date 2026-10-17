"""Authentication and profile endpoints backed by signed HttpOnly sessions.

Zhang Zhanhe (ZZH): Registration, login, logout, current-user and profile
features use signed HttpOnly cookie sessions and PBKDF2 password hashes.
"""

from __future__ import annotations

from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth import (
    clear_session,
    get_current_user,
    hash_password,
    set_session,
    verify_password,
)
from app.database import get_db
from app.models import Allergy, BudgetPeriod, DietaryTag, Role, User
from app.schemas import LoginRequest, ProfileUpdate, RegisterRequest, UserResponse

router = APIRouter(prefix="/api", tags=["auth"])

# The database stores enum values while the frontend uses display labels,
# so these two dicts map back and forth.
COOKING_SKILL_DISPLAY = {
    "beginner": "Beginner",
    "intermediate": "Comfortable",
    "advanced": "Confident",
}
COOKING_SKILL_DB = {value: key for key, value in COOKING_SKILL_DISPLAY.items()}

# Kitchen access has the same database-enum ↔ frontend-label mismatch.
KITCHEN_ACCESS_DISPLAY = {
    "none": "No kitchen",
    "limited": "Limited equipment",
    "shared": "Shared kitchen",
    "full": "Private kitchen",
}
KITCHEN_ACCESS_DB = {value: key for key, value in KITCHEN_ACCESS_DISPLAY.items()}


def _split_cuisines(note: str | None) -> list[str]:
    return [value.strip() for value in (note or "").split(",") if value.strip()]


def _get_or_create_tag(db: Session, name: str) -> DietaryTag | None:
    name = name.strip()
    if not name:
        return None
    tag = db.query(DietaryTag).filter(func.lower(DietaryTag.tag_name) == name.lower()).first()
    if tag is None:
        tag = DietaryTag(tag_name=name)
        db.add(tag)
        db.flush()
    return tag


def _resolve_allergies(db: Session, names: list[str]) -> list[Allergy]:
    """Resolve profile allergies against the controlled database catalogue.

    Allergy options are reference data returned by ``GET /api/allergies``.
    Profile updates may select those rows, but must never create new allergy
    records from arbitrary client text.
    """
    requested: list[tuple[str, str]] = []
    seen: set[str] = set()
    for value in names:
        display_value = value.strip()
        lookup = display_value.casefold()
        if lookup not in seen:
            requested.append((display_value, lookup))
            seen.add(lookup)

    if not requested:
        return []

    rows = (
        db.query(Allergy)
        .filter(func.lower(Allergy.allergy_name).in_([lookup for _, lookup in requested]))
        .all()
    )
    by_name = {row.allergy_name.casefold(): row for row in rows}
    unknown = [display or "<blank>" for display, lookup in requested if lookup not in by_name]
    if unknown:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unknown allergies: {', '.join(unknown)}. "
                "Choose values returned by GET /api/allergies."
            ),
        )
    return [by_name[lookup] for _, lookup in requested]


def user_to_response(user: User) -> dict:
    """Serialize a user (and its preference relationships) for the frontend.

    The frontend expects camelCase fields. This function returns a snake_case
    dictionary and the response model aliases convert it to camelCase.
    """
    return {
        "id": int(user.user_id),
        "display_name": user.display_name,
        "email": user.email,
        "role": user.role.role_name,
        "weekly_budget": float(user.weekly_budget or 0),
        "cooking_skill": COOKING_SKILL_DISPLAY.get(user.cooking_skill, "Beginner"),
        "kitchen_access": KITCHEN_ACCESS_DISPLAY.get(user.kitchen_access, "Shared kitchen"),
        "dietary_preferences": [tag.tag_name for tag in user.dietary_preferences],
        "allergies": [allergy.allergy_name for allergy in user.allergies],
        "favourite_cuisines": _split_cuisines(user.favourite_cuisines_note),
    }


def register_user(db: Session, name: str, email: str, password: str, role: str) -> User:
    """Create a new student or contributor account. Never allows administrator.

    Self-registration is limited to student and contributor roles. Email
    addresses are unique and passwords are stored as PBKDF2 hashes.
    """
    email = email.strip().lower()
    role = (role or "student").strip().lower()
    if role not in ("student", "contributor"):
        raise HTTPException(400, "You can only register a student or contributor account")
    if "@" not in email or "." not in email.split("@")[-1]:
        raise HTTPException(400, "Please enter a valid email address")
    if db.query(User).filter(User.email == email).first() is not None:
        raise HTTPException(409, "An account with this email already exists")

    role_row = db.query(Role).filter(Role.role_name == role).first()
    if role_row is None:
        raise HTTPException(400, "Unknown account role")

    now = datetime.now()
    user = User(
        role_id=role_row.role_id,
        email=email,
        password_hash=hash_password(password),
        display_name=name.strip() or email.split("@")[0],
        cooking_skill="beginner",
        kitchen_access="shared",
        weekly_budget=0,
        is_active=True,
        created_at=now,
        updated_at=now,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        # Fall back to the database unique constraint under concurrent registration.
        db.rollback()
        raise HTTPException(409, "An account with this email already exists") from None
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> User:
    """Return the user when email and password match, otherwise raise 401/403.

    Email addresses are normalized to lowercase. Password verification accepts
    PBKDF2 and bcrypt hashes, and suspended accounts receive 403.
    """
    email = email.strip().lower()
    user = db.query(User).filter(User.email == email).first()
    if user is None or not verify_password(password, user.password_hash):
        raise HTTPException(401, "Incorrect email or password")
    if not user.is_active:
        raise HTTPException(403, "This account has been suspended")
    return user


def apply_profile_update(db: Session, user: User, payload: ProfileUpdate) -> dict:
    """Persist a partial profile update and return the refreshed user.

    Only supplied fields are updated. Preference lists are replaced as a whole,
    and display labels are mapped back to database enum values before saving.
    """
    resolved_allergies = (
        _resolve_allergies(db, payload.allergies) if payload.allergies is not None else None
    )

    if payload.display_name is not None:
        user.display_name = payload.display_name.strip() or user.display_name
    if payload.weekly_budget is not None:
        user.weekly_budget = payload.weekly_budget
        today = date.today()
        (
            db.query(BudgetPeriod)
            .filter(
                BudgetPeriod.user_id == user.user_id,
                BudgetPeriod.period_start <= today,
                BudgetPeriod.period_end >= today,
            )
            .update({BudgetPeriod.budget_amount: payload.weekly_budget}, synchronize_session=False)
        )
    if payload.cooking_skill is not None:
        user.cooking_skill = COOKING_SKILL_DB.get(payload.cooking_skill, user.cooking_skill)
    if payload.kitchen_access is not None:
        user.kitchen_access = KITCHEN_ACCESS_DB.get(payload.kitchen_access, user.kitchen_access)
    if payload.dietary_preferences is not None:
        user.dietary_preferences = [
            tag for tag in (_get_or_create_tag(db, name) for name in payload.dietary_preferences) if tag
        ]
    if resolved_allergies is not None:
        user.allergies = resolved_allergies
    if payload.favourite_cuisines is not None:
        user.favourite_cuisines_note = ", ".join(
            value.strip() for value in payload.favourite_cuisines if value.strip()
        )
    user.updated_at = datetime.now()
    db.commit()
    db.refresh(user)
    return user_to_response(user)


# Registration also signs the caller in so the frontend can redirect straight away.
@router.post("/auth/register", response_model=UserResponse, status_code=201)
def register(payload: RegisterRequest, response: Response, db: Session = Depends(get_db)):
    """Register a new account and sign the caller in."""
    user = register_user(db, payload.name, payload.email, payload.password, payload.role)
    set_session(response, user)
    return user_to_response(user)


# A successful login sets an HttpOnly session cookie carried on later requests.
@router.post("/auth/login", response_model=UserResponse)
def login(payload: LoginRequest, response: Response, db: Session = Depends(get_db)):
    """Verify credentials and set an HttpOnly session cookie."""
    user = authenticate_user(db, payload.email, payload.password)
    set_session(response, user)
    return user_to_response(user)


# Logout revokes the token server-side and clears the cookie client-side.
@router.post("/auth/logout")
def logout(request: Request, response: Response):
    """Revoke the session cookie and clear it from the client."""
    clear_session(request, response)
    return {"message": "Signed out"}


# When not signed in this returns 401, which the frontend treats as "logged out".
@router.get("/auth/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    """Return the currently authenticated user."""
    return user_to_response(user)


# Profile edits are scoped to the authenticated user only.
@router.put("/profile", response_model=UserResponse)
def update_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Update the current user's profile and preferences."""
    return apply_profile_update(db, user, payload)
