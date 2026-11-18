from typing import Optional, List, Dict
from datetime import date, timedelta
from collections import defaultdict
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.transaction import Transaction
from app.schemas.analytics import (
    AnalyticsSummary,
    MonthlyBreakdown,
    MonthlyAnalyticsResponse,
    CategoryBreakdown,
    CategoryAnalyticsResponse,
)


def get_summary(
    db: Session,
    user_id: int,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None
) -> AnalyticsSummary:
    query = db.query(
        Transaction.type,
        func.sum(Transaction.amount).label("total_amount"),
        func.count(Transaction.id).label("count")
    ).filter(Transaction.user_id == user_id)

    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)

    results = query.group_by(Transaction.type).all()

    total_income = 0.0
    total_expenses = 0.0
    total_count = 0

    for r in results:
        t_type = r[0]
        amount = float(r[1] or 0.0)
        cnt = int(r[2] or 0)
        total_count += cnt
        if t_type == "income":
            total_income = amount
        elif t_type == "expense":
            total_expenses = amount

    net_savings = round(total_income - total_expenses, 2)
    savings_rate = 0.0
    if total_income > 0:
        savings_rate = round((net_savings / total_income) * 100, 2)

    return AnalyticsSummary(
        total_income=round(total_income, 2),
        total_expenses=round(total_expenses, 2),
        net_savings=net_savings,
        savings_rate=savings_rate,
        transaction_count=total_count
    )


def get_monthly_breakdown(
    db: Session,
    user_id: int,
    months: int = 6
) -> MonthlyAnalyticsResponse:
    # Query transactions from past X months or all transactions
    # To be reliable across SQLite & PostgreSQL, fetch date, type, amount in query
    today = date.today()
    # Approx 30 days per month
    cutoff_date = (today.replace(day=1) - timedelta(days=months * 31)).replace(day=1)

    transactions = db.query(
        Transaction.transaction_date,
        Transaction.type,
        Transaction.amount
    ).filter(
        Transaction.user_id == user_id,
        Transaction.transaction_date >= cutoff_date
    ).order_by(Transaction.transaction_date.asc()).all()

    # Aggregate by (year, month)
    monthly_data_map: Dict[tuple, Dict[str, float]] = defaultdict(lambda: {"income": 0.0, "expense": 0.0})

    # Ensure recent months are present in sequence
    current = cutoff_date
    while current <= today:
        key = (current.year, current.month)
        if key not in monthly_data_map:
            monthly_data_map[key] = {"income": 0.0, "expense": 0.0}
        # Advance by 1 month
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)

    for t_date, t_type, amount in transactions:
        key = (t_date.year, t_date.month)
        amt = float(amount or 0.0)
        if t_type == "income":
            monthly_data_map[key]["income"] += amt
        elif t_type == "expense":
            monthly_data_map[key]["expense"] += amt

    month_names = [
        "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    result: List[MonthlyBreakdown] = []
    # Sort by (year, month)
    sorted_keys = sorted(monthly_data_map.keys())
    # Take the last `months` entries
    if len(sorted_keys) > months:
        sorted_keys = sorted_keys[-months:]

    for y, m in sorted_keys:
        inc = round(monthly_data_map[(y, m)]["income"], 2)
        exp = round(monthly_data_map[(y, m)]["expense"], 2)
        net = round(inc - exp, 2)
        label = f"{month_names[m]} {y}"
        result.append(
            MonthlyBreakdown(
                month=label,
                year=y,
                income=inc,
                expense=exp,
                net=net
            )
        )

    return MonthlyAnalyticsResponse(monthly_data=result)


def get_category_breakdown(
    db: Session,
    user_id: int,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None
) -> CategoryAnalyticsResponse:
    query = db.query(
        Transaction.category,
        Transaction.type,
        func.sum(Transaction.amount).label("total_amount"),
        func.count(Transaction.id).label("count")
    ).filter(Transaction.user_id == user_id)

    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)

    rows = query.group_by(Transaction.category, Transaction.type).all()

    expense_items: List[dict] = []
    income_items: List[dict] = []
    total_expense = 0.0
    total_income = 0.0

    for cat, t_type, amt, count in rows:
        amount = float(amt or 0.0)
        item = {
            "category": cat,
            "type": t_type,
            "total_amount": round(amount, 2),
            "count": int(count)
        }
        if t_type == "expense":
            total_expense += amount
            expense_items.append(item)
        else:
            total_income += amount
            income_items.append(item)

    # Calculate percentages
    expense_breakdown: List[CategoryBreakdown] = []
    for item in sorted(expense_items, key=lambda x: x["total_amount"], reverse=True):
        pct = round((item["total_amount"] / total_expense) * 100, 2) if total_expense > 0 else 0.0
        expense_breakdown.append(
            CategoryBreakdown(
                category=item["category"],
                type="expense",
                total_amount=item["total_amount"],
                percentage=pct,
                count=item["count"]
            )
        )

    income_breakdown: List[CategoryBreakdown] = []
    for item in sorted(income_items, key=lambda x: x["total_amount"], reverse=True):
        pct = round((item["total_amount"] / total_income) * 100, 2) if total_income > 0 else 0.0
        income_breakdown.append(
            CategoryBreakdown(
                category=item["category"],
                type="income",
                total_amount=item["total_amount"],
                percentage=pct,
                count=item["count"]
            )
        )

    return CategoryAnalyticsResponse(
        expense_categories=expense_breakdown,
        income_categories=income_breakdown
    )
