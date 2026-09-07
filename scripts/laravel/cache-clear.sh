#!/usr/bin/env bash
# @name Laravel Cache Clear
# @description Очистить кэши: конфигурации, маршрутов, представлений и событий
# @usage dev laravel cache-clear
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

echo "==> 🧹 Очистка кэшей Laravel..."
$ARTISAN_CMD optimize:clear

echo
echo "✔ Все кэши успешно очищены."
