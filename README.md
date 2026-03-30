# k3s-lab

API REST Python déployée sur Kubernetes local (K3s) avec PostgreSQL.

Réalisé dans le cadre d'un exercice technique DevOps.

---

## Stack technique

| Composant | Choix | Motivation |
|---|---|---|
| Framework Python | FastAPI | Moderne, performant, Swagger auto-généré |
| ORM | SQLAlchemy | Standard industrie, flexible |
| Base de données | PostgreSQL 15 | Robuste, open source, standard production |
| Containerisation | Docker multi-stage | Image légère et sécurisée |
| Orchestration | K3s | Kubernetes allégé, compatible 100% K8s |
| Dev local | docker-compose | Orchestration simple, healthchecks |
| Automatisation | Makefile | Universel, sans dépendance supplémentaire |
| CI/CD | GitHub Actions | Intégré à GitHub, gratuit |
| Registry | Docker Hub | Référence, gratuit, simple |

---

## Prérequis

- Linux (Ubuntu 22.04 recommandé)
- Docker installé
- K3s installé
- make installé

### Installation des prérequis
```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# K3s
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc

# make
sudo apt install make -y
```

---

## Démarrage rapide
```bash
# Clone le repo
git clone https://github.com/Ciramor07/k3s-lab.git
cd k3s-lab

# Tout déployer en une commande
make all
```

L'application est accessible sur :
- API : http://localhost:30080
- Documentation Swagger : http://localhost:30080/docs
- Health check : http://localhost:30080/health

---

## Commandes disponibles
```bash
make help     # Affiche toutes les commandes
make all      # Build + Deploy (commande principale)
make build    # Build l'image Docker
make deploy   # Déploie sur K3s
make status   # État des pods et services
make logs     # Logs de l'API en temps réel
make url      # Affiche l'URL d'accès
make restart  # Redémarre l'API
make clean    # Supprime toutes les ressources
```

---

## Tester l'API
```bash
# Créer un item
curl -X POST http://localhost:30080/items \
  -H "Content-Type: application/json" \
  -d '{"name": "pizza", "description": "margherita"}'

# Lister les items
curl http://localhost:30080/items
```

Ou ouvrir la documentation interactive :
```
http://localhost:30080/docs
```

---

## Architecture
```
k3s-lab/
├── app/
│   ├── main.py           # Endpoints FastAPI
│   ├── models.py         # Modèle SQLAlchemy
│   ├── database.py       # Connexion PostgreSQL
│   └── requirements.txt  # Dépendances Python
├── k8s/
│   ├── namespace.yaml          # Namespace items-app
│   ├── postgres-secret.yaml    # Credentials PostgreSQL
│   ├── postgres-pvc.yaml       # Persistance des données
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── api-configmap.yaml      # Configuration API
│   ├── api-deployment.yaml     # 2 replicas API
│   └── api-service.yaml        # NodePort 30080
├── .github/workflows/
│   └── ci.yml            # Build et push Docker Hub
├── Dockerfile            # Multi-stage build
├── docker-compose.yml    # Dev local
└── Makefile              # Automatisation
```

### Schéma de déploiement K8s
```
Namespace: items-app
│
├── Deployment: postgres (1 replica)
│   └── Pod PostgreSQL
│       └── PVC: postgres-pvc (1Gi, données persistantes)
│
├── Service: postgres-service (ClusterIP)
│
├── Deployment: items-api (2 replicas)
│   ├── Pod API 1
│   └── Pod API 2
│       └── Liveness + Readiness probes sur /health
│
└── Service: items-api-service (NodePort 30080)
    └── Accessible depuis l'extérieur
```

---

## Développement local

Pour travailler en local sans Kubernetes :
```bash
# Lance PostgreSQL + API ensemble
docker compose up -d

# Teste
curl http://localhost:8000/items

# Arrête tout
docker compose down
```

---

## CI/CD

A chaque push sur `main`, GitHub Actions :

1. Build l'image Docker
2. La pousse sur Docker Hub avec deux tags :
   - `ciramor07/items-api:latest`
   - `ciramor07/items-api:<sha-commit>`

Le tag par commit permet de revenir à une version précise si besoin.

---

## Choix techniques et alternatives

### Pourquoi K3s et pas Minikube ?

K3s est une vraie distribution Kubernetes utilisée en production,
notamment dans des contextes Edge et IoT. Minikube est un outil
de simulation pour le développement uniquement. K3s m'a permis
de travailler avec les mêmes manifests YAML qu'un cluster classique.

> Note : K3s présente des problèmes de compatibilité avec WSL2
> sur les versions récentes (v1.34+). Une VM Linux dédiée
> est recommandée pour une expérience optimale.

### Pourquoi Makefile et pas un script bash ?

Le Makefile est universel — présent sur toutes les distributions
Linux sans installation supplémentaire. Il gère les dépendances
entre les cibles (build avant deploy) et est lisible par
n'importe quel développeur.

### Pourquoi docker-compose pour le dev local ?

docker-compose permet de lancer l'API et PostgreSQL ensemble
en une commande, avec gestion des dépendances via les healthchecks.
C'est le standard pour le développement local multi-conteneurs.

### Sécurité

- Utilisateur non-root dans le container Docker
- Credentials PostgreSQL dans un Secret Kubernetes (base64)
- Token Docker Hub dans les secrets GitHub Actions

> En production : utiliser Sealed Secrets ou HashiCorp Vault
> pour les secrets Kubernetes, et un registry privé.

---

## Ce que j'aurais fait avec plus de temps

- **Ingress NGINX** plutôt que NodePort pour l'exposition
- **Sealed Secrets** pour les credentials Kubernetes
- **Tests unitaires** avec pytest
- **Helm chart** pour packager le déploiement K8s
- **CD automatisé** : mise à jour automatique du cluster
  après le push sur Docker Hub
- **Monitoring** : Prometheus + Grafana pour les métriques

---

## Auteur

Ditine Exercice technique DevOps
