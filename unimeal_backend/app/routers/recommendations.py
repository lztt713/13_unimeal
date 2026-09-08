"""Basic local recommendations for the existing helper page; no external AI call."""
import re
from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session
from app.auth import student_user
from app.database import get_db
from app.models import Recipe, User
from app.routers.recipes import _recipe_to_response

router = APIRouter(prefix='/api', tags=['recommendations'])


class RecommendationQuery(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    query: str = Field(min_length=1, max_length=1000)


@router.post('/recommendations')
def recommend(payload: RecommendationQuery, db: Session = Depends(get_db), user: User = Depends(student_user)):
    query = payload.query.lower()
    price = re.search(r'(?:under|below|less than)\s*\$\s*(\d+(?:\.\d+)?)', query)
    minutes = re.search(r'(?:under|below|less than)\s*(\d+)\s*(?:minutes|mins)', query)
    requested_tags = [tag for tag in ['vegetarian', 'vegan', 'gluten free', 'high protein', 'budget'] if tag in query.replace('-', ' ')]
    tags = requested_tags or [t.tag_name.lower().replace('-', ' ') for t in user.dietary_preferences]
    allergens = {a.allergy_name.lower() for a in user.allergies}
    ingredient_query = re.search(r'\bwith\s+(.+?)(?:\s+(?:under|below)\b|$)', query)
    wanted = [w.strip() for w in re.split(r',|\band\b', ingredient_query.group(1))] if ingredient_query else []
    candidates = []
    for recipe in db.query(Recipe).filter(Recipe.status == 'published').all():
        card = _recipe_to_response(recipe, db)
        if price and card['estimated_cost'] > float(price.group(1)):
            continue
        total_time = card['prep_time'] + card['cook_time']
        if minutes and total_time > int(minutes.group(1)):
            continue
        if 'quick' in query and not minutes and total_time > 30:
            continue
        recipe_tags = {t.lower().replace('-', ' ') for t in card['dietary_tags']}
        if any(t not in recipe_tags for t in tags):
            continue
        if allergens.intersection(a.lower() for a in card['allergen_tags']):
            continue
        names = ' '.join(card['ingredients'])
        if any(w not in names for w in wanted):
            continue
        candidates.append(card)
    candidates.sort(key=lambda c: (c['estimated_cost'], c['prep_time'] + c['cook_time']))
    # Pydantic aliases give the frontend the same recipe shape as the library.
    from app.schemas import RecipeResponse
    return {'query': payload.query, 'mode': 'local-rules',
            'summary': 'Local recipe matching using your request and profile.' if candidates else 'No matching recipes found. Try changing your constraints.',
            'recipes': [RecipeResponse(**c).model_dump(by_alias=True) for c in candidates[:3]],
            'cautions': ['Check ingredient labels against your allergies.', 'Estimated costs can vary by supermarket.']}
