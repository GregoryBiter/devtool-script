#!/usr/bin/env bash
# @name Docker Clean
# @description Очистить неиспользуемые контейнеры, сети и dangling-образы (docker system prune)
# @usage dev docker clean [--all]
# @dangerous true

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен или недоступен в PATH." >&2
    exit 1
fi

FLAGS="-f"
if [[ "${1:-}" == "--all" ]] || [[ "${1:-}" == "-a" ]]; then
    FLAGS="-a -f"
    echo "⚠️  Режим --all: будут удалены все неиспользуемые образы, а не только dangling."
fi

echo "==> Очистка Docker ресурсов..."
docker system prune $FLAGS

echo
echo "==> Использование диска Docker после очистки:"
docker system df
echo
echo "✔ Очистка Docker успешно завершена."
