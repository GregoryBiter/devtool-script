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

echo "--> git fetch origin..."
git -C "$REPO_DIR" fetch origin

echo "--> git pull --ff-only origin $BRANCH..."
git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"

echo "--> Обновление прав на исполнение..."
chmod +x "$REPO_DIR/bin/dev" "$REPO_DIR/lib/utils.sh"
find "$REPO_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +

echo
echo "✔ DevTool успешно обновлен до актуальной версии!"
