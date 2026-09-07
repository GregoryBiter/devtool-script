#!/usr/bin/env bash
# @name DevTool Doctor
# @description Проверить системные утилиты, зависимости и права доступа devtool
# @usage dev doctor
# @dangerous false

set -e

REPO_DIR="${DEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

echo "==> 🩺 Проверка окружения DevTool"
echo

check_tool() {
    local name="$1"
    local required="$2"
    local desc="$3"

    if command -v "$name" >/dev/null 2>&1; then
        local ver
        ver=$("$name" --version 2>/dev/null | head -n 1 || echo "установлен")
        printf "  \033[1;32m✔\033[0m \033[1m%-12s\033[0m (%s)\n" "$name" "$ver"
    else
        if [[ "$required" == "true" ]]; then
            printf "  \033[1;31m✖\033[0m \033[1m%-12s\033[0m \033[31mНЕ НАЙДЕН (обязательно): %s\033[0m\n" "$name" "$desc"
        else
            printf "  \033[1;33m⚠\033[0m \033[1m%-12s\033[0m \033[33mне установлен (опционально): %s\033[0m\n" "$name" "$desc"
        fi
    fi
}

echo "Базовые утилиты:"
check_tool "bash" "true" "Оболочка (версия 4+)"
check_tool "git" "true" "Система контроля версий"
check_tool "fzf" "false" "Интерактивный нечеткий поиск (рекомендуется: sudo apt install fzf)"
echo

echo "Окружение разработки:"
check_tool "docker" "false" "Контейнеризация"
check_tool "php" "false" "PHP для Laravel команд"
check_tool "composer" "false" "Пакетный менеджер PHP"
check_tool "node" "false" "Node.js для сборки фронтенда"
check_tool "npm" "false" "Пакетный менеджер Node.js"
echo

echo "Каталоги скриптов:"
if [[ -d "$REPO_DIR/scripts" ]]; then
    TOTAL=$(find "$REPO_DIR/scripts" -type f -name "*.sh" | wc -l)
    echo -e "  \033[1;32m✔\033[0m Базовые скрипты: $REPO_DIR/scripts (найдено: $TOTAL)"
else
    echo -e "  \033[1;31m✖\033[0m Базовые скрипты не найдены в $REPO_DIR/scripts"
fi

if [[ -d "$HOME/.config/devtool/scripts" ]]; then
    U_TOTAL=$(find "$HOME/.config/devtool/scripts" -type f -name "*.sh" 2>/dev/null | wc -l)
    echo -e "  \033[1;32m✔\033[0m Пользовательские скрипты: ~/.config/devtool/scripts (найдено: $U_TOTAL)"
fi

if [[ -d "$PWD/.dev/scripts" ]] || [[ -d "$PWD/.dev" ]]; then
    echo -e "  \033[1;32m✔\033[0m Локальные скрипты проекта обнаружены в $PWD"
fi

echo
echo "✔ Диагностика завершена."
