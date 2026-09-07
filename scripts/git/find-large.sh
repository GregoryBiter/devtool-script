#!/usr/bin/env bash
# @name Git Find Large Files
# @description Найти самые тяжелые файлы во всей истории Git-репозитория и пакфайлах
# @usage dev git find-large [количество=10]
# @dangerous false

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

COUNT="${1:-10}"

echo "==> 🔍 Сканирование всей истории Git на наличие тяжелых объектов..."
echo "  Показываем топ-$COUNT файлов:"
echo

# Извлекаем все блобы, размеры и имена из всей истории коммитов
git rev-list --objects --all \
    | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
    | awk '/^blob/ {print $3, $2, $4}' \
    | sort -n -r \
    | head -n "$COUNT" \
    | while read -r bytes hash path; do
        if [[ -z "$path" ]]; then
            path="<удаленный файл или безымянный блоб>"
        fi
        # Переводим в человекочитаемый размер
        if [ "$bytes" -ge 1048576 ]; then
            size=$(awk -v b="$bytes" 'BEGIN {printf "%.2f MB", b/1048576}')
        elif [ "$bytes" -ge 1024 ]; then
            size=$(awk -v b="$bytes" 'BEGIN {printf "%.1f KB", b/1024}')
        else
            size="${bytes} B"
        fi

        printf "  \033[1;33m%-10s\033[0m \033[2m%s\033[0m  \033[1;36m%s\033[0m\n" "$size" "$hash" "$path"
    done

echo
echo "💡 Для удаления файла из истории используйте 'git-filter-repo' или BFG Repo-Cleaner."
