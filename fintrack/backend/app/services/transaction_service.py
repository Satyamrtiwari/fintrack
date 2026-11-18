from typing import Optional, Tuple, List
from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import desc, asc
from fastapi import HTTPException, status

from app.models.transaction import Transaction
from app.schemas.transaction import TransactionCreate, TransactionUpdate


def get_transactions(
    db: Session,
    user_id: int,
    type: Optional[str] = None,
    category: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    search: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    sort_order: str = "desc"
) -> Tuple[List[Transaction], int]:
    query = db.query(Transaction).filter(Transaction.user_id == user_id)

    if type:
        query = query.filter(Transaction.type == type.lower())
    if category:
        query = query.filter(Transaction.category.ilike(f"%{category}%"))
    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)
    if search:
        query = query.filter(
            (Transaction.title.ilike(f"%{search}%")) |
            (Transaction.notes.ilike(f"%{search}%"))
        )

    total = query.count()

    if sort_order.lower() == "asc":
        query = query.order_by(asc(Transaction.transaction_date), asc(Transaction.id))
    else:
        query = query.order_by(desc(Transaction.transaction_date), desc(Transaction.id))

    transactions = query.offset(offset).limit(limit).all()
    return transactions, total


def create_transaction(
    db: Session,
    user_id: int,
    data: TransactionCreate
) -> Transaction:
    transaction = Transaction(
        user_id=user_id,
        title=data.title.strip(),
        amount=round(float(data.amount), 2),
        type=data.type.lower(),
        category=data.category.strip(),
        transaction_date=data.transaction_date,
        notes=data.notes.strip() if data.notes else None
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction


def get_transaction_by_id(
    db: Session,
    transaction_id: int,
    user_id: int
) -> Transaction:
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == user_id
    ).first()
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found or access denied."
        )
    return transaction


def update_transaction(
    db: Session,
    transaction_id: int,
    user_id: int,
    data: TransactionUpdate
) -> Transaction:
    transaction = get_transaction_by_id(db, transaction_id, user_id)

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        if value is not None:
            if field == "amount":
                value = round(float(value), 2)
            elif field in ("title", "category"):
                value = str(value).strip()
            elif field == "type":
                value = str(value).lower()
            elif field == "notes" and isinstance(value, str):
                value = value.strip()
            setattr(transaction, field, value)

    db.commit()
    db.refresh(transaction)
    return transaction


def delete_transaction(
    db: Session,
    transaction_id: int,
    user_id: int
) -> None:
    transaction = get_transaction_by_id(db, transaction_id, user_id)
    db.delete(transaction)
    db.commit()
