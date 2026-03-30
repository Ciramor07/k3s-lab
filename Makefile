.PHONY: help install build deploy all status logs url clean restart

# Affiche l'aide par défaut quand on tape juste "make"
help:
	@echo "======================================="
	@echo "  k3s-lab - Commandes disponibles"
	@echo "======================================="
	@echo "  make install  - Vérifie les prérequis"
	@echo "  make build    - Build l'image Docker"
	@echo "  make deploy   - Déploie sur K3s"
	@echo "  make all      - Build + Deploy"
	@echo "  make status   - État des pods"
	@echo "  make logs     - Logs de l'API"
	@echo "  make url      - URL d'accès"
	@echo "  make clean    - Supprime tout"
	@echo "  make restart  - Redémarre l'API"
	@echo "======================================="

# Vérifie que les outils sont installés
install:
	@echo "[1/3] Vérification de Docker..."
	@docker info > /dev/null 2>&1 || \
		(echo "ERREUR: Docker n'est pas lancé !" && exit 1)
	@echo "[2/3] Vérification de kubectl..."
	@kubectl get nodes > /dev/null 2>&1 || \
		(echo "ERREUR: K3s non accessible !" && exit 1)
	@echo "[3/3] Vérification de make..."
	@make --version > /dev/null 2>&1
	@echo "Tous les prérequis sont OK !"

# Build l'image et l'importe dans K3s
build: install
	@echo "Build de l'image Docker..."
	@docker build -t items-api:latest .
	@echo "Import de l'image dans K3s..."
	@docker save items-api:latest | sudo k3s ctr images import -
	@echo "Image prête !"

# Déploie tous les manifests dans le bon ordre
deploy: install
	@echo "Déploiement sur K3s..."
	@kubectl apply -f k8s/namespace.yaml
	@kubectl apply -f k8s/postgres-secret.yaml
	@kubectl apply -f k8s/postgres-pvc.yaml
	@kubectl apply -f k8s/postgres-deployment.yaml
	@kubectl apply -f k8s/postgres-service.yaml
	@kubectl apply -f k8s/api-configmap.yaml
	@kubectl apply -f k8s/api-deployment.yaml
	@kubectl apply -f k8s/api-service.yaml
	@echo "En attente que PostgreSQL soit prêt..."
	@kubectl wait --for=condition=ready pod \
		-l app=postgres \
		-n items-app \
		--timeout=120s
	@echo "En attente que l'API soit prête..."
	@kubectl wait --for=condition=ready pod \
		-l app=items-api \
		-n items-app \
		--timeout=120s
	@echo ""
	@echo "Déploiement réussi !"
	@$(MAKE) url

# Commande principale : tout en une fois
all: build deploy
	@echo ""
	@echo "Application déployée !"

# État de toutes les ressources
status:
	@echo "=== Nodes ==="
	@kubectl get nodes
	@echo ""
	@echo "=== Pods ==="
	@kubectl get pods -n items-app -o wide
	@echo ""
	@echo "=== Services ==="
	@kubectl get services -n items-app
	@echo ""
	@echo "=== PVC ==="
	@kubectl get pvc -n items-app

# Logs de l'API en temps réel
logs:
	@kubectl logs -l app=items-api -n items-app --tail=50 -f

# Affiche l'URL d'accès
url:
	@echo ""
	@echo "======================================="
	@echo "  URL : http://localhost:30080"
	@echo "  Swagger : http://localhost:30080/docs"
	@echo "  Health  : http://localhost:30080/health"
	@echo "======================================="

# Redémarre l'API
restart:
	@kubectl rollout restart deployment/items-api -n items-app
	@kubectl rollout status deployment/items-api -n items-app

# Supprime toutes les ressources
clean:
	@echo "Suppression des ressources..."
	@kubectl delete namespace items-app --ignore-not-found=true
	@echo "Nettoyage terminé !"