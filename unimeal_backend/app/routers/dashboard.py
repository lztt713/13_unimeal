"""Dashboard endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Recipe, Student
from app.routers.recipes import _recipe_to_response
from app.schemas import DashboardResponse

router = APIRouter(prefix="/api", tags=["dashboard"])


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(db: Session = Depends(get_db)):
    """Return the student dashboard: budget info, tonight's recipe, and favourites.

    Uses the first student in the database (single-user prototype).
    """
    student = db.query(Student).first()
    if student is None:
        raise HTTPException(status_code=404, detail="No student found. Run seed_data.py first.")

    # Tonight's suggested recipe
    tonight_recipe = db.query(Recipe).filter(Recipe.is_tonight == 1).first()

    # Favourite recipes
    favourites = student.favourite_recipes

    return DashboardResponse(
        student={
            "name": student.name,
            "weekly_budget": student.weekly_budget,
            "spent": student.spent,
        },
        weekly_budget=student.weekly_budget,
        spent=student.spent,
        tonight=_recipe_to_response(tonight_recipe, db) if tonight_recipe else None,
        favourites=[_recipe_to_response(r, db) for r in favourites],
    )
