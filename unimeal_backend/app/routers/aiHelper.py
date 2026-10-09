from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import student_user
from app.database import get_db
from app.models import User
from app.routers.recipes import _recipe_to_response
from app.schemas import AiRecommendationRequest, AiRecommendationResponse, RecipeResponse, RecipeSearchParams
from app.services.aiRecommendation import recommend_recipes
from app.services.query_parser import parse_smart_query
from app.services.recipe_service import search_recipes

router = APIRouter(prefix="/api/ai", tags=["AI Helper"])


@router.get("/test")
def test_ai_helper():
    return {
        "message": "AI Helper backend is working"
    }

@router.post("/recommendations", response_model=AiRecommendationResponse)
def get_ai_recommendations(
    payload: AiRecommendationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(student_user),
):
    return recommend_recipes(db, payload.query, current_user)

@router.post("/smart-search", response_model=list[RecipeResponse])
def smart_search(
    payload: AiRecommendationRequest,
    db: Session = Depends(get_db),
    _current_user: User = Depends(student_user),
):
    """Search published recipes from a short natural-language request."""

    constraints = parse_smart_query(payload.query)

    recipes = search_recipes(
        db,
        RecipeSearchParams(
            search=constraints.ingredient,
            price_max=constraints.price_max,
            max_minutes=constraints.max_minutes,
            dietary_tags=constraints.dietary_tags or None,
            sort_by="cost",
            sort_order="asc",
        ),
    )

    return [_recipe_to_response(recipe, db) for recipe in recipes]
