#!/usr/bin/env bash
# @name Server Deploy
# @description Базовый сценарий деплоя: git pull, сборка зависимостей, миграции и кэш
# @usage dev server deploy [branch]
# @dangerous true

set -e

BRANCH="${1:-main}"

echo "==> 🚀 Старт процесса деплоя для ветки: $BRANCH"
echo

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "--> [1/5] Синхронизация кода из Git..."
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
    git pull --ff-only origin "$BRANCH"
else
    echo "--> [1/5] Пропуск Git (директория не является git-репозиторием)."
fi

if [[ -f "composer.json" ]] && command -v composer >/dev/null 2>&1; then
    echo "--> [2/5] Установка PHP зависимостей (composer install)..."
    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
fi

if [[ -f "package.json" ]]; then
    echo "--> [3/5] Сборка фронтенд-ассетов..."
    if command -v pnpm >/dev/null 2>&1 && [[ -f "pnpm-lock.yaml" ]]; then
        pnpm install --frozen-lockfile
        pnpm run build || true
    elif command -v npm >/dev/null 2>&1; then
        npm ci || npm install
        npm run build || true
    fi
fi

if [[ -f "artisan" ]] && command -v php >/dev/null 2>&1; then
    echo "--> [4/5] Применение миграций и оптимизация кэша Laravel..."
    php artisan migrate --force
    php artisan optimize
fi

if [[ -f "artisan" ]] && command -v php >/dev/null 2>&1; then
    echo "--> [5/5] Перезапуск Laravel queue worker..."
    php artisan queue:restart || true
fi

echo
echo "✔ Деплой успешно завершен!"
