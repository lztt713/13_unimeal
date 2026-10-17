"""Content reports and administrator management endpoints.

Zhang Zhanhe (ZZH): Any authenticated user can report a recipe or comment.
Administrators can view statistics, manage users and recipes, resolve reports,
and maintain ingredient categories.
"""

from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.auth import admin_user, get_current_user
from app.database import get_db
from app.models import (
    ContentReport,
    Ingredient,
    IngredientCategory,
    MealPlan,
    Recipe,
    RecipeComment,
    Role,
    User,
)
from app.routers.recipes import _db_status, _display_difficulty, _display_status
from app.schemas import (
    AdminRecipeStatusUpdate,
    AdminUserUpdate,
    IngredientCategoryCreate,
    ReportCreate,
    ReportStatusUpdate,
)

router = APIRouter(prefix="/api", tags=["admin"])

# Report status: the frontend sends display labels, the DB stores enum values.
REPORT_STATUS_DB = {
    "open": "open",
    "in review": "reviewing",
    "resolved": "resolved",
    "dismissed": "dismissed",
}
REPORT_STATUS_DISPLAY = {
    "open": "Open",
    "reviewing": "In review",
    "resolved": "Resolved",
    "dismissed": "Dismissed",
}


def _report_target_title(report: ContentReport) -> str:
    if report.recipe_id is not None:
        recipe = report.recipe
        return recipe.title if recipe else "Deleted recipe"
    comment = report.comment
    if comment is not None:
        recipe = comment.recipe
        return f"Comment on {recipe.title}" if recipe else "Comment"
    return "Unknown target"


def _report_response(report: ContentReport) -> dict:
    return {
        "id": int(report.content_report_id),
        "targetType": "Recipe" if report.recipe_id is not None else "Comment",
        "targetTitle": _report_target_title(report),
        "reporter": report.reporter.display_name if report.reporter else "Unknown",
        "reason": report.reason,
        "status": REPORT_STATUS_DISPLAY.get(report.status, report.status),
        "createdAt": report.created_at.isoformat() if report.created_at else None,
    }


def create_report(db: Session, reporter: User, target_type: str, target_id: int, reason: str) -> dict:
    """Record a report against one recipe or one comment.

    A report must target an existing recipe or comment. The database CHECK
    constraint enforces that exactly one of recipe_id and comment_id is set.
    """
    reason = reason.strip()
    if not reason:
        raise HTTPException(status_code=400, detail="Please provide a reason")

    report = ContentReport(
        reporter_user_id=reporter.user_id,
        reason=reason,
        status="open",
        created_at=datetime.now(),
    )
    target_type = target_type.strip().lower()
    if target_type == "recipe":
        if db.get(Recipe, target_id) is None:
            raise HTTPException(status_code=404, detail="Recipe not found")
        report.recipe_id = target_id
    elif target_type == "comment":
        if db.get(RecipeComment, target_id) is None:
            raise HTTPException(status_code=404, detail="Comment not found")
        report.recipe_comment_id = target_id
    else:
        raise HTTPException(status_code=400, detail="targetType must be Recipe or Comment")

    db.add(report)
    db.commit()
    db.refresh(report)
    return {"id": int(report.content_report_id), "status": REPORT_STATUS_DISPLAY[report.status]}


def admin_overview(db: Session) -> dict:
    active_users = db.query(User).filter(User.is_active.is_(True)).count()
    suspended_users = db.query(User).filter(User.is_active.is_(False)).count()
    published_recipes = db.query(Recipe).filter(Recipe.status == "published").count()
    draft_recipes = db.query(Recipe).filter(Recipe.status == "draft").count()
    meal_plans = db.query(MealPlan).count()
    open_reports = db.query(ContentReport).filter(ContentReport.status == "open").count()

    reports = (
        db.query(ContentReport)
        .order_by(ContentReport.created_at.desc(), ContentReport.content_report_id.desc())
        .all()
    )

    return {
        "statistics": [
            {"label": "Active users", "value": active_users, "note": f"{suspended_users} suspended"},
            {"label": "Published recipes", "value": published_recipes, "note": f"{draft_recipes} drafts"},
            {"label": "Weekly meal plans", "value": meal_plans, "note": "All weeks"},
            {"label": "Open reports", "value": open_reports, "note": "Needs review"},
        ],
        "reports": [_report_response(report) for report in reports],
    }


def admin_management(db: Session) -> dict:
    users = [
        {
            "id": int(user.user_id),
            "displayName": user.display_name,
            "email": user.email,
            "role": user.role.role_name,
            "status": "Active" if user.is_active else "Suspended",
        }
        for user in db.query(User).order_by(User.user_id.asc()).all()
    ]
    recipes = [
        {
            "id": int(recipe.recipe_id),
            "title": recipe.title,
            "cuisine": recipe.cuisine.cuisine_name if recipe.cuisine else "Unclassified",
            "difficulty": _display_difficulty(recipe.difficulty),
            "estimatedCost": float(recipe.estimated_cost or 0),
            "status": _display_status(recipe.status),
        }
        for recipe in db.query(Recipe).order_by(Recipe.recipe_id.desc()).all()
    ]
    return {"users": users, "recipes": recipes}


