from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
import models
from database import engine, get_db

# Crée toutes les tables au démarrage si elles n'existent pas
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Items API",
    description="API CRUD pour gérer des items - TP DevOps",
    version="1.0.0"
)

# --- Schémas Pydantic ---
# Ce sont les "contrats" de l'API :
# ce qu'elle accepte en entrée et ce qu'elle retourne en sortie

class ItemCreate(BaseModel):
    """Ce que l'utilisateur envoie pour créer un item."""
    name: str
    description: Optional[str] = None

class ItemResponse(BaseModel):
    """Ce que l'API retourne quand on demande un item."""
    id: int
    name: str
    description: Optional[str]

    class Config:
        from_attributes = True  # Permet la conversion objet SQLAlchemy → JSON

# --- Endpoints ---

@app.get("/health")
def health_check():
    """
    Endpoint de santé.
    Kubernetes l'utilise pour savoir si l'app est vivante.
    """
    return {"status": "healthy"}

@app.post("/items", response_model=ItemResponse, status_code=201)
def create_item(item: ItemCreate, db: Session = Depends(get_db)):
    """
    Crée un nouvel item dans PostgreSQL.
    - Reçoit : {"name": "pizza", "description": "margherita"}
    - Retourne : {"id": 1, "name": "pizza", "description": "margherita"}
    """
    db_item = models.Item(name=item.name, description=item.description)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)  # Récupère l'id généré par PostgreSQL
    return db_item

@app.get("/items", response_model=List[ItemResponse])
def get_items(db: Session = Depends(get_db)):
    """
    Retourne tous les items de PostgreSQL.
    - Retourne : [{"id": 1, "name": "pizza", ...}, ...]
    """
    return db.query(models.Item).all()