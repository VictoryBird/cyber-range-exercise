"""
MOIS External Portal API Server
Asset 01: External Portal Server (192.168.92.201)

[취약점] VULN-01-01: Swagger UI and OpenAPI spec exposed in production.
올바른 구현: set docs_url=None, redoc_url=None, openapi_url=None
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from database import get_pool, close_pool
from routers import notices, search, inquiry, admin, internal
import logging

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
    ],
)

logger = logging.getLogger("mois-portal")

# Try to add file handler (may fail if log dir doesn't exist in dev)
try:
    fh = logging.FileHandler(settings.LOG_FILE)
    fh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
    logger.addHandler(fh)
except (FileNotFoundError, PermissionError):
    pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    logger.info("MOIS Portal API starting up...")
    await get_pool()
    logger.info("Database connection pool initialized")
    yield
    logger.info("MOIS Portal API shutting down...")
    await close_pool()


# [취약점] VULN-01-01: API documentation exposed in production
# 올바른 구현:
#   app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
app = FastAPI(
    title="MOIS Portal API",
    version=settings.VERSION,
    description="Republic of Valdoria - Ministry of Interior and Safety Portal API",
    docs_url="/docs",           # [취약 설정] Swagger UI active in production
    redoc_url="/redoc",         # [취약 설정] ReDoc active in production
    openapi_url="/openapi.json",  # [취약 설정] OpenAPI spec exposed
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS + ["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(notices.router)
app.include_router(search.router)
app.include_router(inquiry.router)
app.include_router(admin.router)
app.include_router(internal.router)


@app.get("/")
async def root():
    return {
        "service": "MOIS Portal API",
        "version": settings.VERSION,
        "status": "running",
    }
