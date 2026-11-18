from typing import Optional, Literal
from pydantic import BaseModel, Field, ConfigDict


class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    type: Literal["income", "expense"]
    icon: Optional[str] = "category"
    color: Optional[str] = "#4F46E5"


class CategoryCreate(CategoryBase):
    pass


class CategoryResponse(CategoryBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
