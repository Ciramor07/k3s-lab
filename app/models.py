from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from database import Base

class Item(Base):
    """
    Représente la table 'items' dans PostgreSQL.
    Chaque attribut = une colonne dans la table.
    """
    __tablename__ = "items"

    id          = Column(Integer, primary_key=True, index=True)
    name        = Column(String(100), nullable=False)
    description = Column(String(500), nullable=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())