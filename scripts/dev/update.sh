#!/usr/bin/env bash
# @name DevTool Update
# @description Обновить devtool-script до последней версии из Git-репозитория
# @usage dev update
# @dangerous false

set -e

REPO_DIR="${DEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

echo "==> 🚀 Обновление DevTool из Git..."
echo "  Каталог: $REPO_DIR"
echo

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: $REPO_DIR не является Git-репозиторием." >&2
    exit 1
fi

BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
OLD_HASH=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "--> git fetch origin $BRANCH..."
git -C "$REPO_DIR" fetch origin "$BRANCH" --prune

REMOTE_HASH=$(git -C "$REPO_DIR" rev-parse --short "origin/$BRANCH" 2>/dev/null || echo "unknown")

if [[ "$OLD_HASH" == "$REMOTE_HASH" ]]; then
    echo "✔ У вас уже установлена самая актуальная версия ($OLD_HASH)."
else
    echo "--> Применение обновлений ($OLD_HASH -> $REMOTE_HASH)..."
    git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
    echo
    echo "Новые изменения:"
    git -C "$REPO_DIR" log --oneline "${OLD_HASH}..${REMOTE_HASH}" || true
    echo
fi

echo "--> Проверка прав на исполнение..."
chmod +x "$REPO_DIR/bin/dev" "$REPO_DIR/lib/utils.sh"
find "$REPO_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "$REPO_DIR/install.sh" "$REPO_DIR/uninstall.sh" 2>/dev/null || true

echo
echo "✔ DevTool готов к работе (версия: $(git -C "$REPO_DIR" rev-parse --short HEAD))."
