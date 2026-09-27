"""Notification read/query endpoints with reminder deduplication.

Reminder trigger conditions are supplied by the planning module; this module
owns persistence, deduplication and the read/unread API.

张展赫 (Zhang Zhanhe / ZZH): 通知模块。梁子豪的 planning_reminder_candidates 提供
触发条件，本模块负责数据库写入、去重和已读接口。
"""

from __future__ import annotations

from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import Notification, Role, User, saved_recipes
from app.routers.planning import planning_reminder_candidates
from app.schemas import NotificationResponse

router = APIRouter(prefix="/api", tags=["notifications"])

# ZZH: 梁子豪给的触发类型是 meal_plan/shopping_list，数据库枚举是 meal_reminder/
# shopping_reminder，前端展示名是 "Meal reminder"/"Shopping reminder"，这里做两层映射。
# The planning module emits generic kinds, the DB stores enum values and the
# frontend renders labels — map each layer explicitly.
CANDIDATE_TYPE_MAP = {
    "meal_plan": "meal_reminder",
    "shopping_list": "shopping_reminder",
}
NOTIFICATION_TYPE_DISPLAY = {
    "meal_reminder": "Meal reminder",
    "shopping_reminder": "Shopping reminder",
    "recipe_update": "Recipe update",
    "system": "System",
}


def _notification_response(notification: Notification) -> dict:
    return {
        "id": int(notification.notification_id),
        "type": NOTIFICATION_TYPE_DISPLAY.get(
            notification.notification_type, notification.notification_type
        ),
        "title": notification.title,
        "message": notification.message,
        "created_at": notification.created_at.isoformat() if notification.created_at else None,
        "read": notification.read_at is not None,
    }


def sync_notifications(db: Session, user_id: int) -> None:
    """Create any missing reminders for the user, deduplicated by dedupe_key.

    去重核心：每个触发条件带一个 dedupe_key（如 meal_plan:{uid}:{date}），
    同一用户 + 同一 key 已存在就跳过，避免重复提醒被反复写入。
    """
    candidates = planning_reminder_candidates(db, user_id)
    candidate_keys = {candidate.get("dedupe_key") for candidate in candidates}

    # A shopping reminder describes live state, rather than an immutable event.
    # If today's active list no longer contains an unpurchased item, remove the
    # reminder that was created earlier today so the API cannot return stale UI.
    today_shopping_key = f"shopping_list:{user_id}:{date.today().isoformat()}"
    if today_shopping_key not in candidate_keys:
        (
            db.query(Notification)
            .filter(
                Notification.user_id == user_id,
                Notification.notification_type == "shopping_reminder",
                Notification.dedupe_key == today_shopping_key,
            )
            .delete(synchronize_session=False)
        )

    for candidate in candidates:
        dedupe_key = candidate.get("dedupe_key")
        if dedupe_key and (
            db.query(Notification)
            .filter(Notification.user_id == user_id, Notification.dedupe_key == dedupe_key)
            .first()
            is not None
        ):
            continue
        db.add(
            Notification(
                user_id=user_id,
                notification_type=CANDIDATE_TYPE_MAP.get(candidate["type"], "system"),
                title=candidate["title"],
                message=candidate["message"],
                dedupe_key=dedupe_key,
                created_at=datetime.now(),
            )
        )
    db.commit()


def _list(db: Session, user_id: int) -> list[dict]:
    notifications = (
        db.query(Notification)
        .filter(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc(), Notification.notification_id.desc())
        .all()
    )
    return [_notification_response(notification) for notification in notifications]


def list_notifications(db: Session, user: User) -> list[dict]:
    sync_notifications(db, user.user_id)
    return _list(db, user.user_id)


def notify_recipe_updated(db: Session, recipe) -> None:
    """Notify every user who saved a recipe when its contributor edits it.

    ZZH: 贡献者修改菜谱后，通知所有收藏了该菜谱的学生（recipe_update 类型）。
    用 recipe.updated_at 作为去重 key 的一部分，同一次更新只通知一次，
    下次更新（updated_at 变了）会再产生新通知。
    """
    savers = (
        db.query(User)
        .join(saved_recipes, saved_recipes.c.user_id == User.user_id)
        .join(Role, User.role_id == Role.role_id)
        .filter(
            saved_recipes.c.recipe_id == recipe.recipe_id,
            Role.role_name == "student",
            User.user_id != recipe.author_user_id,
        )
        .all()
    )
    for saver in savers:
        updated_at = recipe.updated_at or datetime.now()
        db.add(
            Notification(
                user_id=saver.user_id,
                notification_type="recipe_update",
                title="Saved recipe updated",
                message=f"{recipe.title} has updated ingredients and steps.",
                dedupe_key=f"recipe_update:{saver.user_id}:{recipe.recipe_id}:{updated_at}",
                created_at=datetime.now(),
            )
        )
    db.commit()


def mark_notification_read(db: Session, user: User, notification_id: int) -> dict:
    notification = (
        db.query(Notification)
        .filter(
            Notification.notification_id == notification_id,
            Notification.user_id == user.user_id,
        )
        .first()
    )
    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    if notification.read_at is None:
        notification.read_at = datetime.now()
        db.commit()
        db.refresh(notification)
    return _notification_response(notification)


def mark_all_notifications_read(db: Session, user: User) -> list[dict]:
    now = datetime.now()
    for notification in (
        db.query(Notification)
        .filter(Notification.user_id == user.user_id, Notification.read_at.is_(None))
        .all()
    ):
        notification.read_at = now
    db.commit()
    return _list(db, user.user_id)


def delete_read_notifications(db: Session, user: User) -> list[dict]:
    """Delete only read notifications owned by the current user."""
    (
        db.query(Notification)
        .filter(Notification.user_id == user.user_id, Notification.read_at.is_not(None))
        .delete(synchronize_session=False)
    )
    db.commit()
    return _list(db, user.user_id)


# ZZH: 列表接口在返回前先同步一次提醒，这样"明天有餐/购物清单未购"会即时出现。
# Listing first syncs reminders so new triggers appear without a cron job.
@router.get("/notifications", response_model=list[NotificationResponse])
def get_notifications(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """List the current user's notifications, syncing pending reminders first."""
    return list_notifications(db, user)


# ZZH: 单条已读：按 notification_id + user_id 联合过滤，保证只能改自己的通知。
# Filter by both id and user_id so a user can only mark their own notification.
@router.patch("/notifications/{notification_id}/read", response_model=NotificationResponse)
def read_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Mark one of the current user's notifications as read."""
    return mark_notification_read(db, user, notification_id)


# ZZH: 全部已读：把当前用户所有 read_at 为空的记录一次性置为已读。
# Marks every unread notification for the current user as read in one go.
@router.patch("/notifications/read-all", response_model=list[NotificationResponse])
def read_all_notifications(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Mark every notification for the current user as read."""
    return mark_all_notifications_read(db, user)


@router.delete("/notifications/read", response_model=list[NotificationResponse])
def clear_read_notifications(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Delete the current user's read notifications and keep unread records."""
    return delete_read_notifications(db, user)
