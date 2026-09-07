#!/usr/bin/env bash
# lib/utils.sh - Вспомогательные функции для devtool CLI

# --- Цвета и форматирование ---
setup_colors() {
    if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
        C_RESET="\033[0m"
        C_BOLD="\033[1m"
        C_DIM="\033[2m"
        C_RED="\033[31m"
        C_GREEN="\033[32m"
        C_YELLOW="\033[33m"
        C_BLUE="\033[34m"
        C_MAGENTA="\033[35m"
        C_CYAN="\033[36m"
        C_WHITE="\033[37m"
        C_BG_RED="\033[41m"
    else
        C_RESET=""
        C_BOLD=""
        C_DIM=""
        C_RED=""
        C_GREEN=""
        C_YELLOW=""
        C_BLUE=""
        C_MAGENTA=""
        C_CYAN=""
        C_WHITE=""
        C_BG_RED=""
    fi
}

setup_colors

log_info() {
    echo -e "${C_CYAN}ℹ${C_RESET} $*"
}

log_success() {
    echo -e "${C_GREEN}✔${C_RESET} $*"
}

log_warn() {
    echo -e "${C_YELLOW}⚠${C_RESET} $*"
}

log_error() {
    echo -e "${C_RED}✖${C_RESET} $*" >&2
}

log_step() {
    echo -e "${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"
}

# Корректное дополнение пробелами с учетом UTF-8 символов
pad_to() {
    local str="$1"
    local width="$2"
    local len=${#str}
    local pad_len=$((width - len))
    printf "%s" "$str"
    if (( pad_len > 0 )); then
        printf "%*s" "$pad_len" ""
    fi
}

# --- Извлечение метаданных из заголовков скрипта ---
# Поддерживает синтаксис:
# # @name Название команды
# # @description: Описание
# # @dangerous true / false
# # @usage: dev git sync [branch]
get_metadata() {
    local file="$1"
    local key="$2"
    local default_value="${3:-}"

    if [[ ! -f "$file" ]]; then
        echo "$default_value"
        return
    fi

    local val
    val=$(grep -m 1 -E "^#[[:space:]]*@${key}[:=]?[[:space:]]+" "$file" 2>/dev/null | \
          sed -E "s/^#[[:space:]]*@${key}[:=]?[[:space:]]+//" | \
          sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    if [[ -n "$val" ]]; then
        echo "$val"
    else
        echo "$default_value"
    fi
}

# --- Проверка опасных скриптов ---
confirm_if_dangerous() {
    local script_file="$1"
    local category="$2"
    local command_name="$3"
    local force_flag="${DEV_FORCE:-0}"

    local dangerous
    dangerous=$(get_metadata "$script_file" "dangerous" "false")

    if [[ "$dangerous" != "true" ]]; then
        return 0
    fi

    if [[ "$force_flag" == "1" ]]; then
        return 0
    fi

    local title
    title=$(get_metadata "$script_file" "name" "$category $command_name")
    local desc
    desc=$(get_metadata "$script_file" "description" "Опасная операция без описания")

    echo
    echo -e "${C_BOLD}${C_RED}┌─────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_RED}│  ⚠️   ВНИМАНИЕ: ОПАСНАЯ ОПЕРАЦИЯ!                            │${C_RESET}"
    echo -e "${C_BOLD}${C_RED}└─────────────────────────────────────────────────────────────┘${C_RESET}"
    echo -e "  ${C_BOLD}Команда:${C_RESET}     ${C_YELLOW}${category} ${command_name}${C_RESET} (${title})"
    echo -e "  ${C_BOLD}Описание:${C_RESET}    ${desc}"
    echo -e "  ${C_BOLD}Скрипт:${C_RESET}      ${C_DIM}${script_file}${C_RESET}"
    echo
    echo -e "${C_YELLOW}Эта операция может изменить или удалить локальные данные / ресурсы.${C_RESET}"
    echo -n "Вы действительно хотите продолжить? [y/N]: "
    
    local reply
    read -r reply || reply="n"

    echo
    case "$reply" in
        [yY]|[yY][eE][sS]|[дД]|[дД][аА])
            return 0
            ;;
        *)
            log_warn "Выполнение отменено пользователем."
            return 1
            ;;
    esac
}

