from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.analytics import (
    AnalyticsSummary,
    MonthlyAnalyticsResponse,
    CategoryAnalyticsResponse,
)
from app.services import analytics_service

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])


@router.get(
    "/summary",
    response_model=AnalyticsSummary,
    summary="Get overall finance summary (Income, Expenses, Net, Savings Rate)"
)
def get_summary(
    start_date: Optional[date] = Query(None, description="Start date for summary calculation"),
    end_date: Optional[date] = Query(None, description="End date for summary calculation"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns total income, total expenses, net savings, savings rate, and total transaction count.
    """
    return analytics_service.get_summary(
        db=db,
        user_id=current_user.id,
        start_date=start_date,
        end_date=end_date
    )


@router.get(
    "/monthly",
    response_model=MonthlyAnalyticsResponse,
    summary="Get monthly income vs expense analytics"
)
def get_monthly(
    months: int = Query(6, ge=1, le=24, description="Number of past months to retrieve"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns monthly income, expense, and net savings trends over the specified number of months.
    """
    return analytics_service.get_monthly_breakdown(
        db=db,
        user_id=current_user.id,
        months=months
    )


@router.get(
    "/categories",
    response_model=CategoryAnalyticsResponse,
    summary="Get category-wise breakdown with percentages"
)
def get_categories(
    start_date: Optional[date] = Query(None, description="Start date for category aggregation"),
    end_date: Optional[date] = Query(None, description="End date for category aggregation"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns income and expense category distributions, with totals and percentage contributions.
    """
    return analytics_service.get_category_breakdown(
        db=db,
        user_id=current_user.id,
        start_date=start_date,
        end_date=end_date
    )
