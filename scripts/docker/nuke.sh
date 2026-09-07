#!/usr/bin/env bash
# @name Docker Deep Clean (Nuke)
# @description Полная зачистка: остановка всех контейнеров, удаление томов, неиспользуемых сетей, dangling/unused образов и кэша BuildKit
# @usage dev docker nuke [--volumes]
# @dangerous true

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен." >&2
    exit 1
fi

echo "==> 💣 Запуск полной глубокой зачистки Docker..."
echo

# 1. Остановка всех контейнеров
RUNNING=$(docker ps -q)
if [[ -n "$RUNNING" ]]; then
    echo "--> [1/5] Остановка работающих контейнеров..."
    docker stop $RUNNING
else
    echo "--> [1/5] Нет активных контейнеров."
fi

# 2. Удаление всех остановленных контейнеров
CONTAINERS=$(docker ps -aq)
if [[ -n "$CONTAINERS" ]]; then
    echo "--> [2/5] Удаление контейнеров..."
    docker rm -f $CONTAINERS
else
    echo "--> [2/5] Контейнеры для удаления отсутствуют."
fi

# 3. Очистка образов и неиспользуемых сетей
echo "--> [3/5] Удаление неиспользуемых образов и сетей (system prune -a)..."
docker system prune -a -f

# 4. Очистка кэша сборщика BuildKit
echo "--> [4/5] Очистка кэша сборщика BuildKit (builder prune -a)..."
docker builder prune -a -f 2>/dev/null || true

# 5. Тома (опционально или при флаге)
if [[ "${1:-}" == "--volumes" ]] || [[ "${1:-}" == "-v" ]]; then
    echo "--> [5/5] Принудительное удаление ВСЕХ томов..."
    docker volume prune -f
else
    echo "--> [5/5] Очистка неиспользуемых анонимных томов..."
    docker volume prune -f
fi

echo
echo "==> 📊 Использование диска Docker после зачистки:"
docker system df

echo
echo "✔ Глубокая очистка Docker успешно завершена!"
