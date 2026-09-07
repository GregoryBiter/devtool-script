#!/usr/bin/env bash
# @name Laravel Reset
# @description Полный сброс БД и кэшей: migrate:fresh --seed и optimize:clear
# @usage dev laravel reset
# @dangerous true

set -e

ARTISAN_CMD=""
if [[ -f "./vendor/bin/sail" ]]; then
    ARTISAN_CMD="./vendor/bin/sail artisan"
elif [[ -f "./artisan" ]]; then
    ARTISAN_CMD="php artisan"
else
    echo "✖ Ошибка: файл artisan не найден. Убедитесь, что находитесь в корне Laravel-проекта." >&2
    exit 1
fi

echo "==> ⚡ Полный сброс окружения Laravel..."
echo "  Исполнитель: $ARTISAN_CMD"
echo

echo "--> Очистка всех кэшей..."
$ARTISAN_CMD optimize:clear

echo "--> Пересоздание базы данных и запуск сидеров (migrate:fresh --seed)..."
$ARTISAN_CMD migrate:fresh --seed --force

echo "--> Проверка символической ссылки storage..."
$ARTISAN_CMD storage:link || true

echo
echo "✔ Laravel проект успешно сброшен и подготовлен к работе!"
