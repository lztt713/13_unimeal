"""Account endpoints used by the existing login and profile pages."""
from datetime import date, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.auth import clear_session, get_current_user, hash_password, set_session, verify_password
from app.database import get_db
from app.models import Allergy, BudgetPeriod, DietaryTag, Role, User

router = APIRouter(prefix='/api', tags=['accounts'])
SKILLS = {'Beginner': 'beginner', 'Comfortable': 'intermediate', 'Confident': 'advanced'}
KITCHENS = {'Shared kitchen': 'shared', 'Private kitchen': 'full', 'Limited equipment': 'limited', 'No kitchen': 'none'}


class Login(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=128)

    @field_validator('email')
    @classmethod
    def email_address(cls, value):
        value = value.strip().lower()
        if '@' not in value or '.' not in value.split('@')[-1] or ' ' in value:
            raise ValueError('Enter a valid email address')
        return value


class Registration(Login):
    name: str = Field(min_length=1, max_length=80)
    password: str = Field(min_length=8, max_length=128)
    role: Literal['student', 'contributor'] = 'student'

    @field_validator('name')
    @classmethod
    def nonempty_name(cls, value):
        if not value.strip():
            raise ValueError('Display name is required')
        return value.strip()


class ProfileWrite(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    displayName: str = Field(min_length=1, max_length=80)
    weeklyBudget: float = Field(ge=0, le=99999999)
    cookingSkill: Literal['Beginner', 'Comfortable', 'Confident']
    kitchenAccess: Literal['Shared kitchen', 'Private kitchen', 'Limited equipment', 'No kitchen']
    dietaryPreferences: list[str] = Field(default_factory=list, max_length=30)
    allergies: list[str] = Field(default_factory=list, max_length=30)
    favouriteCuisines: list[str] = Field(default_factory=list, max_length=30)


def current_budget(db, user_id):
    today = date.today()
    return db.query(BudgetPeriod).filter(BudgetPeriod.user_id == user_id,
        BudgetPeriod.period_start <= today, BudgetPeriod.period_end >= today).order_by(BudgetPeriod.period_start.desc()).first()


def user_response(user, db):
    budget = current_budget(db, user.user_id)
    return {'id': user.user_id, 'displayName': user.display_name, 'email': user.email,
            'role': user.role.role_name, 'weeklyBudget': float(budget.budget_amount) if budget else 0,
            'cookingSkill': next((k for k,v in SKILLS.items() if v == user.cooking_skill), 'Beginner'),
            'kitchenAccess': next((k for k,v in KITCHENS.items() if v == user.kitchen_access), 'Shared kitchen'),
            'dietaryPreferences': [x.tag_name.replace('-', ' ') for x in user.dietary_preferences],
            'allergies': [x.allergy_name for x in user.allergies],
            'favouriteCuisines': [x.strip() for x in (user.favourite_cuisines_note or '').split(',') if x.strip()]}


@router.post('/auth/register', status_code=201)
def register(payload: Registration, response: Response, db: Session = Depends(get_db)):
    if db.query(User).filter(func.lower(User.email) == payload.email).first():
        raise HTTPException(409, 'An account with this email already exists')
    role = db.query(Role).filter(Role.role_name == payload.role).first()
    if not role:
        raise HTTPException(503, 'The database is missing the required account roles')
    user = User(role_id=role.role_id, display_name=payload.name, email=payload.email,
                password_hash=hash_password(payload.password))
    db.add(user)
    db.flush()
    start = date.today() - timedelta(days=date.today().weekday())
    db.add(BudgetPeriod(user_id=user.user_id, period_start=start,
                       period_end=start+timedelta(days=6), budget_amount=45))
    db.commit()
    set_session(response, user)
    return user_response(user, db)


@router.post('/auth/login')
def login(payload: Login, response: Response, db: Session = Depends(get_db)):
    user = db.query(User).filter(func.lower(User.email) == payload.email).first()
    if not user or not user.is_active or not verify_password(payload.password, user.password_hash):
        raise HTTPException(401, 'Invalid email or password')
    set_session(response, user)
    return user_response(user, db)


@router.post('/auth/logout')
def logout(request: Request, response: Response):
    clear_session(request, response)
    return {'ok': True}


@router.get('/auth/me')
def me(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return user_response(user, db)


def lookup_values(db, model, column, values, max_length):
    rows = []
    for name in dict.fromkeys(v.strip() for v in values if v.strip()):
        if len(name) > max_length:
            raise HTTPException(422, 'Preference name is too long')
        row = db.query(model).filter(func.lower(func.replace(column, '-', ' ')) == name.lower().replace('-', ' ')).first()
        if row is None:
            row = model(**{column.key: name})
            db.add(row)
            db.flush()
        if row not in rows:
            rows.append(row)
    return rows


@router.put('/profile')
def update_profile(payload: ProfileWrite, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    note = ', '.join(payload.favouriteCuisines)
    if len(note) > 255:
        raise HTTPException(422, 'Favourite cuisines must fit within 255 characters')
    user.display_name = payload.displayName
    user.cooking_skill = SKILLS[payload.cookingSkill]
    user.kitchen_access = KITCHENS[payload.kitchenAccess]
    user.favourite_cuisines_note = note
    user.dietary_preferences = lookup_values(db, DietaryTag, DietaryTag.tag_name, payload.dietaryPreferences, 60)
    user.allergies = lookup_values(db, Allergy, Allergy.allergy_name, payload.allergies, 80)
    period = current_budget(db, user.user_id)
    if not period:
        start = date.today() - timedelta(days=date.today().weekday())
        period = BudgetPeriod(user_id=user.user_id, period_start=start, period_end=start+timedelta(days=6))
        db.add(period)
    period.budget_amount = payload.weeklyBudget
    db.commit()
    return user_response(user, db)
