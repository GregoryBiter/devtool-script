#!/usr/bin/env bash
# @name Laravel Tinker
# @description Запустить интерактивную консоль Laravel Tinker
# @usage dev laravel tinker
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

$ARTISAN_CMD tinker "$@"
