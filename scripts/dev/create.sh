#!/usr/bin/env bash
# @name DevTool Create Script
# @description Создать шаблон нового скрипта с метаданными
# @usage dev dev create [category] [name]
# @dangerous false

set -e

REPO_DIR="${DEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

CATEGORY="${1:-}"
NAME="${2:-}"

if [[ -z "$CATEGORY" ]]; then
    echo -n "Введите категорию (например: git, docker, myproject): "
    read -r CATEGORY
fi

if [[ -z "$NAME" ]]; then
    echo -n "Введите имя команды (например: backup, deploy, test): "
    read -r NAME
fi

if [[ -z "$CATEGORY" ]] || [[ -z "$NAME" ]]; then
    echo "✖ Ошибка: категория и имя команды обязательны." >&2
    exit 1
fi

NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
CATEGORY=$(echo "$CATEGORY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

TARGET_DIR="$REPO_DIR/scripts/$CATEGORY"
TARGET_FILE="$TARGET_DIR/$NAME.sh"

if [[ -f "$TARGET_FILE" ]]; then
    echo "✖ Файл уже существует: $TARGET_FILE" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash
# @name __TITLE__
# @description Описание того, что делает этот сценарий
# @usage dev __CATEGORY__ __NAME__ [параметры]
# @dangerous false

set -e

echo "==> Выполнение __TITLE__..."

# Ваш код здесь:
# echo "Hello world!"

echo "✔ Завершено."
EOF

sed -i "s/__CATEGORY__/$CATEGORY/g" "$TARGET_FILE"
sed -i "s/__NAME__/$NAME/g" "$TARGET_FILE"
TITLE="$(tr '[:lower:]' '[:upper:]' <<< "${CATEGORY:0:1}")${CATEGORY:1} $(tr '[:lower:]' '[:upper:]' <<< "${NAME:0:1}")${NAME:1}"
sed -i "s/__TITLE__/$TITLE/g" "$TARGET_FILE"

chmod +x "$TARGET_FILE"

echo
echo "✔ Скрипт успешно создан:"
echo "  Путь:    $TARGET_FILE"
echo "  Команда: dev $CATEGORY $NAME"
echo
echo "Откройте файл в редакторе и настройте логику!"
