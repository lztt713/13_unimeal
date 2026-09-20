"""UniMeal FastAPI application entry point.

Run with:
    uvicorn app.main:app --reload
"""

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session

from app.database import get_db
from app.routers import admin, aiHelper, auth, dashboard, notifications, planning, recipes

app = FastAPI(
    title="UniMeal API",
    description="Backend for the UniMeal student meal planning app",
    version="0.1.0",
)

# Allow frontend dev server (Vite default: localhost:5173)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(recipes.router)
app.include_router(planning.router)
app.include_router(dashboard.router)
app.include_router(aiHelper.router)
app.include_router(notifications.router)
app.include_router(admin.router)


# ZZH: 全局异常处理：约束冲突统一转 409，不把数据库报错细节（可能含表名/连接串）泄露给前端。
# Global handler: constraint conflicts become 409 without leaking DB internals.
@app.exception_handler(IntegrityError)
async def integrity_error_handler(request, exc):
    """Return a clean 409 without leaking database internals."""
    return JSONResponse(
        status_code=409,
        content={"detail": "A record with those details already exists or conflicts with existing data"},
    )


# ZZH: 数据库连不上统一转 503，同样用通用文案，绝不暴露密码/主机名。
# Database outages become 503 with a generic message (no credentials or hostnames).
@app.exception_handler(OperationalError)
async def operational_error_handler(request, exc):
    """Return a clean 503 when the database cannot be reached."""
    return JSONResponse(
        status_code=503,
        content={"detail": "The database is currently unavailable"},
    )


# ZZH: 健康检查真实执行 SELECT 1，数据库不可达时返回 503 而非假装健康。
# The health check actually runs a query and returns 503 if the DB is unreachable.
@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    """Health check that verifies a real database connection."""
    try:
        db.execute(text("SELECT 1"))
    except OperationalError:
        raise HTTPException(status_code=503, detail="The database is currently unavailable") from None
    return {"status": "ok", "service": "unimeal-api", "database": "connected"}
