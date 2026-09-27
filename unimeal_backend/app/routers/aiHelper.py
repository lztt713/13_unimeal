from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import student_user
from app.database import get_db
from app.models import User
from app.services.aiRecommendation import recommend_recipes
from app.schemas import AiRecommendationRequest, AiRecommendationResponse

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
    student: User = Depends(student_user),
):
    return recommend_recipes(db, payload.query, student)
