#!/usr/bin/env bash
# @name Git Reset Main
# @description Жестко сбросить ветку main (или master) к состоянию origin с удалением изменений
# @usage dev git reset-main
# @dangerous true

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

MAIN_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        MAIN_BRANCH="master"
    fi
fi

echo "==> Жесткий сброс ветки '$MAIN_BRANCH' к origin/$MAIN_BRANCH..."

echo "--> git fetch origin..."
git fetch origin "$MAIN_BRANCH"

echo "--> git checkout $MAIN_BRANCH..."
git checkout "$MAIN_BRANCH"

echo "--> git reset --hard origin/$MAIN_BRANCH..."
git reset --hard "origin/$MAIN_BRANCH"

echo
echo "✔ Ветка $MAIN_BRANCH полностью синхронизирована с origin/$MAIN_BRANCH!"
