#!/usr/bin/env bash
# install.sh - Скрипт установки DevTool CLI

set -e

REPO_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_SOURCE="$REPO_DIR/bin/dev"

echo "======================================================"
echo "          🚀 Установка DevTool CLI Launcher          "
echo "======================================================"
echo

# 1. Проверка версии Bash
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "✖ Ошибка: Требуется Bash версии 4.0 или выше (у вас $BASH_VERSION)." >&2
    exit 1
fi

# 2. Выставление прав на исполнение
echo "--> Выставление прав на исполнение файлов..."
chmod +x "$BIN_SOURCE" "$REPO_DIR/lib/utils.sh"
find "$REPO_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "$REPO_DIR/install.sh" "$REPO_DIR/uninstall.sh" 2>/dev/null || true

# 3. Определение целевого каталога для symlink
TARGET_DIR="/usr/local/bin"
USE_SUDO=0

if [[ ! -w "$TARGET_DIR" ]] && [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        echo "ℹ Для создания глобальной ссылки в /usr/local/bin/dev требуются права sudo."
        USE_SUDO=1
    else
        TARGET_DIR="$HOME/.local/bin"
        mkdir -p "$TARGET_DIR"
    fi
fi

if [[ "${1:-}" == "--user" ]]; then
    TARGET_DIR="$HOME/.local/bin"
    mkdir -p "$TARGET_DIR"
    USE_SUDO=0
fi

TARGET_LINK="$TARGET_DIR/dev"

echo "--> Создание символической ссылки: $TARGET_LINK -> $BIN_SOURCE..."

if [[ $USE_SUDO -eq 1 ]]; then
    sudo ln -sf "$BIN_SOURCE" "$TARGET_LINK"
else
    ln -sf "$BIN_SOURCE" "$TARGET_LINK"
fi

# 4. Проверка PATH если установка была в ~/.local/bin
if [[ "$TARGET_DIR" == "$HOME/.local/bin" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo
        echo "⚠️  Внимание: $HOME/.local/bin отсутствует в вашей переменной PATH."
        echo "Добавьте следующую строку в ~/.bashrc или ~/.zshrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

# 5. Проверка fzf
echo
if ! command -v fzf >/dev/null 2>&1; then
    echo "💡 Рекомендация:"
    echo "  Утилита 'fzf' не найдена. Лаунчер работает и со встроенным меню,"
    echo "  но с fzf доступен мгновенный интерактивный поиск с превью."
    echo "  Установить: sudo apt install fzf  (или brew install fzf)"
    echo
fi

echo "======================================================"
echo "✔ Установка завершена успешно!"
echo
echo "Теперь вы можете использовать команду:"
echo "  dev                     (интерактивное меню)"
echo "  dev list                (список всех команд)"
echo "  dev git sync            (запуск синхронизации git)"
echo "  dev doctor              (проверка готовности окружения)"
echo "======================================================"
