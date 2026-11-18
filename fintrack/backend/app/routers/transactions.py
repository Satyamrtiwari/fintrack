from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionResponse,
    TransactionListResponse,
)
from app.services import transaction_service

router = APIRouter(prefix="/api/transactions", tags=["Transactions"])


@router.get(
    "",
    response_model=TransactionListResponse,
    summary="List transactions for the authenticated user"
)
def list_transactions(
    type: Optional[str] = Query(None, description="Filter by type ('income' or 'expense')"),
    category: Optional[str] = Query(None, description="Filter by category"),
    start_date: Optional[date] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[date] = Query(None, description="End date (YYYY-MM-DD)"),
    search: Optional[str] = Query(None, description="Search query in title and notes"),
    limit: int = Query(50, ge=1, le=200, description="Page limit"),
    offset: int = Query(0, ge=0, description="Page offset"),
    sort_order: str = Query("desc", description="Sort order: 'desc' or 'asc'"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieve all transactions belonging to the authenticated user with optional filtering,
    pagination, and search.
    """
    transactions, total = transaction_service.get_transactions(
        db=db,
        user_id=current_user.id,
        type=type,
        category=category,
        start_date=start_date,
        end_date=end_date,
        search=search,
        limit=limit,
        offset=offset,
        sort_order=sort_order
    )
    return TransactionListResponse(
        transactions=[TransactionResponse.model_validate(t) for t in transactions],
        total=total,
        limit=limit,
        offset=offset
    )


@router.post(
    "",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new transaction"
)
def create_transaction(
    transaction_in: TransactionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Record a new income or expense transaction for the current user.
    """
    transaction = transaction_service.create_transaction(
        db=db,
        user_id=current_user.id,
        data=transaction_in
    )
    return TransactionResponse.model_validate(transaction)


@router.get(
    "/{id}",
    response_model=TransactionResponse,
    summary="Get transaction details by ID"
)
def get_transaction(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Fetch a single transaction by ID. Only accessible if it belongs to the authenticated user.
    """
    transaction = transaction_service.get_transaction_by_id(
        db=db,
        transaction_id=id,
        user_id=current_user.id
    )
    return TransactionResponse.model_validate(transaction)


@router.put(
    "/{id}",
    response_model=TransactionResponse,
    summary="Update an existing transaction"
)
def update_transaction(
    id: int,
    transaction_in: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update fields of an existing transaction owned by the authenticated user.
    """
    updated = transaction_service.update_transaction(
        db=db,
        transaction_id=id,
        user_id=current_user.id,
        data=transaction_in
    )
    return TransactionResponse.model_validate(updated)


@router.delete(
    "/{id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a transaction"
)
def delete_transaction(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a transaction. Only accessible if owned by the authenticated user.
    """
    transaction_service.delete_transaction(
        db=db,
        transaction_id=id,
        user_id=current_user.id
    )
    return {"message": "Transaction deleted successfully", "id": id}