def update_report_status(db: Session, admin: User, report_id: int, status: str) -> dict:
    db_status = REPORT_STATUS_DB.get((status or "").strip().lower())
    if db_status is None:
        raise HTTPException(status_code=400, detail="Invalid report status")
    report = db.get(ContentReport, report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = db_status
    report.reviewed_by_user_id = admin.user_id
    report.reviewed_at = datetime.now()
    db.commit()
    return admin_overview(db)


def update_user(db: Session, admin: User, user_id: int, role: str | None, status: str | None) -> dict:
    # Guard: an administrator cannot suspend their own account.
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="User not found")

    if role is not None:
        role_row = db.query(Role).filter(Role.role_name == role.strip().lower()).first()
        if role_row is None:
            raise HTTPException(status_code=400, detail="Invalid role")
        target.role_id = role_row.role_id

    if status is not None:
        is_active = status.strip().lower() == "active"
        if not is_active and target.user_id == admin.user_id:
            raise HTTPException(status_code=400, detail="You cannot suspend your own account")
        target.is_active = is_active

    target.updated_at = datetime.now()
    db.commit()
    return admin_management(db)


def update_recipe_status(db: Session, recipe_id: int, status: str) -> dict:
    recipe = db.get(Recipe, recipe_id)
    if recipe is None:
        raise HTTPException(status_code=404, detail="Recipe not found")
    recipe.status = _db_status(status)
    db.commit()
    return admin_management(db)


def list_ingredient_categories(db: Session) -> list[dict]:
    rows = (
        db.query(IngredientCategory)
        .order_by(IngredientCategory.ingredient_category_id.asc())
        .all()
    )
    return [
        {"id": int(category.ingredient_category_id), "name": category.category_name, "description": None}
        for category in rows
    ]


def add_ingredient_category(db: Session, name: str) -> list[dict]:
    name = name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Category name cannot be empty")
    exists = (
        db.query(IngredientCategory)
        .filter(func.lower(IngredientCategory.category_name) == name.lower())
        .first()
    )
    if exists is not None:
        raise HTTPException(status_code=409, detail="This category already exists")
    db.add(IngredientCategory(category_name=name))
    db.commit()
    return list_ingredient_categories(db)


def delete_ingredient_category(db: Session, category_id: int) -> list[dict]:
    category = db.get(IngredientCategory, category_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    if db.query(Ingredient).filter(Ingredient.ingredient_category_id == category_id).first() is not None:
        raise HTTPException(
            status_code=409,
            detail="This category is still used by ingredients and cannot be deleted",
        )
    db.delete(category)
    db.commit()
    return list_ingredient_categories(db)


# Reporting only requires being signed in (any role).
@router.post("/reports", status_code=201)
def submit_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Report a recipe or comment for administrator review."""
    return create_report(db, user, payload.target_type, payload.target_id, payload.reason)


# Every /admin/** route below uses admin_user, so non-admins receive 403.
@router.get("/admin/overview")
def get_admin_overview(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    """Return platform statistics and reported content for administrators."""
    return admin_overview(db)


@router.get("/admin/management")
def get_admin_management(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    """Return users and recipes for the administration management view."""
    return admin_management(db)


@router.patch("/admin/reports/{report_id}")
def patch_report(
    report_id: int,
    payload: ReportStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_user),
):
    """Update a report's review status."""
    return update_report_status(db, admin, report_id, payload.status)


@router.patch("/admin/users/{user_id}")
def patch_user(
    user_id: int,
    payload: AdminUserUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_user),
):
    """Update a user's role and/or active status."""
    return update_user(db, admin, user_id, payload.role, payload.status)


@router.patch("/admin/recipes/{recipe_id}")
def patch_recipe(
    recipe_id: int,
    payload: AdminRecipeStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_user),
):
    """Update a recipe's visibility status."""
    return update_recipe_status(db, recipe_id, payload.status)


@router.get("/admin/ingredient-categories")
def get_ingredient_categories(db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    """List ingredient categories."""
    return list_ingredient_categories(db)


@router.post("/admin/ingredient-categories")
def post_ingredient_category(
    payload: IngredientCategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_user),
):
    """Add a new ingredient category."""
    return add_ingredient_category(db, payload.name)


@router.delete("/admin/ingredient-categories/{category_id}")
def delete_ingredient_category_endpoint(
    category_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(admin_user),
):
    """Delete an ingredient category that is not referenced by any ingredient."""
    return delete_ingredient_category(db, category_id)
