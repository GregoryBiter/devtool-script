#!/usr/bin/env bash
# @name Git Clean
# @description Удалить неотслеживаемые файлы и каталоги в репозитории (git clean -fd)
# @usage dev git clean [-x]
# @dangerous true

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

MODE="-fd"
if [[ "${1:-}" == "-x" ]] || [[ "${2:-}" == "-x" ]]; then
    MODE="-fdx"
    echo "⚠️  Режим -x: будут удалены также файлы из .gitignore!"
fi

echo "==> Неотслеживаемые файлы и директории:"
git status --short | grep '^[?]' || echo "  (неотслеживаемых файлов нет)"
echo

git clean $MODE
echo "✔ Рабочая копия очищена."
