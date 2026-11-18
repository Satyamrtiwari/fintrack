import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.config import settings
from app.database import engine, Base, SessionLocal
from app.models.category import Category
from app.routers import auth, transactions, analytics, categories

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger(__name__)


def seed_default_categories(db: Session):
    default_categories = [
        # Expense categories
        {"name": "Food & Dining", "type": "expense", "icon": "restaurant", "color": "#EF4444"},
        {"name": "Transportation", "type": "expense", "icon": "directions_car", "color": "#F97316"},
        {"name": "Housing & Rent", "type": "expense", "icon": "home", "color": "#8B5CF6"},
        {"name": "Utilities & Bills", "type": "expense", "icon": "receipt_long", "color": "#06B6D4"},
        {"name": "Entertainment", "type": "expense", "icon": "movie", "color": "#EC4899"},
        {"name": "Shopping", "type": "expense", "icon": "shopping_bag", "color": "#3B82F6"},
        {"name": "Health & Medical", "type": "expense", "icon": "local_hospital", "color": "#10B981"},
        {"name": "Education", "type": "expense", "icon": "school", "color": "#6366F1"},
        {"name": "Travel", "type": "expense", "icon": "flight", "color": "#14B8A6"},
        {"name": "Other Expense", "type": "expense", "icon": "more_horiz", "color": "#6B7280"},
        # Income categories
        {"name": "Salary", "type": "income", "icon": "payments", "color": "#10B981"},
        {"name": "Freelance", "type": "income", "icon": "computer", "color": "#3B82F6"},
        {"name": "Investments", "type": "income", "icon": "trending_up", "color": "#8B5CF6"},
        {"name": "Business", "type": "income", "icon": "store", "color": "#F59E0B"},
        {"name": "Gifts & Grants", "type": "income", "icon": "card_giftcard", "color": "#EC4899"},
        {"name": "Other Income", "type": "income", "icon": "add_circle_outline", "color": "#059669"},
    ]

    for cat_data in default_categories:
        existing = db.query(Category).filter(
            Category.name == cat_data["name"],
            Category.type == cat_data["type"]
        ).first()
        if not existing:
            cat = Category(**cat_data)
            db.add(cat)
    db.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure tables and seed initial data
    logger.info("Initializing FinTrack database tables...")
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()
    try:
        seed_default_categories(db)
        logger.info("FinTrack default categories checked and seeded.")
    finally:
        db.close()
    yield
    logger.info("FinTrack API shutting down.")


app = FastAPI(
    title="FinTrack API",
    description="Full-Stack Personal Finance Management REST API built with FastAPI, SQLAlchemy, and JWT.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins including Flutter Web and Mobile
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(transactions.router)
app.include_router(analytics.router)
app.include_router(categories.router)


@app.get("/", tags=["Health"])
def root():
    return {
        "app": "FinTrack API",
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "healthy"}
