#!/usr/bin/env bash
# install.sh - Универсальный скрипт автоматической установки и обновления DevTool CLI
# Поддерживает как локальный запуск, так и однострочный запуск через curl:
#   curl -fsSL https://raw.githubusercontent.com/GregoryBiter/devtool-script/main/install.sh | bash

set -e

# --- Цвета для вывода ---
if [[ -t 1 ]] || [[ -n "${FORCE_COLOR:-}" ]]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_CYAN="\033[36m"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_CYAN=""
fi

log_info()    { echo -e "${C_CYAN}ℹ${C_RESET} $*"; }
log_success() { echo -e "${C_GREEN}✔${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
log_step()    { echo -e "${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }

GITHUB_REPO="https://github.com/GregoryBiter/devtool-script.git"
DEFAULT_INSTALL_DIR="$HOME/.devtools"

echo
echo -e "${C_BOLD}${C_CYAN}╔════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}║             🚀 DevTool CLI — Автоустановщик                ║${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}╚════════════════════════════════════════════════════════════╝${C_RESET}"
echo

# 1. Проверка системных требований: Git и Bash 4+
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    log_error "Требуется Bash версии 4.0 или выше (у вас $BASH_VERSION)."
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    log_error "Git не найден. Пожалуйста, установите Git перед продолжением:"
    echo "  sudo apt install git   # Debian/Ubuntu"
    echo "  brew install git      # macOS"
    exit 1
fi

# 2. Определение режима запуска (локальный или удаленный через curl/pipe)
IS_PIPED=0
if [[ -z "${BASH_SOURCE[0]:-}" ]] || [[ "${BASH_SOURCE[0]}" == "-" ]] || [[ "${BASH_SOURCE[0]}" == "/dev/fd/"* ]] || [[ "${BASH_SOURCE[0]}" == *"/stdin"* ]]; then
    IS_PIPED=1
fi

CURRENT_DIR=""
if [[ $IS_PIPED -eq 0 ]]; then
    CURRENT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi

# Проверка, находимся ли мы уже внутри репозитория devtool-script
if [[ -n "$CURRENT_DIR" ]] && [[ -f "$CURRENT_DIR/bin/dev" ]] && [[ -d "$CURRENT_DIR/scripts" ]]; then
    REPO_DIR="$CURRENT_DIR"
    log_info "Используется локальная директория репозитория: ${C_BOLD}$REPO_DIR${C_RESET}"
else
    # Режим установки через curl или из внешней папки
    REPO_DIR="${DEVTOOL_DIR:-$DEFAULT_INSTALL_DIR}"

    if [[ -d "$REPO_DIR/.git" ]] && [[ -f "$REPO_DIR/bin/dev" ]]; then
        log_step "DevTool уже установлен в $REPO_DIR. Выполняем обновление через Git..."
        git -C "$REPO_DIR" fetch origin
        BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        git -C "$REPO_DIR" pull --ff-only origin "$BRANCH" || {
            log_warn "Не удалось выполнить fast-forward pull. Пробуем переключиться на origin/main..."
            git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
        }
        log_success "Репозиторий успешно обновлен."
    elif [[ -d "$REPO_DIR" ]] && [[ ! -d "$REPO_DIR/.git" ]]; then
        log_error "Каталог $REPO_DIR уже существует, но не является Git-репозиторием."
        echo "Пожалуйста, удалите или переименуйте его, либо укажите другую папку через DEVTOOL_DIR."
        exit 1
    else
        log_step "Клонирование репозитория DevTool из GitHub..."
        mkdir -p "$(dirname "$REPO_DIR")"
        git clone "$GITHUB_REPO" "$REPO_DIR"
        log_success "Репозиторий успешно склонирован в $REPO_DIR"
    fi
fi

BIN_SOURCE="$REPO_DIR/bin/dev"

if [[ ! -f "$BIN_SOURCE" ]]; then
    log_error "Файл исполнителя $BIN_SOURCE не найден. Ошибка целостности установки."
    exit 1
fi

# 3. Выставление прав на исполнение
log_step "Настройка прав доступа..."
chmod +x "$BIN_SOURCE" "$REPO_DIR/lib/utils.sh"
find "$REPO_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "$REPO_DIR/install.sh" "$REPO_DIR/uninstall.sh" 2>/dev/null || true
log_success "Права доступа выставлены."

# 4. Выбор каталога для символической ссылки
TARGET_DIR=""
USE_SUDO=0

if [[ "${1:-}" == "--global" ]] || [[ "${1:-}" == "-g" ]]; then
    TARGET_DIR="/usr/local/bin"
    if [[ $EUID -ne 0 ]] && [[ ! -w "$TARGET_DIR" ]]; then
        USE_SUDO=1
    fi
elif [[ $EUID -eq 0 ]] || [[ -w "/usr/local/bin" ]]; then
    # Если запущен под root или каталог доступен на запись
    TARGET_DIR="/usr/local/bin"
    USE_SUDO=0
else
    # Стандартный путь пользователя (не требует sudo, безопасно для curl | bash)
    TARGET_DIR="$HOME/.local/bin"
    USE_SUDO=0
fi

mkdir -p "$TARGET_DIR"
TARGET_LINK="$TARGET_DIR/dev"

log_step "Создание символической ссылки: ${C_CYAN}$TARGET_LINK${C_RESET} -> ${C_DIM}$BIN_SOURCE${C_RESET}..."

if [[ $USE_SUDO -eq 1 ]]; then
    sudo ln -sf "$BIN_SOURCE" "$TARGET_LINK"
else
    ln -sf "$BIN_SOURCE" "$TARGET_LINK"
fi
log_success "Символическая ссылка создана в $TARGET_LINK"

# 5. Автоматическая настройка PATH, если выбран ~/.local/bin
if [[ "$TARGET_DIR" == "$HOME/.local/bin" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_step "Настройка переменной PATH в профиле оболочки..."
        
        # Определяем файл конфигурации пользователя
        TARGET_RC=""
        if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" =~ "zsh" ]]; then
            TARGET_RC="$HOME/.zshrc"
        elif [[ -f "$HOME/.bashrc" ]]; then
            TARGET_RC="$HOME/.bashrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            TARGET_RC="$HOME/.bash_profile"
        elif [[ -f "$HOME/.profile" ]]; then
            TARGET_RC="$HOME/.profile"
        fi

        if [[ -n "$TARGET_RC" ]]; then
            if ! grep -q "PATH=.*$HOME/\.local/bin" "$TARGET_RC" 2>/dev/null; then
                echo "" >> "$TARGET_RC"
                echo "# DevTool CLI" >> "$TARGET_RC"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$TARGET_RC"
                log_success "Строка экспорта PATH добавлена в $TARGET_RC"
            fi
        fi
        
        export PATH="$HOME/.local/bin:$PATH"
        log_warn "Чтобы команда 'dev' стала доступна в текущей вкладке терминала, выполните:"
        echo -e "     ${C_BOLD}${C_GREEN}source ${TARGET_RC:-~/.bashrc}${C_RESET}   (или перезапустите терминал)"
    fi
fi

# 6. Проверка fzf
echo
if ! command -v fzf >/dev/null 2>&1; then
    echo -e "${C_YELLOW}💡 Рекомендация:${C_RESET}"
    echo "   Утилита 'fzf' не найдена. Лаунчер полностью работает и без нее,"
    echo "   но с fzf доступен мгновенный интерактивный поиск команд с живым превью."
    echo -e "   Установить: ${C_BOLD}sudo apt install fzf${C_RESET} (Debian/Ubuntu) или ${C_BOLD}brew install fzf${C_RESET} (macOS)"
    echo
fi

echo -e "${C_BOLD}${C_GREEN}════════════════════════════════════════════════════════════${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}✔ DevTool CLI успешно установлен и готов к работе!${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}════════════════════════════════════════════════════════════${C_RESET}"
echo
echo -e "Доступные команды:"
echo -e "  ${C_CYAN}dev${C_RESET}                     — интерактивное меню (поиск и запуск)"
echo -e "  ${C_CYAN}dev list${C_RESET}                — список всех доступных команд"
echo -e "  ${C_CYAN}dev git sync${C_RESET}            — синхронизация репозитория git"
echo -e "  ${C_CYAN}dev update${C_RESET}              — автоматическое обновление devtool через Git"
echo -e "  ${C_CYAN}dev doctor${C_RESET}              — проверка системных зависимостей"
echo
