#!/usr/bin/env bash
# @name Laravel Sail NPM Runner
# @description Выполнить команды NPM (install, dev, build) внутри рабочего окружения Laravel Sail
# @usage dev laravel sail-npm [аргументы_npm...]
# @dangerous false

set -e

if [[ ! -f "./vendor/bin/sail" ]]; then
    echo "✖ Ошибка: ./vendor/bin/sail не найден." >&2
    echo "  Сначала установите зависимости через: dev laravel sail-install" >&2
    exit 1
fi

# Проверка, запущен ли Sail
if ! ./vendor/bin/sail ps 2>/dev/null | grep -q "running"; then
    echo "ℹ Контейнеры Sail не запущены. Запускаем: ./vendor/bin/sail up -d..."
    ./vendor/bin/sail up -d
    sleep 2
fi

if [[ $# -eq 0 ]]; then
    echo "==> 📦 Запуск установки NPM зависимостей и сборки ассетов через Sail..."
    echo "--> ./vendor/bin/sail npm install..."
    ./vendor/bin/sail npm install

    echo "--> ./vendor/bin/sail npm run build..."
    ./vendor/bin/sail npm run build || true
    echo
    echo "✔ Фронтенд успешно собран через Laravel Sail."
    echo "💡 Для сборки на лету используйте: dev laravel sail-npm run dev"
else
    echo "==> 🚀 Выполнение в Sail: npm $*"
    ./vendor/bin/sail npm "$@"
fi
