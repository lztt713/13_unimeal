"""Meal planning, generated shopping lists, and budget endpoints."""

from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, time, timedelta
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    BudgetPeriod,
    MealPlan,
    MealPlanEntry,
    Recipe,
    ShoppingList,
    ShoppingListItem,
)
from app.auth import student_user
from app.models import User
from app.schemas import (
    BudgetSummaryResponse,
    MealPlanEntryWrite,
    MealPlanResponse,
    PersistedShoppingListResponse,
)

router = APIRouter(prefix="/api", tags=["planning"])

ALLOWED_MEAL_TYPES = {"breakfast", "lunch", "dinner", "snack"}


def _week_start(day: date) -> date:
    return day - timedelta(days=day.weekday())


def _resolve_week_start(value: date | None) -> date:
    return value or _week_start(date.today())


def _find_plan(db: Session, user_id: int, week_start_date: date) -> MealPlan | None:
    return (
        db.query(MealPlan)
        .filter(
            MealPlan.user_id == user_id,
            MealPlan.week_start_date == week_start_date,
        )
        .first()
    )


def _get_or_create_plan(db: Session, user_id: int, week_start_date: date) -> MealPlan:
    plan = _find_plan(db, user_id, week_start_date)
    if plan is None:
        now = datetime.now()
        plan = MealPlan(
            user_id=user_id,
            week_start_date=week_start_date,
            plan_name="Weekly meal plan",
            created_at=now,
            updated_at=now,
        )
        db.add(plan)
        db.flush()
    return plan


def _plan_response(plan: MealPlan | None, week_start_date: date) -> dict:
    entries = sorted(
        plan.entries if plan else [],
        key=lambda entry: (entry.planned_date, entry.meal_type, entry.meal_plan_entry_id),
    )
    return {
        "id": int(plan.meal_plan_id) if plan else None,
        "week_start_date": week_start_date,
        "plan_name": plan.plan_name if plan else "Weekly meal plan",
        "entries": [
            {
                "id": int(entry.meal_plan_entry_id),
                "planned_date": entry.planned_date,
                "meal_type": entry.meal_type.capitalize(),
                "recipe_id": int(entry.recipe_id),
                "planned_servings": int(entry.servings),
                "notes": entry.notes,
            }
            for entry in entries
        ],
    }


def _validate_slot(payload: MealPlanEntryWrite, week_start_date: date) -> str:
    meal_type = payload.meal_type.strip().lower()
    if meal_type not in ALLOWED_MEAL_TYPES:
        raise HTTPException(status_code=400, detail="Meal type must be breakfast, lunch, dinner, or snack")
    if not week_start_date <= payload.planned_date <= week_start_date + timedelta(days=6):
        raise HTTPException(status_code=400, detail="Planned date must be inside the selected week")
    return meal_type

#  Get a weekly meal plan.
@router.get("/meal-plan", response_model=MealPlanResponse)
def get_meal_plan(
    week_start: date | None = Query(default=None),
    db: Session = Depends(get_db),
    student: User = Depends(student_user),
):

    # Return the requested week for the current student without creating
    # an empty database record when no plan exists.

    week_start_date = _resolve_week_start(week_start)
    return _plan_response(_find_plan(db, student.user_id, week_start_date), week_start_date)

# Create or replace a meal slot.
@router.post("/meal-plan/entries", response_model=MealPlanResponse)
def save_meal_plan_entry(payload: MealPlanEntryWrite, db: Session = Depends(get_db), student: User = Depends(student_user)):

    # Create a meal-plan entry, or replace the recipe and servings already
    # assigned to the same date and meal type.

    week_start_date = _week_start(payload.planned_date)
    meal_type = _validate_slot(payload, week_start_date)
    if db.query(Recipe).filter(Recipe.recipe_id == payload.recipe_id, Recipe.status == "published").first() is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    plan = _get_or_create_plan(db, student.user_id, week_start_date)

    entry = (
        db.query(MealPlanEntry)
        .filter(
            MealPlanEntry.meal_plan_id == plan.meal_plan_id,
            MealPlanEntry.planned_date == payload.planned_date,
            MealPlanEntry.meal_type == meal_type,
        )
        .first()
    )
    if entry is None:
        entry = MealPlanEntry(
            meal_plan_id=plan.meal_plan_id,
            planned_date=payload.planned_date,
            meal_type=meal_type,
            recipe_id=payload.recipe_id,
            servings=payload.planned_servings,
            notes=payload.notes,
        )
        db.add(entry)
    else:
        entry.recipe_id = payload.recipe_id
        entry.servings = payload.planned_servings
        entry.notes = payload.notes
    plan.updated_at = datetime.now()
    db.commit()
    db.refresh(plan)
    return _plan_response(plan, week_start_date)

