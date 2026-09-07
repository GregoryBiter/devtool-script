#!/usr/bin/env bash
# uninstall.sh - Скрипт удаления символических ссылок DevTool CLI

set -e

echo "==> Удаление DevTool CLI..."

REMOVED=0

for path in "/usr/local/bin/dev" "$HOME/.local/bin/dev"; do
    if [[ -L "$path" ]] || [[ -f "$path" ]]; then
        if [[ -w "$(dirname "$path")" ]] || [[ $EUID -eq 0 ]]; then
            rm -f "$path"
            echo "✔ Удалена ссылка: $path"
            REMOVED=1
        elif command -v sudo >/dev/null 2>&1; then
            sudo rm -f "$path"
            echo "✔ Удалена ссылка: $path (через sudo)"
            REMOVED=1
        fi
    fi
done

if [[ $REMOVED -eq 0 ]]; then
    echo "ℹ Символические ссылки dev не найдены в стандартных путях."
else
    echo
    echo "✔ DevTool CLI успешно удален из системы."
fi
