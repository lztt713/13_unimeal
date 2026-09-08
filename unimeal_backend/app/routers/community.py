"""Persist existing comments, notifications, reports, and administrator controls."""
from datetime import date, datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.auth import admin_user, get_current_user
from app.database import get_db
from app.models import ContentReport, Ingredient, IngredientCategory, MealPlan, Notification, Recipe, RecipeComment, Role, User
from app.routers.recipes import _recipe_to_response
from app.schemas import RecipeResponse

router = APIRouter(prefix='/api', tags=['community'])


class CommentWrite(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    text: str = Field(min_length=1, max_length=5000)


class ReportWrite(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    targetType: Literal['Recipe', 'Comment']
    targetId: int = Field(gt=0)
    reason: str = Field(min_length=1, max_length=255)


class ReportStatus(BaseModel):
    status: Literal['Open', 'In review', 'Resolved', 'Dismissed']


class UserWrite(BaseModel):
    role: Literal['student', 'contributor', 'administrator'] | None = None
    status: Literal['Active', 'Suspended'] | None = None


class RecipeStatus(BaseModel):
    status: Literal['Published', 'Draft', 'Archived']


class CategoryWrite(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    name: str = Field(min_length=1, max_length=60)


def visible_recipe(db, recipe_id, user):
    recipe = db.get(Recipe, recipe_id)
    if not recipe or (recipe.status != 'published' and recipe.author_user_id != user.user_id and user.role.role_name != 'administrator'):
        raise HTTPException(404, 'Recipe not found')
    return recipe


@router.post('/recipes/{recipe_id}/comments', status_code=201, response_model=RecipeResponse)
def comment(recipe_id: int, payload: CommentWrite, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    recipe = visible_recipe(db, recipe_id, user)
    db.add(RecipeComment(recipe_id=recipe_id, user_id=user.user_id, comment_text=payload.text))
    db.commit()
    return _recipe_to_response(recipe, db)


def notification_response(row):
    return {'id': row.notification_id, 'type': row.notification_type, 'title': row.title,
            'message': row.message, 'read': row.read_at is not None,
            'createdAt': row.created_at.isoformat() if row.created_at else ''}


def available_notifications(db, user):
    return db.query(Notification).filter(Notification.user_id == user.user_id,
        or_(Notification.scheduled_for.is_(None), Notification.scheduled_for <= datetime.now()))


@router.get('/notifications')
def notifications(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return [notification_response(n) for n in available_notifications(db, user).order_by(Notification.created_at.desc()).all()]


@router.patch('/notifications/read-all')
def read_all(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    available_notifications(db, user).filter(Notification.read_at.is_(None)).update({'read_at': datetime.now()}, synchronize_session=False)
    db.commit()
    return notifications(db, user)


@router.patch('/notifications/{notification_id}/read')
def read_notification(notification_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    row = available_notifications(db, user).filter(Notification.notification_id == notification_id).first()
    if not row:
        raise HTTPException(404, 'Notification not found')
    row.read_at = row.read_at or datetime.now()
    db.commit()
    return notification_response(row)


def report_response(row):
    title = row.recipe.title if row.recipe else f'Comment on {row.comment.recipe.title}' if row.comment else 'Removed content'
    return {'id': row.content_report_id, 'targetType': 'Recipe' if row.recipe_id else 'Comment',
            'targetId': row.recipe_id or row.recipe_comment_id, 'targetTitle': title,
            'reporter': row.reporter.display_name, 'reason': row.reason,
            'status': 'In review' if row.status == 'reviewing' else row.status.capitalize(),
            'createdAt': row.created_at.date().isoformat() if row.created_at else ''}


@router.post('/reports', status_code=201)
def create_report(payload: ReportWrite, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if payload.targetType == 'Recipe':
        visible_recipe(db, payload.targetId, user)
        target = {'recipe_id': payload.targetId}
    else:
        comment = db.get(RecipeComment, payload.targetId)
        if not comment or comment.is_hidden:
            raise HTTPException(404, 'Comment not found')
        visible_recipe(db, comment.recipe_id, user)
        target = {'recipe_comment_id': payload.targetId}
    row = ContentReport(reporter_user_id=user.user_id, reason=payload.reason, **target)
    db.add(row)
    db.commit()
    return report_response(row)


@router.get('/admin/overview')
def overview(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    week = date.today() - timedelta(days=date.today().weekday())
    counts = [
        ('Active users', db.query(User).filter(User.is_active.is_(True)).count()),
        ('Published recipes', db.query(Recipe).filter(Recipe.status == 'published').count()),
        ('Weekly meal plans', db.query(MealPlan).filter(MealPlan.week_start_date == week).count()),
        ('Open reports', db.query(ContentReport).filter(ContentReport.status.in_(['open','reviewing'])).count()),
    ]
    return {'statistics': [{'label': label, 'value': value, 'note': ''} for label, value in counts],
            'reports': [report_response(r) for r in db.query(ContentReport).order_by(ContentReport.created_at.desc()).all()]}


@router.patch('/admin/reports/{report_id}')
def update_report(report_id: int, payload: ReportStatus, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    report = db.get(ContentReport, report_id)
    if not report:
        raise HTTPException(404, 'Report not found')
    report.status = 'reviewing' if payload.status == 'In review' else payload.status.lower()
    report.reviewed_by_user_id = admin.user_id
    report.reviewed_at = datetime.now()
    db.commit()
    return overview(db, admin)


@router.get('/admin/management')
def management(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    return {'users': [{'id': u.user_id, 'displayName': u.display_name, 'email': u.email,
                       'role': u.role.role_name, 'status': 'Active' if u.is_active else 'Suspended'}
                      for u in db.query(User).order_by(User.user_id).all()],
            'recipes': [_recipe_to_response(r, db) for r in db.query(Recipe).order_by(Recipe.recipe_id.desc()).all()]}


@router.patch('/admin/users/{user_id}')
def update_user(user_id: int, payload: UserWrite, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(404, 'User not found')
    if user_id == admin.user_id and (payload.status == 'Suspended' or payload.role not in (None, 'administrator')):
        raise HTTPException(409, 'You cannot remove your own administrator access')
    if payload.role:
        role = db.query(Role).filter(Role.role_name == payload.role).first()
        if not role:
            raise HTTPException(422, 'Role not found')
        user.role = role
    if payload.status:
        user.is_active = payload.status == 'Active'
    db.commit()
    return management(db, admin)


@router.patch('/admin/recipes/{recipe_id}')
def update_recipe(recipe_id: int, payload: RecipeStatus, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    recipe = db.get(Recipe, recipe_id)
    if not recipe:
        raise HTTPException(404, 'Recipe not found')
    recipe.status = payload.status.lower()
    db.commit()
    return management(db, admin)


@router.get('/admin/ingredient-categories')
def categories(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    return [{'id': c.ingredient_category_id, 'name': c.category_name, 'description': ''}
            for c in db.query(IngredientCategory).order_by(IngredientCategory.category_name).all()]


@router.post('/admin/ingredient-categories', status_code=201)
def add_category(payload: CategoryWrite, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    if db.query(IngredientCategory).filter(func.lower(IngredientCategory.category_name) == payload.name.lower()).first():
        raise HTTPException(409, 'This category already exists')
    db.add(IngredientCategory(category_name=payload.name))
    db.commit()
    return categories(db, admin)


@router.delete('/admin/ingredient-categories/{category_id}')
def delete_category(category_id: int, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    category = db.get(IngredientCategory, category_id)
    if not category:
        raise HTTPException(404, 'Category not found')
    if db.query(Ingredient).filter(Ingredient.ingredient_category_id == category_id).first():
        raise HTTPException(409, 'This category is used by ingredients and cannot be deleted')
    db.delete(category)
    db.commit()
    return categories(db, admin)
