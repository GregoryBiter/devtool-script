#!/usr/bin/env bash
# @name Docker Stop All
# @description Остановить все запущенные Docker-контейнеры
# @usage dev docker stop-all
# @dangerous true

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен." >&2
    exit 1
fi

RUNNING=$(docker ps -q)

if [[ -z "$RUNNING" ]]; then
    echo "ℹ Нет запущенных контейнеров."
    exit 0
fi

echo "==> Остановка контейнеров:"
docker stop $RUNNING

echo
echo "✔ Все контейнеры успешно остановлены."
