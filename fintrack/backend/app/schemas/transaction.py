from datetime import date, datetime
from typing import Optional, List, Literal
from pydantic import BaseModel, Field, ConfigDict


class TransactionBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=150, description="Title of transaction")
    amount: float = Field(..., gt=0, description="Transaction amount (must be positive)")
    type: Literal["income", "expense"] = Field(..., description="Type: 'income' or 'expense'")
    category: str = Field(..., min_length=1, max_length=50, description="Category name")
    transaction_date: date = Field(..., description="Date of transaction (YYYY-MM-DD)")
    notes: Optional[str] = Field(None, max_length=500, description="Optional notes")


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=150)
    amount: Optional[float] = Field(None, gt=0)
    type: Optional[Literal["income", "expense"]] = None
    category: Optional[str] = Field(None, min_length=1, max_length=50)
    transaction_date: Optional[date] = None
    notes: Optional[str] = Field(None, max_length=500)


class TransactionResponse(TransactionBase):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TransactionListResponse(BaseModel):
    transactions: List[TransactionResponse]
    total: int
    limit: int
    offset: int
