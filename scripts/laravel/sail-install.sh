#!/usr/bin/env bash
# @name Laravel Sail Composer Bootstrap
# @description Установить composer-зависимости через временный Docker-контейнер без локального PHP на хосте
# @usage dev laravel sail-install [--force]
# @dangerous false

set -e

if [[ ! -f "composer.json" ]]; then
    echo "✖ Ошибка: файл composer.json не найден. Перейдите в корень Laravel-проекта." >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен или недоступен." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker демон не запущен. Запустите службу Docker." >&2
    exit 1
fi

if [[ -f "./vendor/bin/sail" ]] && [[ "${1:-}" != "--force" ]] && [[ "${1:-}" != "-f" ]]; then
    echo "✔ Laravel Sail уже установлен в ./vendor/bin/sail."
    echo "  (Используйте 'dev laravel sail-install --force' для принудительной переустановки)"
    exit 0
fi

echo "==> 🐳 Установка Composer зависимостей через Docker (без локального PHP на хосте)..."

# Определение требуемой версии PHP из composer.json
PHP_VER="83"
if grep -q '"php":\s*"[^"]*8\.4' composer.json 2>/dev/null; then
    PHP_VER="84"
elif grep -q '"php":\s*"[^"]*8\.2' composer.json 2>/dev/null; then
    PHP_VER="82"
elif grep -q '"php":\s*"[^"]*8\.1' composer.json 2>/dev/null; then
    PHP_VER="81"
fi

IMAGE="laravelsail/php${PHP_VER}-composer:latest"
echo "  Используемый образ: $IMAGE (PHP $PHP_VER)"
echo "  Пользователь: $(id -u):$(id -g)"
echo

echo "--> Запуск контейнера composer install..."
docker run --rm \
    --interactive \
    --tty \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    "$IMAGE" \
    composer install --ignore-platform-reqs || {
        echo "⚠ Не удалось использовать $IMAGE. Пробуем резервный образ composer:lts..."
        docker run --rm \
            --interactive \
            --tty \
            -u "$(id -u):$(id -g)" \
            -v "$(pwd):/var/www/html" \
            -w /var/www/html \
            composer:lts \
            composer install --ignore-platform-reqs
    }

if [[ -f "./vendor/bin/sail" ]]; then
    echo
    echo "✔ Зависимости Composer успешно установлены!"
    echo "  Файл ./vendor/bin/sail готов к запуску."
else
    echo
    echo "⚠ Composer завершил работу, но ./vendor/bin/sail не найден."
    echo "  Возможно, пакет laravel/sail не указан в composer.json."
fi
