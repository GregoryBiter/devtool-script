#!/usr/bin/env bash
# @name Laravel Hard Reset
# @description Полный перезапуск приложения: down, composer dump-autoload, очистка bootstrap/cache, migrate:fresh --seed, storage:link, права 775, up
# @usage dev laravel reset
# @dangerous true

set -e

ARTISAN_CMD=""
if [[ -f "./vendor/bin/sail" ]]; then
    ARTISAN_CMD="./vendor/bin/sail artisan"
elif [[ -f "./artisan" ]]; then
    ARTISAN_CMD="php artisan"
else
    echo "✖ Ошибка: файл artisan не найден. Перейдите в корень Laravel-проекта." >&2
    exit 1
fi

echo "==> ⚡ Запуск полного глубокого перезапуска Laravel проекта..."
echo "  Исполнитель: $ARTISAN_CMD"
echo

# 1. Включение режима обслуживания
echo "--> [1/8] Перевод приложения в режим обслуживания (down)..."
$ARTISAN_CMD down || true

# 2. Очистка кэшей и скомпилированных классов
echo "--> [2/8] Очистка всех кэшей и файлов bootstrap/cache..."
$ARTISAN_CMD optimize:clear
rm -f bootstrap/cache/*.php 2>/dev/null || true

# 3. Пересборка composer autoload (если доступен)
if command -v composer >/dev/null 2>&1 && [[ -f "composer.json" ]]; then
    echo "--> [3/8] Оптимизация автозагрузки Composer (dump-autoload)..."
    composer dump-autoload -o
fi

# 4. Пересоздание базы данных с запуском сидеров
echo "--> [4/8] Полный сброс БД и заполнение данными (migrate:fresh --seed)..."
$ARTISAN_CMD migrate:fresh --seed --force

# 5. Проверка симлинка хранилища
echo "--> [5/8] Проверка символической ссылки хранилища (storage:link)..."
$ARTISAN_CMD storage:link || true

# 6. Перезапуск очередей
echo "--> [6/8] Перезапуск фоновых очередей (queue:restart)..."
$ARTISAN_CMD queue:restart || true

# 7. Права доступа на storage и bootstrap/cache
echo "--> [7/8] Корректировка прав на storage и bootstrap/cache (775)..."
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# 8. Выход из режима обслуживания
echo "--> [8/8] Включение приложения (up)..."
$ARTISAN_CMD up

echo
echo "✔ Laravel-окружение полностью сброшено, оптимизировано и запущено!"
