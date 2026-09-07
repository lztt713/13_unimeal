"""Dashboard endpoints backed by the shared MySQL schema."""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MealPlan, MealPlanEntry
from app.routers.planning import budget_summary_for_user
from app.routers.recipes import DEFAULT_STUDENT_EMAIL, _get_user_by_email, _recipe_to_response
from app.schemas import DashboardResponse

router = APIRouter(prefix="/api", tags=["dashboard"])


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    """Return today's dinner, saved recipes, and purchased spend."""
    student = _get_user_by_email(db, DEFAULT_STUDENT_EMAIL, "Student")
    tonight_entry = (
        db.query(MealPlanEntry)
        .join(MealPlan, MealPlanEntry.meal_plan_id == MealPlan.meal_plan_id)
        .filter(
            MealPlan.user_id == student.user_id,
            MealPlanEntry.planned_date == date.today(),
            MealPlanEntry.meal_type == "dinner",
        )
        .first()
    )

    budget = budget_summary_for_user(db, student.user_id)
    weekly_budget = budget["period"]["budget_amount"]
    spent = budget["actual_spent"]

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
