#!/usr/bin/env bash
# @name Laravel Migrate
# @description Выполнить миграции базы данных
# @usage dev laravel migrate [--seed]
# @dangerous false

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

echo "==> 🗄 Выполнение миграций..."
$ARTISAN_CMD migrate "$@"

echo
echo "✔ Миграции успешно применены."
