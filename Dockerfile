# ---- Stage 1 : builder ----
# On part d'une image Python légère
FROM python:3.11-slim AS builder

WORKDIR /app

# On copie UNIQUEMENT requirements.txt en premier
# Astuce : si le code change mais pas les dépendances,
# Docker réutilise le cache et ne réinstalle pas tout
COPY app/requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ---- Stage 2 : image finale ----
# image propre sans les outils de build
FROM python:3.11-slim

WORKDIR /app

# ne pas tourner en root
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup appuser

# Copie les librairies installées depuis le stage builder
COPY --from=builder /usr/local/lib/python3.11/site-packages \
    /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn

# Copie le code applicatif
COPY app/ .

# droits à notre utilisateur non-root
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

