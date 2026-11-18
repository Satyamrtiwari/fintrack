from typing import List
from pydantic import BaseModel


class AnalyticsSummary(BaseModel):
    total_income: float
    total_expenses: float
    net_savings: float
    savings_rate: float
    transaction_count: int


class MonthlyBreakdown(BaseModel):
    month: str  # e.g., "Nov 2026" or "2026-11"
    year: int
    income: float
    expense: float
    net: float


class MonthlyAnalyticsResponse(BaseModel):
    monthly_data: List[MonthlyBreakdown]


class CategoryBreakdown(BaseModel):
    category: str
    type: str
    total_amount: float
    percentage: float
    count: int


class CategoryAnalyticsResponse(BaseModel):
    expense_categories: List[CategoryBreakdown]
    income_categories: List[CategoryBreakdown]
