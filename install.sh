#!/usr/bin/env bash
# install.sh — установка/обновление ядра dev.
#
#   curl -fsSL https://raw.githubusercontent.com/GregoryBiter/devtool-script/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --pack git@github.com:me/my-scripts.git
#   ./install.sh                # из локальной копии репозитория
#
# Флаги:
#   --pack <git-url>   сразу подключить пакет скриптов (можно несколько раз)
#   --global           ссылка в /usr/local/bin вместо ~/.local/bin

set -euo pipefail

REPO_URL="https://github.com/GregoryBiter/devtool-script.git"
INSTALL_DIR="${DEVTOOL_DIR:-$HOME/.devtools}"
SCRIPTS_HOME="${DEV_SCRIPTS_HOME:-$HOME/.dev-scripts}"

ok()   { echo -e "\033[32m✔\033[0m $*"; }
warn() { echo -e "\033[33m⚠\033[0m $*"; }
die()  { echo -e "\033[31m✖\033[0m $*" >&2; exit 1; }

PACKS=() GLOBAL=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pack)      PACKS+=("${2:?нужен URL}"); shift 2 ;;
        -g|--global) GLOBAL=1; shift ;;
        *) die "Неизвестный аргумент: $1" ;;
    esac
done

(( BASH_VERSINFO[0] >= 4 )) || die "Нужен Bash 4+ (у вас $BASH_VERSION). На macOS: brew install bash"
command -v git >/dev/null 2>&1 || die "Нужен git."

# 1. Ядро: локальная копия или клон в ~/.devtools
HERE=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -n "$HERE" && -f "$HERE/bin/dev" ]]; then
    ROOT="$HERE"
    ok "Ядро: локальная копия $ROOT"
elif [[ -d "$INSTALL_DIR/.git" ]]; then
    ROOT="$INSTALL_DIR"
    git -C "$ROOT" pull --ff-only -q || warn "Не удалось обновить $ROOT (локальные изменения?)"
    ok "Ядро обновлено: $ROOT"
else
    [[ -e "$INSTALL_DIR" ]] && die "$INSTALL_DIR уже существует и это не git-репозиторий."
    git clone -q "$REPO_URL" "$INSTALL_DIR"
    ROOT="$INSTALL_DIR"
    ok "Ядро установлено: $ROOT"
fi
chmod +x "$ROOT/bin/dev"

# 2. Ссылка dev в PATH
if [[ $GLOBAL == 1 ]]; then
    BIN_DIR="/usr/local/bin"
    SUDO=""; [[ -w "$BIN_DIR" ]] || SUDO="sudo"
    $SUDO ln -sf "$ROOT/bin/dev" "$BIN_DIR/dev"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    ln -sf "$ROOT/bin/dev" "$BIN_DIR/dev"
fi
ok "Команда: $BIN_DIR/dev"

SH="bash"; [[ "${SHELL:-}" == *zsh ]] && SH="zsh"
RC="$HOME/.${SH}rc"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]] && ! grep -qs "$BIN_DIR" "$RC"; then
    printf '\n# dev\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$RC"
    ok "PATH дописан в $RC"
fi
if ! grep -qs "dev completion" "$RC"; then
    printf '\n# dev: автодополнение по Tab\ncommand -v dev >/dev/null && eval "$(dev completion %s)"\n' "$SH" >> "$RC"
    ok "Автодополнение по Tab подключено в $RC"
fi
warn "Перезапустите терминал или выполните: source $RC"

# 3. Папка для пакетов скриптов
mkdir -p "$SCRIPTS_HOME"
ok "Скрипты: $SCRIPTS_HOME"
for url in "${PACKS[@]}"; do
    name="$(basename "$url" .git)"
    if [[ -d "$SCRIPTS_HOME/$name" ]]; then
        warn "Пакет $name уже есть — пропуск"
    else
        git clone -q "$url" "$SCRIPTS_HOME/$name" && ok "Пакет подключён: $name"
    fi
done

command -v fzf >/dev/null 2>&1 || warn "Совет: установите fzf для поиска с превью (sudo apt install fzf / brew install fzf)"

cat <<EOF

Готово. Дальше:
  dev new              создать свой скрипт
  dev add <git-url>    подключить репозиторий со скриптами
  dev                  меню
EOF
