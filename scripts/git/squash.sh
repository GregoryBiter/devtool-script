#!/usr/bin/env bash
# @name Git Squash
# @description Объединить последние N коммитов в один (soft reset HEAD~N)
# @usage dev git squash [количество_коммитов]
# @dangerous true

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

COUNT="${1:-2}"

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 2 ]; then
    echo "✖ Ошибка: укажите число коммитов (минимум 2). Пример: dev git squash 3" >&2
    exit 1
fi

echo "==> Последние $COUNT коммитов, которые будут объединены:"
git log -n "$COUNT" --oneline
echo

git reset --soft "HEAD~$COUNT"

echo "✔ Выполнен git reset --soft HEAD~$COUNT."
echo "Все изменения объединены в staging-область."
echo "Теперь вы можете сделать один коммит: git commit -m 'Ваше сообщение'"
