#!/usr/bin/env bash
# @name Laravel Sail Full Setup
# @description Полный запуск проекта с нуля: установка Composer в Docker без локального PHP, .env, sail up, key:generate, sail npm install/build, migrate
# @usage dev laravel sail-setup
# @dangerous true

set -e

REPO_DIR="${DEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

if [[ ! -f "composer.json" ]]; then
    echo "✖ Ошибка: файл composer.json не найден. Перейдите в корень Laravel-проекта." >&2
    exit 1
fi

echo "================================================================"
echo "      ⛵ Полный запуск Laravel проекта через Laravel Sail      "
echo "================================================================"
echo

# 1. Проверка и создание .env
if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
        echo "--> [1/6] Создание файла конфигурации .env из .env.example..."
        cp .env.example .env
        echo "✔ Создан .env файл."
    else
        echo "⚠ Предупреждение: .env и .env.example не найдены."
    fi
else
    echo "--> [1/6] Файл .env уже существует."
fi

# 2. Установка Composer зависимостей без локального PHP на хосте
if [[ ! -f "./vendor/bin/sail" ]]; then
    echo "--> [2/6] Запуск Composer внутри временного Docker-контейнера..."
    bash "$REPO_DIR/scripts/laravel/sail-install.sh" --force
else
    echo "--> [2/6] Зависимости Composer уже установлены (./vendor/bin/sail найден)."
fi

if [[ ! -f "./vendor/bin/sail" ]]; then
    echo "✖ Ошибка: ./vendor/bin/sail не был создан. Проверьте вывод Composer." >&2
    exit 1
fi

# 3. Запуск контейнеров Sail
echo "--> [3/6] Запуск контейнеров Sail (sail up -d)..."
./vendor/bin/sail up -d
echo "Ожидание запуска служб..."
sleep 3

# 4. Генерация ключа приложения APP_KEY
if grep -q '^APP_KEY=\s*$' .env 2>/dev/null || ! grep -q '^APP_KEY=' .env 2>/dev/null; then
    echo "--> [4/6] Генерация ключа приложения (sail artisan key:generate)..."
    ./vendor/bin/sail artisan key:generate
else
    echo "--> [4/6] Ключ приложения APP_KEY уже установлен."
fi

# 5. Установка NPM зависимостей и сборка фронтенда через Sail
if [[ -f "package.json" ]]; then
    echo "--> [5/6] Установка NPM зависимостей и сборка через Sail..."
    ./vendor/bin/sail npm install
    ./vendor/bin/sail npm run build || true
else
    echo "--> [5/6] Файл package.json отсутствует, пропуск NPM."
fi

# 6. Применение миграций базы данных
echo "--> [6/6] Ожидание готовности БД и выполнение миграций..."
# Небольшая пауза для инициализации MySQL/PostgreSQL
for i in {1..30}; do
    if ./vendor/bin/sail artisan migrate --force 2>/dev/null; then
        echo "✔ Миграции успешно выполнены."
        break
    fi
    echo "  (база данных еще запускается, ожидание... $i/30)"
    sleep 2
done

APP_PORT=$(grep '^APP_PORT=' .env 2>/dev/null | cut -d= -f2 || echo "80")
[[ -z "$APP_PORT" ]] && APP_PORT="80"
URL="http://localhost"
[[ "$APP_PORT" != "80" ]] && URL="http://localhost:$APP_PORT"

echo
echo "================================================================"
echo "✔ Проект успешно запущен через Laravel Sail!"
echo "================================================================"
echo
echo "Статус контейнеров:"
./vendor/bin/sail ps
echo
echo "🌐 Приложение доступно по адресу: $URL"
echo
echo "Полезные команды:"
echo "  dev laravel sail-npm run dev   # Сборка ассетов в реальном времени (HMR)"
echo "  ./vendor/bin/sail stop         # Остановить контейнеры"
echo "  ./vendor/bin/sail artisan ...  # Вызов консоли Artisan"
echo