# Update an existing meal slot.
@router.put("/meal-plan/entries/{entry_id}", response_model=MealPlanResponse)
def update_meal_plan_entry(entry_id: int, payload: MealPlanEntryWrite, db: Session = Depends(get_db), student: User = Depends(student_user)):

    entry = (
        db.query(MealPlanEntry)
        .join(MealPlan)
        .filter(MealPlanEntry.meal_plan_entry_id == entry_id, MealPlan.user_id == student.user_id)
        .first()
    )
    if entry is None:
        raise HTTPException(status_code=404, detail="Meal-plan entry not found")
    week_start_date = entry.meal_plan.week_start_date
    meal_type = _validate_slot(payload, week_start_date)
    if db.query(Recipe).filter(Recipe.recipe_id == payload.recipe_id, Recipe.status == "published").first() is None:
        raise HTTPException(status_code=404, detail="Recipe not found")

    #  Check the updated slot for conflicts.
    duplicate = (
        db.query(MealPlanEntry)
        .filter(
            MealPlanEntry.meal_plan_id == entry.meal_plan_id,
            MealPlanEntry.planned_date == payload.planned_date,
            MealPlanEntry.meal_type == meal_type,
            MealPlanEntry.meal_plan_entry_id != entry_id,
        )
        .first()
    )
    if duplicate is not None:
        raise HTTPException(status_code=409, detail="That meal slot already has an entry")

    entry.planned_date = payload.planned_date
    entry.meal_type = meal_type
    entry.recipe_id = payload.recipe_id
    entry.servings = payload.planned_servings
    entry.notes = payload.notes
    entry.meal_plan.updated_at = datetime.now()
    db.commit()
    db.refresh(entry.meal_plan)
    return _plan_response(entry.meal_plan, week_start_date)

#  Delete an existing meal slot.
@router.delete("/meal-plan/entries/{entry_id}", response_model=MealPlanResponse)
def delete_meal_plan_entry(entry_id: int, db: Session = Depends(get_db), student: User = Depends(student_user)):

    entry = (
        db.query(MealPlanEntry)
        .join(MealPlan)
        .filter(MealPlanEntry.meal_plan_entry_id == entry_id, MealPlan.user_id == student.user_id)
        .first()
    )
    if entry is None:
        raise HTTPException(status_code=404, detail="Meal-plan entry not found")
    plan = entry.meal_plan
    week_start_date = plan.week_start_date
    db.delete(entry)
    plan.updated_at = datetime.now()
    db.commit()
    db.refresh(plan)
    return _plan_response(plan, week_start_date)


def _shopping_response(shopping_list: ShoppingList | None, plan: MealPlan | None) -> dict:
    items = list(shopping_list.items) if shopping_list else []
    recipe_ids = sorted({int(entry.recipe_id) for entry in plan.entries}) if plan else []

    def unit_price(item: ShoppingListItem) -> float:
        if item.ingredient is not None:
            return float(item.ingredient.estimated_unit_cost or 0)
        return float(item.estimated_unit_cost or 0)

    return {
        "id": int(shopping_list.shopping_list_id) if shopping_list else None,
        "recipe_ids": recipe_ids,
        "status": shopping_list.status if shopping_list else "active",
        "items": [
            {
                "id": int(item.shopping_list_item_id),
                "ingredient_id": int(item.ingredient_id) if item.ingredient_id is not None else None,
                "name": item.item_name,
                "unit": item.measurement_unit.unit_symbol,
                "total_quantity": float(item.quantity),
                "unit_price": unit_price(item),
                "estimated_cost": round(float(item.quantity) * unit_price(item), 2),
                "actual_cost": float(item.actual_cost) if item.actual_cost is not None else None,
                "purchased": bool(item.is_purchased),
                "category": item.ingredient.category.category_name
                if item.ingredient and item.ingredient.category
                else None,
            }
            for item in items
        ],
        "total_estimated_cost": round(
            sum(float(item.quantity) * unit_price(item) for item in items),
            2,
        ),
    }


def _generate_shopping_list(db: Session, user_id: int, plan: MealPlan | None) -> dict:

    # Return an empty list when no weekly plan exists.
    if plan is None:
        return _shopping_response(None, None)

    # Reuse the active list already linked to this plan.
    shopping_list = (
        db.query(ShoppingList)
        .filter(
            ShoppingList.user_id == user_id,
            ShoppingList.meal_plan_id == plan.meal_plan_id,
            ShoppingList.status == "active",
        )
        .order_by(ShoppingList.shopping_list_id.desc())
        .first()
    )
    now = datetime.now()
    if shopping_list is None:
        shopping_list = ShoppingList(
            user_id=user_id,
            meal_plan_id=plan.meal_plan_id,
            list_name=f"Week of {plan.week_start_date.isoformat()}",
            status="active",
            created_at=now,
            updated_at=now,
        )
        db.add(shopping_list)
        db.flush()

    # Merge by ingredient and unit IDs, scaling quantities by planned servings.
    merged: dict[tuple[int, int], dict] = {}
    for entry in plan.entries:
        recipe_servings = Decimal(entry.recipe.servings or 1)

        # Required quantity = recipe quantity * planned servings / original servings.
        serving_scale = Decimal(entry.servings) / recipe_servings
        for recipe_item in entry.recipe.recipe_ingredients:
            key = (int(recipe_item.ingredient_id), int(recipe_item.measurement_unit_id))
            current = merged.setdefault(
                key,
                {
                    "ingredient": recipe_item.ingredient,
                    "unit": recipe_item.measurement_unit,
                    "quantity": Decimal("0"),
                },
            )
            current["quantity"] += Decimal(recipe_item.quantity) * serving_scale

    existing = {
        (int(item.ingredient_id), int(item.measurement_unit_id)): item
        for item in shopping_list.items
        if item.ingredient_id is not None
    }

    # Update existing items or create new ones so valid purchase states are preserved.
    for key, values in merged.items():
        item = existing.pop(key, None)
        ingredient = values["ingredient"]
        if item is None:
            item = ShoppingListItem(
                shopping_list_id=shopping_list.shopping_list_id,
                ingredient_id=ingredient.ingredient_id,
                measurement_unit_id=values["unit"].measurement_unit_id,
                is_purchased=False,
            )
            db.add(item)
        item.item_name = ingredient.ingredient_name
        item.quantity = values["quantity"]
        item.estimated_unit_cost = ingredient.estimated_unit_cost

    # Remove items no longer required by the current plan.
    for obsolete in existing.values():
        # Keep paid items so editing a plan does not erase recorded spending.
        if not obsolete.is_purchased:
            db.delete(obsolete)
    shopping_list.updated_at = now
    db.commit()
    db.refresh(shopping_list)
    return _shopping_response(shopping_list, plan)


