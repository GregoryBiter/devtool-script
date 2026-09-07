#!/usr/bin/env bash
# uninstall.sh - Скрипт удаления DevTool CLI и символических ссылок

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

if [[ -d "$HOME/.devtools" ]]; then
    if [[ "${1:-}" == "--purge" ]] || [[ "${1:-}" == "-f" ]]; then
        rm -rf "$HOME/.devtools"
        echo "✔ Каталог $HOME/.devtools удален."
    elif [[ -t 0 ]]; then
        read -r -p "Удалить каталог репозитория $HOME/.devtools? [y/N]: " del_repo
        if [[ "$del_repo" =~ ^[yYдД] ]]; then
            rm -rf "$HOME/.devtools"
            echo "✔ Каталог $HOME/.devtools удален."
        fi
    fi
fi

if [[ $REMOVED -eq 0 ]]; then
    echo "ℹ Символические ссылки dev не найдены в стандартных путях."
else
    echo
    echo "✔ DevTool CLI успешно удален из системы."
fi
