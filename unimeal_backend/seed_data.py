"""Seed the database with initial data matching the frontend mock.

Run once after first setup:
    cd unimeal_backend
    python seed_data.py
"""

from app.database import Base, SessionLocal, engine
from app.models import Ingredient, Recipe, RecipeIngredient, Student

# Ensure tables exist
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# ── Clear existing data ─────────────────────────────────────────────────────
db.query(RecipeIngredient).delete()
db.query(Ingredient).delete()
db.query(Recipe).delete()
db.query(Student).delete()

# ── Student ─────────────────────────────────────────────────────────────────
student = Student(
    id=1,
    name="Michael",
    weekly_budget=45.0,
    spent=27.6,
)
db.add(student)

# ── Ingredients (with unit prices for procurement cost calculation) ─────────
ingredient_data = [
    # Recipe 1: Creamy Tomato Pasta
    {"name": "pasta", "unit": "g", "unit_price": 0.003},       # $3/kg
    {"name": "tomato", "unit": "piece", "unit_price": 0.50},
    {"name": "cream", "unit": "ml", "unit_price": 0.008},      # $8/L
    # Recipe 2: Teriyaki Chicken Rice Bowl
    {"name": "chicken", "unit": "g", "unit_price": 0.008},     # $8/kg
    {"name": "rice", "unit": "g", "unit_price": 0.002},        # $2/kg
    {"name": "broccoli", "unit": "g", "unit_price": 0.005},    # $5/kg
    # Recipe 3: Chickpea Coconut Curry
    {"name": "chickpeas", "unit": "g", "unit_price": 0.003},
    {"name": "coconut milk", "unit": "ml", "unit_price": 0.006},
    # Recipe 4: Mediterranean Veggie Wrap
    {"name": "wrap", "unit": "piece", "unit_price": 0.40},
    {"name": "hummus", "unit": "g", "unit_price": 0.010},
    {"name": "cucumber", "unit": "piece", "unit_price": 0.60},
    # Recipe 5: Spiced Lentil Soup
    {"name": "lentils", "unit": "g", "unit_price": 0.002},
    {"name": "carrot", "unit": "piece", "unit_price": 0.30},
    {"name": "cumin", "unit": "g", "unit_price": 0.020},
    # Recipe 6: Garlic Mushroom Toast
    {"name": "mushrooms", "unit": "g", "unit_price": 0.007},
    {"name": "bread", "unit": "slice", "unit_price": 0.25},
    {"name": "garlic", "unit": "clove", "unit_price": 0.10},
]

ingredients = {}
for data in ingredient_data:
    ing = Ingredient(name=data["name"], unit=data["unit"], unit_price=data["unit_price"])
    db.add(ing)
    db.flush()
    ingredients[data["name"]] = ing

# ── Recipes ─────────────────────────────────────────────────────────────────
recipe_data = [
    {
        "id": 1,
        "title": "Creamy Tomato Pasta",
        "image_url": "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80",
        "cuisine": "Italian",
        "difficulty": "Easy",
        "estimated_cost": 4.80,
        "cook_time": 25,
        "rating": 4.8,
        "review_count": 126,
        "dietary_tags": "Vegetarian",
        "steps": "Boil pasta\nMake sauce\nCombine",
        "ingredients": [("pasta", 200), ("tomato", 4), ("cream", 100)],
    },
    {
        "id": 2,
        "title": "Teriyaki Chicken Rice Bowl",
        "image_url": "https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80",
        "cuisine": "Japanese",
        "difficulty": "Easy",
        "estimated_cost": 5.60,
        "cook_time": 30,
        "rating": 4.7,
        "review_count": 94,
        "dietary_tags": "High Protein",
        "steps": "Cook rice\nPan fry chicken\nAssemble bowl",
        "ingredients": [("chicken", 250), ("rice", 300), ("broccoli", 150)],
    },
    {
        "id": 3,
        "title": "Chickpea Coconut Curry",
        "image_url": "https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=900&q=80",
        "cuisine": "Indian",
        "difficulty": "Easy",
        "estimated_cost": 4.20,
        "cook_time": 35,
        "rating": 4.9,
        "review_count": 203,
        "dietary_tags": "Vegan, Gluten Free",
        "steps": "Toast spices\nSimmer curry\nServe with rice",
        "ingredients": [("chickpeas", 200), ("coconut milk", 300), ("rice", 250)],
        "is_tonight": True,
    },
    {
        "id": 4,
        "title": "Mediterranean Veggie Wrap",
        "image_url": "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&w=900&q=80",
        "cuisine": "Mediterranean",
        "difficulty": "Easy",
        "estimated_cost": 3.90,
        "cook_time": 15,
        "rating": 4.6,
        "review_count": 71,
        "dietary_tags": "Vegetarian",
        "steps": "Chop vegetables\nFill wrap\nRoll and serve",
        "ingredients": [("wrap", 3), ("hummus", 60), ("cucumber", 2)],
    },
    {
        "id": 5,
        "title": "Spiced Lentil Soup",
        "image_url": "https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80",
        "cuisine": "Middle Eastern",
        "difficulty": "Medium",
        "estimated_cost": 3.50,
        "cook_time": 45,
        "rating": 4.8,
        "review_count": 154,
        "dietary_tags": "Vegan, Budget",
        "steps": "Sauté vegetables\nSimmer lentils\nBlend partly",
        "ingredients": [("lentils", 250), ("carrot", 3), ("cumin", 5)],
    },
    {
        "id": 6,
        "title": "Garlic Mushroom Toast",
        "image_url": "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=900&q=80",
        "cuisine": "European",
        "difficulty": "Easy",
        "estimated_cost": 3.20,
        "cook_time": 20,
        "rating": 4.5,
        "review_count": 52,
        "dietary_tags": "Vegetarian",
        "steps": "Toast bread\nSauté mushrooms\nTop and serve",
        "ingredients": [("mushrooms", 200), ("bread", 4), ("garlic", 3)],
    },
]

for rd in recipe_data:
    recipe = Recipe(
        id=rd["id"],
        title=rd["title"],
        image_url=rd["image_url"],
        cuisine=rd["cuisine"],
        difficulty=rd["difficulty"],
        estimated_cost=rd["estimated_cost"],
        cook_time=rd["cook_time"],
        rating=rd["rating"],
        review_count=rd["review_count"],
        dietary_tags=rd["dietary_tags"],
        steps=rd["steps"],
        is_tonight=1 if rd.get("is_tonight") else 0,
    )
    db.add(recipe)
    db.flush()

    for ing_name, qty in rd["ingredients"]:
        ing = ingredients[ing_name]
        db.add(RecipeIngredient(recipe_id=recipe.id, ingredient_id=ing.id, quantity=qty))

# ── Student favourites ──────────────────────────────────────────────────────
student.favourite_recipes = [
    db.get(Recipe, 1),
    db.get(Recipe, 2),
    db.get(Recipe, 4),
]

db.commit()
db.close()

print("Database seeded successfully!")
print(f"  - 1 student (Michael)")
print(f"  - {len(ingredients)} ingredients with unit prices")
print(f"  - {len(recipe_data)} recipes with ingredient links")
print(f"  - 3 favourite recipes")
print(f"  - Tonight's recipe: Chickpea Coconut Curry (#3)")