# --- Поиск каталогов скриптов ---
# Приоритет:
# 1. Проектные скрипты: $PWD/.dev/scripts или $PWD/.dev
# 2. Пользовательские скрипты: ~/.config/devtool/scripts или ~/.devtools/scripts
# 3. Базовая библиотека репозитория: $DEV_ROOT_DIR/scripts
get_script_search_dirs() {
    local dirs=()

    # 1. Локальные для текущего репозитория/проекта
    if [[ -d "$PWD/.dev/scripts" ]]; then
        dirs+=("$PWD/.dev/scripts")
    elif [[ -d "$PWD/.dev" ]]; then
        dirs+=("$PWD/.dev")
    fi

    # 2. Персональные пользовательские скрипты
    if [[ -n "${DEV_EXTRA_SCRIPTS:-}" ]] && [[ -d "$DEV_EXTRA_SCRIPTS" ]]; then
        dirs+=("$DEV_EXTRA_SCRIPTS")
    elif [[ -d "$HOME/.config/devtool/scripts" ]]; then
        dirs+=("$HOME/.config/devtool/scripts")
    fi

    # 3. Базовое хранилище (встроенные скрипты)
    if [[ -d "$DEV_ROOT_DIR/scripts" ]]; then
        dirs+=("$DEV_ROOT_DIR/scripts")
    fi

    printf "%s\n" "${dirs[@]}"
}

# Найти конкретный скрипт по категории и имени
resolve_script_path() {
    local category="$1"
    local command_name="$2"

    local search_dirs
    mapfile -t search_dirs < <(get_script_search_dirs)

    for dir in "${search_dirs[@]}"; do
        # 1. Полноценная категория/команда.sh
        if [[ -f "$dir/$category/$command_name.sh" ]]; then
            echo "$dir/$category/$command_name.sh"
            return 0
        fi
        # 2. Без расширения .sh
        if [[ -f "$dir/$category/$command_name" ]] && [[ -x "$dir/$category/$command_name" ]]; then
            echo "$dir/$category/$command_name"
            return 0
        fi
        # 3. Если category пустой, прямой поиск в корне каталога
        if [[ -z "$command_name" ]] && [[ -f "$dir/$category.sh" ]]; then
            echo "$dir/$category.sh"
            return 0
        fi
    done

    return 1
}

# Список всех категорий
get_all_categories() {
    local search_dirs
    mapfile -t search_dirs < <(get_script_search_dirs)
    local categories=()

    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r cat_path; do
                if [[ -d "$cat_path" ]]; then
                    local cat_name
                    cat_name=$(basename "$cat_path")
                    # Пропускаем скрытые каталоги
                    [[ "$cat_name" =~ ^\. ]] && continue
                    categories+=("$cat_name")
                fi
            done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d)
        fi
    done

    printf "%s\n" "${categories[@]}" | sort -u
}

# Список всех скриптов (формат: category:command:file_path)
get_all_scripts() {
    local filter_category="${1:-}"
    local search_dirs
    mapfile -t search_dirs < <(get_script_search_dirs)
    
    declare -A seen_scripts

    for dir in "${search_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue

        while IFS= read -r script_file; do
            local rel_path="${script_file#$dir/}"
            local cat
            local cmd

            if [[ "$rel_path" == *"/"* ]]; then
                cat=$(dirname "$rel_path")
                cmd=$(basename "$rel_path" .sh)
            else
                cat="general"
                cmd=$(basename "$rel_path" .sh)
            fi

            # Если задан фильтр по категории
            if [[ -n "$filter_category" ]] && [[ "$cat" != "$filter_category" ]]; then
                continue
            fi

            local key="${cat}:${cmd}"
            if [[ -z "${seen_scripts[$key]:-}" ]]; then
                seen_scripts[$key]=1
                echo "${cat}:${cmd}:${script_file}"
            fi
        done < <(find "$dir" -type f -name "*.sh" | sort)
    done
}
