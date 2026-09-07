#!/usr/bin/env bash
# @name Docker Status
# @description Показать запущенные контейнеры, порты и использование памяти
# @usage dev docker ps
# @dangerous false

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен." >&2
    exit 1
fi

echo "==> 🐳 Список контейнеров:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo

echo "==> 📊 Использование ресурсов (stats):"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" || true
