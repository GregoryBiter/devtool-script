#!/usr/bin/env bash
# @name Server Permissions
# @description Выставить безопасные права доступа для файлов проекта (755/644, storage 775)
# @usage dev server permissions [директория]
# @dangerous true

set -e

TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "✖ Ошибка: директория '$TARGET_DIR' не существует." >&2
    exit 1
fi

echo "==> 🔒 Настройка прав доступа для: $TARGET_DIR"

echo "--> Установка 755 для директорий..."
find "$TARGET_DIR" -type d -exec chmod 755 {} +

echo "--> Установка 644 для файлов..."
find "$TARGET_DIR" -type f -exec chmod 644 {} +

if [[ -d "$TARGET_DIR/bin" ]]; then
    chmod -R +x "$TARGET_DIR/bin" || true
fi
if [[ -d "$TARGET_DIR/scripts" ]]; then
    find "$TARGET_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} + || true
fi

if [[ -d "$TARGET_DIR/storage" ]]; then
    echo "--> Настройка прав на storage (775)..."
    chmod -R 775 "$TARGET_DIR/storage"
fi
if [[ -d "$TARGET_DIR/bootstrap/cache" ]]; then
    echo "--> Настройка прав на bootstrap/cache (775)..."
    chmod -R 775 "$TARGET_DIR/bootstrap/cache"
fi

echo
echo "✔ Права доступа успешно скорректированы."
