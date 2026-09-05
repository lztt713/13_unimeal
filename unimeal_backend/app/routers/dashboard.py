"""Dashboard endpoints backed by the shared MySQL schema."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import BudgetPeriod, MealPlan, MealPlanEntry
from app.routers.recipes import DEFAULT_STUDENT_EMAIL, _get_user_by_email, _recipe_to_response
from app.schemas import DashboardResponse

router = APIRouter(prefix="/api", tags=["dashboard"])


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    """Return a minimal student dashboard from the real MySQL tables."""
    student = _get_user_by_email(db, DEFAULT_STUDENT_EMAIL, "Student")
    budget_period = (
        db.query(BudgetPeriod)
        .filter(BudgetPeriod.user_id == student.user_id)
        .order_by(BudgetPeriod.period_start.desc())
        .first()
    )
    tonight_entry = (
        db.query(MealPlanEntry)
        .join(MealPlan, MealPlanEntry.meal_plan_id == MealPlan.meal_plan_id)
        .filter(MealPlan.user_id == student.user_id, MealPlanEntry.meal_type == "dinner")
        .order_by(MealPlanEntry.planned_date.desc())
        .first()
    )

    weekly_budget = float(budget_period.budget_amount) if budget_period else 0.0
    spent = 0.0

    return DashboardResponse(
        student={
            "name": student.display_name,
            "weekly_budget": weekly_budget,
            "spent": spent,
        },
        weekly_budget=weekly_budget,
        spent=spent,
        tonight=_recipe_to_response(tonight_entry.recipe, db) if tonight_entry else None,
        favourites=[_recipe_to_response(recipe, db) for recipe in student.saved_recipes],
    )
