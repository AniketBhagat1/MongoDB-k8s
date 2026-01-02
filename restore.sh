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

BACKUP_FILE="$1"

# =========================
# VALIDATION
# =========================
if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Usage: $0 <backup-file-path>"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

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
# RESTORE
# =========================
echo "♻️ Starting MongoDB restore..."

cat "$BACKUP_FILE" | kubectl exec -i -n "$NAMESPACE" -c mongo "$PRIMARY_POD" -- \
mongorestore \
  -u "$MONGO_USER" \
  -p "$MONGO_PASSWORD" \
  --authenticationDatabase "$AUTH_DB" \
  --archive \
  --gzip \
  --drop

echo "✅ Restore completed successfully"