@router.post("/shopping-list/generate", response_model=PersistedShoppingListResponse)
def generate_shopping_list(
    week_start: date | None = Query(default=None),
    db: Session = Depends(get_db),
    student: User = Depends(student_user),
):

    plan = _find_plan(db, student.user_id, _resolve_week_start(week_start))
    return _generate_shopping_list(db, student.user_id, plan)


@router.patch("/shopping-list/items/{item_id}/purchased", response_model=PersistedShoppingListResponse)
def toggle_shopping_item(item_id: int, db: Session = Depends(get_db), student: User = Depends(student_user)):

    item = (
        db.query(ShoppingListItem)
        .join(ShoppingList)
        .filter(
            ShoppingListItem.shopping_list_item_id == item_id,
            ShoppingList.user_id == student.user_id,
        )
        .first()
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Shopping-list item not found")

    # Toggle between purchased and not purchased.
    item.is_purchased = not bool(item.is_purchased)
    if item.is_purchased:
        item.purchased_at = datetime.now()
        if item.actual_cost is None:
            source_price = (
                item.ingredient.estimated_unit_cost
                if item.ingredient is not None
                else item.estimated_unit_cost
            )
            # Currently use the estimated price as the default actual cost.
            item.actual_cost = Decimal(item.quantity) * Decimal(source_price or 0)
    else:
        item.purchased_at = None
        item.actual_cost = None
    item.shopping_list.updated_at = datetime.now()
    db.commit()
    db.refresh(item.shopping_list)
    return _shopping_response(item.shopping_list, item.shopping_list.meal_plan)


def _budget_period(db: Session, user_id: int, reference_date: date) -> BudgetPeriod | None:
    active = (
        db.query(BudgetPeriod)
        .filter(
            BudgetPeriod.user_id == user_id,
            BudgetPeriod.period_start <= reference_date,
            BudgetPeriod.period_end >= reference_date,
        )
        .order_by(BudgetPeriod.period_start.desc())
        .first()
    )
    if active is not None:
        return active
    return None


def budget_summary_for_user(db: Session, user_id: int, reference_date: date | None = None) -> dict:

    reference_date = reference_date or date.today()
    period = _budget_period(db, user_id, reference_date)
    if period is None:
        start_date = _week_start(reference_date)
        end_date = start_date + timedelta(days=6)
        budget_amount = 0.0
    else:
        start_date = period.period_start
        end_date = period.period_end
        budget_amount = float(period.budget_amount)

    # Include only purchased items within the budget period.
    purchased_items = (
        db.query(ShoppingListItem)
        .join(ShoppingList)
        .filter(
            ShoppingList.user_id == user_id,
            ShoppingListItem.is_purchased.is_(True),
            ShoppingListItem.purchased_at >= datetime.combine(start_date, time.min),
            ShoppingListItem.purchased_at < datetime.combine(end_date + timedelta(days=1), time.min),
        )
        .all()
    )

    # Group uncategorized ingredients under Other.
    categories: dict[str, float] = defaultdict(float)
    for item in purchased_items:
        amount = float(item.actual_cost or 0)
        label = (
            item.ingredient.category.category_name
            if item.ingredient and item.ingredient.category
            else "Other"
        )
        categories[label] += amount
    category_rows = [
        {"label": label, "amount": round(amount, 2)}
        for label, amount in sorted(categories.items())
    ]
    return {
        "period": {
            "start_date": start_date,
            "end_date": end_date,
            "budget_amount": budget_amount,
        },
        "actual_spent": round(sum(row["amount"] for row in category_rows), 2),
        "categories": category_rows,
    }


@router.get("/budget-summary", response_model=BudgetSummaryResponse)
def get_budget_summary(db: Session = Depends(get_db), student: User = Depends(student_user)):

    return budget_summary_for_user(db, student.user_id)
