#!/usr/bin/env bash
# uninstall.sh — удалить ядро dev. Ваши скрипты (~/.dev-scripts) НЕ трогаются.
#   ./uninstall.sh            удалить ссылки dev
#   ./uninstall.sh --purge    + удалить ~/.devtools

set -euo pipefail

INSTALL_DIR="${DEVTOOL_DIR:-$HOME/.devtools}"

for link in "$HOME/.local/bin/dev" "/usr/local/bin/dev"; do
    [[ -L "$link" ]] || continue
    if [[ -w "$(dirname "$link")" ]]; then rm -f "$link"; else sudo rm -f "$link"; fi
    echo "✔ Удалено: $link"
done

if [[ "${1:-}" == "--purge" && -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    echo "✔ Удалено: $INSTALL_DIR"
fi

echo "ℹ Скрипты в ${DEV_SCRIPTS_HOME:-$HOME/.dev-scripts} оставлены как есть."
