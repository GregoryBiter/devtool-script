#!/usr/bin/env bash
# @name Docker Database Dump
# @description Выгрузить дамп БД (MySQL / PostgreSQL / MariaDB) из работающего контейнера в сжатый .sql.gz файл на хосте
# @usage dev docker db-dump [имя_контейнера]
# @dangerous false

set -e

if ! command -v docker >/dev/null 2>&1; then
    echo "✖ Ошибка: Docker не установлен." >&2
    exit 1
fi

CONTAINER="${1:-}"

# Если контейнер не указан, ищем запущенные БД-контейнеры
if [[ -z "$CONTAINER" ]]; then
    DB_CONTAINERS=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && DB_CONTAINERS+=("$line")
    done < <(docker ps --format "{{.Names}}" | grep -Ei "(db|mysql|postgres|mariadb|mongo)" || true)

    if [[ ${#DB_CONTAINERS[@]} -eq 1 ]]; then
        CONTAINER="${DB_CONTAINERS[0]}"
        echo "ℹ Автоматически выбран контейнер БД: $CONTAINER"
    elif [[ ${#DB_CONTAINERS[@]} -gt 1 ]]; then
        echo "Найдено несколько контейнеров БД:"
        select c in "${DB_CONTAINERS[@]}"; do
            if [[ -n "$c" ]]; then
                CONTAINER="$c"
                break
            fi
        done
    else
        echo -n "Введите имя запущенного контейнера БД: "
        read -r CONTAINER
    fi
fi

if [[ -z "$CONTAINER" ]] || ! docker ps --format "{{.Names}}" | grep -qw "$CONTAINER"; then
    echo "✖ Ошибка: контейнер '$CONTAINER' не запущен." >&2
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="./dump_${CONTAINER}_${TIMESTAMP}.sql.gz"

echo "==> 🗄 Создание дампа из контейнера '$CONTAINER'..."

# Определение типа базы данных внутри контейнера
IMAGE_INFO=$(docker inspect --format '{{.Config.Image}}' "$CONTAINER")

if [[ "$IMAGE_INFO" =~ (mysql|mariadb) ]] || docker exec "$CONTAINER" which mysqldump >/dev/null 2>&1; then
    echo "  Тип: MySQL / MariaDB"
    USER_VAL=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" | grep '^MYSQL_USER=' | cut -d= -f2 || true)
    [[ -z "$USER_VAL" ]] && USER_VAL="root"
    
    PASS_VAL=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" | grep '^MYSQL_ROOT_PASSWORD=' | cut -d= -f2 || true)
    PASS_FLAG=""
    [[ -n "$PASS_VAL" ]] && PASS_FLAG="-p$PASS_VAL"

    docker exec "$CONTAINER" mysqldump -u"$USER_VAL" $PASS_FLAG --all-databases --single-transaction --quick | gzip > "$OUTPUT_FILE"

elif [[ "$IMAGE_INFO" =~ (postgres) ]] || docker exec "$CONTAINER" which pg_dumpall >/dev/null 2>&1; then
    echo "  Тип: PostgreSQL"
    USER_VAL=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" | grep '^POSTGRES_USER=' | cut -d= -f2 || true)
    [[ -z "$USER_VAL" ]] && USER_VAL="postgres"

    docker exec -e PGPASSWORD="$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" | grep '^POSTGRES_PASSWORD=' | cut -d= -f2 || true)" \
        "$CONTAINER" pg_dumpall -U "$USER_VAL" | gzip > "$OUTPUT_FILE"
else
    echo "✖ Не удалось автоматически распознать СУБД в контейнере (поддерживаются MySQL, MariaDB, Postgres)." >&2
    exit 1
fi

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo
echo "✔ Дамп успешно создан:"
echo "  Файл:   $OUTPUT_FILE"
echo "  Размер: $FILE_SIZE"
