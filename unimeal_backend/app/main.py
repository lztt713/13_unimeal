"""UniMeal FastAPI application entry point.

Run with:
    uvicorn app.main:app --reload
"""

from pathlib import Path

from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session
from app.database import get_db
from fastapi.middleware.cors import CORSMiddleware

from app.routers import accounts, community, dashboard, planning, recipes, recommendations

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

app.include_router(accounts.router)
app.include_router(community.router)
app.include_router(recommendations.router)
app.include_router(recipes.router)
app.include_router(planning.router)
app.include_router(dashboard.router)


@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    """Simple health check endpoint."""
    db.execute(text("SELECT 1"))
    return {"status": "ok", "service": "unimeal-api", "database": "connected"}


@app.exception_handler(IntegrityError)
async def integrity_error(_request, _exc):
    return JSONResponse(status_code=409, content={"detail": "This change conflicts with existing data or database constraints"})


@app.exception_handler(OperationalError)
async def database_error(_request, _exc):
    return JSONResponse(status_code=503, content={"detail": "Database unavailable. Check the local MySQL service and .env connection settings."})


# Serve the built Vue app and API together for a simple local prototype.
DIST = Path(__file__).resolve().parents[2] / 'unimeal_frontend' / 'dist'
if DIST.is_dir():
    app.mount('/assets', StaticFiles(directory=DIST / 'assets'), name='assets')

    @app.get('/{path:path}', include_in_schema=False)
    def frontend(path: str):
        if path == 'api' or path.startswith('api/'):
            raise HTTPException(404, 'API endpoint not found')
        target = (DIST / path).resolve()
        if not target.is_relative_to(DIST.resolve()):
            raise HTTPException(404, 'Not found')
        return FileResponse(target if target.is_file() else DIST / 'index.html')
