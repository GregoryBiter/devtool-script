#!/usr/bin/env bash
# @name Git Log Graph
# @description Красивое древовидное отображение истории последних коммитов
# @usage dev git log [count]
# @dangerous false

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

COUNT="${1:-15}"

git log \
    --graph \
    --color=always \
    --abbrev-commit \
    --decorate \
    --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' \
    -n "$COUNT"
