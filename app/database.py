import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# On lit l'URL de connexion depuis une variable d'environnement
# Format : postgresql://utilisateur:motdepasse@hôte:port/nombase
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/itemsdb"
)

# Le moteur SQLAlchemy — c'est lui qui gère la connexion à PostgreSQL
engine = create_engine(DATABASE_URL)

# Une "usine" à sessions — chaque requête HTTP aura sa propre session DB
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# La classe de base dont hériteront tous nos modèles
Base = declarative_base()

def get_db():
    """
    Fonction utilitaire FastAPI.
    Ouvre une session DB pour une requête et la ferme automatiquement après.
    C'est ce qu'on appelle un 'context manager'.
    """
    db = SessionLocal()
    try:
        yield db       # donne la session à l'endpoint
    finally:
        db.close()     # ferme toujours la session, même si erreur