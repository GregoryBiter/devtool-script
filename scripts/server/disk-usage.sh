#!/usr/bin/env bash
# @name Find Disk Hogs
# @description Найти 15 самых тяжелых каталогов и файлов на диске без зависания на системных псевдо-ФС
# @usage dev server disk-usage [путь=/] [количество=15]
# @dangerous false

set -e

TARGET_PATH="${1:-.}"
COUNT="${2:-15}"

if [[ ! -e "$TARGET_PATH" ]]; then
    echo "✖ Ошибка: путь '$TARGET_PATH' не существует." >&2
    exit 1
fi

echo "==> 📊 Анализ использования диска для: $TARGET_PATH..."
echo "  Показываем топ-$COUNT самых крупных элементов (файлов и папок):"
echo

# Сканируем с флагом -x (одна файловая система, не лезть в /proc, /sys, nfs)
du -ahx "$TARGET_PATH" 2>/dev/null \
    | sort -rh \
    | head -n "$((COUNT + 1))" \
    | while read -r size path; do
        # Пропускаем сам корневой путь
        if [[ "$path" == "$TARGET_PATH" ]] || [[ "$path" == "." ]]; then
            continue
        fi
        
        TYPE="[файл]"
        [[ -d "$path" ]] && TYPE="[папка]"
        printf "  \033[1;33m%-10s\033[0m \033[2m%-8s\033[0m \033[1;36m%s\033[0m\n" "$size" "$TYPE" "$path"
    done

echo
echo "✔ Анализ завершен."
