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
# 2. Персональные пользовательские скрипты: $DEV_EXTRA_SCRIPTS, ~/.dev-tools-scripts, ~/.config/devtool/scripts
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
    fi

    # Пользовательская директория в домашней папке (~/.dev-tools-scripts)
    local user_scripts_dir="${DEV_USER_SCRIPTS_DIR:-$HOME/.dev-tools-scripts}"
    if [[ -d "$user_scripts_dir" ]]; then
        dirs+=("$user_scripts_dir")
        if [[ -d "$user_scripts_dir/scripts" ]]; then
            dirs+=("$user_scripts_dir/scripts")
        fi
    fi

    if [[ -d "$HOME/.config/devtool/scripts" ]]; then
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
        if [[ -n "$category" ]] && [[ -n "$command_name" ]] && [[ -f "$dir/$category/$command_name.sh" ]]; then
            echo "$dir/$category/$command_name.sh"
            return 0
        fi
        # 2. Без расширения .sh внутри категории
        if [[ -n "$category" ]] && [[ -n "$command_name" ]] && [[ -f "$dir/$category/$command_name" ]] && [[ -x "$dir/$category/$command_name" ]]; then
            echo "$dir/$category/$command_name"
            return 0
        fi
        # 3. Прямой поиск в корне каталога (dir/command_name.sh), если category == "general" или category пустой
        if [[ "$category" == "general" || -z "$category" ]] && [[ -n "$command_name" ]]; then
            if [[ -f "$dir/$command_name.sh" ]]; then
                echo "$dir/$command_name.sh"
                return 0
            fi
            if [[ -f "$dir/$command_name" ]] && [[ -x "$dir/$command_name" ]]; then
                echo "$dir/$command_name"
                return 0
            fi
        fi
        # 4. Если command_name пустой, прямой поиск в корне каталога (dir/category.sh)
        if [[ -z "$command_name" ]] && [[ -f "$dir/$category.sh" ]]; then
            echo "$dir/$category.sh"
            return 0
        fi
        # 5. Если вызван как "dev mycmd", и category="mycmd", проверяем dir/mycmd.sh
        if [[ -n "$category" ]] && [[ -z "$command_name" || "$command_name" == "$category" ]] && [[ -f "$dir/$category.sh" ]]; then
            echo "$dir/$category.sh"
            return 0
        fi
        # 6. Если передан category и command_name, но скрипт лежит в корне как dir/command_name.sh
        if [[ -n "$command_name" ]] && [[ -f "$dir/$command_name.sh" ]]; then
            echo "$dir/$command_name.sh"
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
            done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)

            # Если в корне каталога есть скрипты .sh, добавляем категорию general
            if find "$dir" -maxdepth 1 -type f -name "*.sh" ! -name '.*' 2>/dev/null | grep -q .; then
                categories+=("general")
            fi
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
            [[ -z "$script_file" ]] && continue
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

            # Пропускаем скрытые файлы или каталоги
            [[ "$cat" =~ (^|/)\. ]] && continue
            [[ "$cmd" =~ ^\. ]] && continue

            # Если задан фильтр по категории
            if [[ -n "$filter_category" ]] && [[ "$cat" != "$filter_category" ]]; then
                continue
            fi

            local key="${cat}:${cmd}"
            if [[ -z "${seen_scripts[$key]:-}" ]]; then
                seen_scripts[$key]=1
                echo "${cat}:${cmd}:${script_file}"
            fi
        done < <(find "$dir" -mindepth 1 \( -name '.*' -prune -o -type f -name "*.sh" -print \) 2>/dev/null | sort)
    done
}
