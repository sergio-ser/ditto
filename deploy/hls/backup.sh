#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/apps/ditto}"
BACKUP_ROOT="${BACKUP_ROOT:-/apps/ditto-backups}"
COMPOSE_FILES=(-f docker-compose.lite.yaml -f deploy/hls/docker-compose.hls.yaml)
DATE="$(date +%F-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$DATE"

cd "$APP_DIR"
set -a
source .env
set +a

mkdir -p "$BACKUP_DIR"

# Logical Postgres backup, stored on the host machine.
docker compose "${COMPOSE_FILES[@]}" exec -T postgres \
  pg_dump -U "${DATABASE_USER:-postgres}" -d dittofeed -Fc \
  > "$BACKUP_DIR/postgres.dump"

# Safer filesystem backups for Docker volumes. This briefly stops the stack.
docker compose "${COMPOSE_FILES[@]}" stop

for volume in postgres clickhouse_lib clickhouse_log; do
  docker run --rm \
    -v "dittofeed_${volume}:/volume:ro" \
    -v "$BACKUP_DIR:/backup" \
    alpine tar -czf "/backup/${volume}.tar.gz" -C /volume .
done

docker compose "${COMPOSE_FILES[@]}" up -d

find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} \;

echo "Backup written to $BACKUP_DIR"
