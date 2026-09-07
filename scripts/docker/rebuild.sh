#!/usr/bin/env bash
# @name Docker Rebuild
# @description Пересобрать и перезапустить контейнеры через Docker Compose без кэша
# @usage dev docker rebuild [service]
# @dangerous false

set -e

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo "✖ Ошибка: Docker Compose не найден." >&2
    exit 1
fi

SERVICE="${1:-}"

if [[ -n "$SERVICE" ]]; then
    echo "==> 🔄 Пересборка отдельного сервиса: $SERVICE"
    $COMPOSE_CMD stop "$SERVICE" || true
    $COMPOSE_CMD rm -f "$SERVICE" || true
    $COMPOSE_CMD build --no-cache "$SERVICE"
    $COMPOSE_CMD up -d "$SERVICE"
else
    echo "==> 🔄 Полная пересборка Docker Compose проекта..."
    $COMPOSE_CMD down --remove-orphans || true
    $COMPOSE_CMD build --no-cache
    $COMPOSE_CMD up -d
fi

echo
echo "✔ Контейнеры успешно пересобраны и запущены:"
$COMPOSE_CMD ps
