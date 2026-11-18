from sqlalchemy import Column, Integer, String
from app.database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False, unique=True)
    type = Column(String(20), nullable=False)  # 'income' or 'expense'
    icon = Column(String(50), nullable=True, default="category")
    color = Column(String(20), nullable=True, default="#4F46E5")
