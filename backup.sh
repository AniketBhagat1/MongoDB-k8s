#!/bin/bash
set -e

# =========================
# CONFIGURATION
# =========================
NAMESPACE="mongodb"
APP_LABEL="app=mongo"

MONGO_USER="admin"
MONGO_PASSWORD="StrongPass123"
AUTH_DB="admin"

BACKUP_BASE_DIR="/opt/mongo-backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$BACKUP_BASE_DIR/backup-$TIMESTAMP"

# =========================
# FIND PRIMARY POD
# =========================
echo "🔍 Detecting MongoDB PRIMARY pod..."

PRIMARY_POD=$(
for pod in $(kubectl get pods -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec -n "$NAMESPACE" -c mongo "$pod" -- \
    mongosh -u "$MONGO_USER" -p "$MONGO_PASSWORD" \
    --authenticationDatabase "$AUTH_DB" \
    --quiet \
    --eval 'db.hello().isWritablePrimary' 2>/dev/null | grep -q true && echo "$pod" && break
done
)

if [ -z "$PRIMARY_POD" ]; then
  echo "❌ ERROR: Could not detect PRIMARY pod"
  exit 1
fi

echo "✅ PRIMARY pod detected: $PRIMARY_POD"

# =========================
# CREATE BACKUP DIR
# =========================
mkdir -p "$BACKUP_DIR"

# =========================
# RUN BACKUP
# =========================
echo "📦 Starting MongoDB backup..."

kubectl exec -n "$NAMESPACE" -c mongo "$PRIMARY_POD" -- \
mongodump \
  -u "$MONGO_USER" \
  -p "$MONGO_PASSWORD" \
  --authenticationDatabase "$AUTH_DB" \
  --oplog \
  --archive \
  --gzip \
> "$BACKUP_DIR/mongo-backup.gz"

echo "✅ Backup completed successfully"
echo "📂 Backup location: $BACKUP_DIR/mongo-backup.gz"

