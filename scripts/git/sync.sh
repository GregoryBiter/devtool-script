#!/usr/bin/env bash
# @name Git Sync
# @description Синхронизировать текущую или указанную ветку с origin (fetch + pull --ff-only)
# @usage dev git sync [branch]
# @dangerous false

set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

TARGET_BRANCH="${1:-$CURRENT_BRANCH}"

echo "==> 🔄 Синхронизация репозитория..."
echo "  Текущая ветка: $CURRENT_BRANCH"
echo "  Целевая ветка: $TARGET_BRANCH"
echo

echo "--> git fetch origin --prune..."
git fetch origin --prune

if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
    echo "--> Переключение на $TARGET_BRANCH..."
    git checkout "$TARGET_BRANCH"
fi

echo "--> Обновление ветки $TARGET_BRANCH (fast-forward)..."
git pull --ff-only origin "$TARGET_BRANCH"

echo
echo "✔ Ветка $TARGET_BRANCH успешно синхронизирована с origin/$TARGET_BRANCH!"
