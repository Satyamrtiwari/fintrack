from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.category import Category
from app.schemas.category import CategoryResponse, CategoryCreate

router = APIRouter(prefix="/api/categories", tags=["Categories"])


@router.get(
    "",
    response_model=List[CategoryResponse],
    summary="List available categories"
)
def list_categories(
    type: Optional[str] = Query(None, description="Filter categories by type ('income' or 'expense')"),
    db: Session = Depends(get_db)
):
    """
    Returns available categories with their visual icons and hex colors.
    """
    query = db.query(Category)
    if type:
        query = query.filter(Category.type == type.lower())
    return [CategoryResponse.model_validate(c) for c in query.order_by(Category.name.asc()).all()]


@router.post(
    "",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a custom category"
)
def create_category(
    cat_in: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add a new category (requires authenticated user).
    """
    existing = db.query(Category).filter(
        Category.name.ilike(cat_in.name.strip()),
        Category.type == cat_in.type.lower()
    ).first()
    if existing:
        return CategoryResponse.model_validate(existing)

    category = Category(
        name=cat_in.name.strip(),
        type=cat_in.type.lower(),
        icon=cat_in.icon or "category",
        color=cat_in.color or "#4F46E5"
    )
    db.add(category)
    db.commit()
    db.refresh(category)
    return CategoryResponse.model_validate(category)
