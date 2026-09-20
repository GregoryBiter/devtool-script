#!/usr/bin/env bash
# @name Git Tag Version Manager
# @description Управление версиями через Git-теги (semver vX.Y.Z: patch, minor, major) с авто-отправкой на origin
# @usage dev git tag [patch|minor|major] [сообщение] [-y|--yes]
# @dangerous false

set -e

# Проверка, что мы находимся внутри Git-репозитория
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

# Цвета для терминала
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Получение последнего тега версий (формат vX.Y.Z или X.Y.Z)
get_latest_tag() {
    # Пробуем получить актуальные теги из origin без падения, если нет сети
    git fetch --tags --quiet 2>/dev/null || true

    # Сортировка версий от новых к старым (version sort)
    git tag -l --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1
}

# 1. Быстрые команды: help / list / delete
if [[ "${1:-}" == "help" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo -e "${BOLD}${CYAN}Git Tag Version Manager${NC}"
    echo "Управление версиями проекта через семантические Git-теги (vX.Y.Z) с авто-отправкой на remote."
    echo
    echo -e "${BOLD}Использование:${NC}"
    echo "  dev git tag                       Интерактивное меню выбора инкремента версии"
    echo "  dev git tag patch [сообщение]     Инкремент patch версии (v0.0.1 -> v0.0.2)"
    echo "  dev git tag minor [сообщение]     Инкремент minor версии (v0.0.1 -> v0.1.0)"
    echo "  dev git tag major [сообщение]     Инкремент major версии (v0.0.1 -> v1.0.0)"
    echo "  dev git tag v1.2.3 [сообщение]    Установка явного номера версии"
    echo "  dev git tag list                  Показать текущую версию и историю тегов"
    echo "  dev git tag delete <tag>          Удалить тег локально и в remote"
    echo
    echo -e "${BOLD}Флаги:${NC}"
    echo "  -y, --yes, --force                Пропустить запросы подтверждения (для CI/CD)"
    echo "  -h, --help                        Показать эту справку"
    echo
    echo -e "${BOLD}Примечание:${NC}"
    echo "  Если в репозитории еще нет тегов, начальная версия автоматически стартует с v0.0.1."
    exit 0
fi

if [[ "${1:-}" == "list" || "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
    LATEST=$(get_latest_tag)
    echo -e "${BOLD}${CYAN}=== Список Git-тегов версий ===${NC}"
    if [[ -z "$LATEST" ]]; then
        echo "Теги версий пока не созданы."
    else
        echo -e "Текущая актуальная версия: ${GREEN}${BOLD}${LATEST}${NC}"
        echo
        echo "История тегов версий (последние 10):"
        git tag -l --sort=-v:refname -n1 | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -n 10
    fi
    exit 0
fi

if [[ "${1:-}" == "delete" || "${1:-}" == "--delete" || "${1:-}" == "-d" ]]; then
    TAG_DEL="${2:-}"
    if [[ -z "$TAG_DEL" ]]; then
        echo -e "${RED}✖ Ошибка: укажите имя тега для удаления.${NC}" >&2
        echo "Пример: dev git tag delete v0.0.1"
        exit 1
    fi
    echo -e "${YELLOW}⚠ Удаление тега: $TAG_DEL...${NC}"
    git tag -d "$TAG_DEL" || true
    REMOTE=$(git remote | head -n 1)
    if [[ -n "$REMOTE" ]]; then
        git push "$REMOTE" --delete "$TAG_DEL" 2>/dev/null || true
    fi
    echo -e "${GREEN}✔ Тег $TAG_DEL удален локально и на сервере.${NC}"
    exit 0
fi

# 2. Определение текущей и будущих версий
LATEST_TAG=$(get_latest_tag)

if [[ -z "$LATEST_TAG" ]]; then
    HAS_TAGS=false
    MAJOR=0
    MINOR=0
    PATCH=0
    # Если версий еще нет, начинаем с v0.0.1
    NEXT_PATCH="v0.0.1"
    NEXT_MINOR="v0.1.0"
    NEXT_MAJOR="v1.0.0"
else
    HAS_TAGS=true
    CLEAN_TAG="${LATEST_TAG#v}"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CLEAN_TAG"
    MAJOR="${MAJOR:-0}"
    MINOR="${MINOR:-0}"
    PATCH="${PATCH:-0}"

    NEXT_PATCH="v${MAJOR}.${MINOR}.$((PATCH + 1))"
    NEXT_MINOR="v${MAJOR}.$((MINOR + 1)).0"
    NEXT_MAJOR="v$((MAJOR + 1)).0.0"
fi

# 3. Разбор переданных аргументов
AUTO_CONFIRM=0
if [[ "${DEV_FORCE:-0}" == "1" ]]; then
    AUTO_CONFIRM=1
fi

ACTION=""
MESSAGE=""

for arg in "$@"; do
    case "$arg" in
        -y|--yes|--force)
            AUTO_CONFIRM=1
            ;;
        patch|minor|major|manor)
            ACTION="$arg"
            ;;
        v[0-9]*\.[0-9]*\.[0-9]*|[0-9]*\.[0-9]*\.[0-9]*)
            ACTION="$arg"
            ;;
        *)
            if [[ -z "$MESSAGE" ]]; then
                MESSAGE="$arg"
            else
                MESSAGE="$MESSAGE $arg"
            fi
            ;;
    esac
done

# Исправление опечатки manor -> major
if [[ "$ACTION" == "manor" ]]; then
    ACTION="major"
fi

# 4. Интерактивный выбор, если аргумент версии не задан
if [[ -z "$ACTION" ]]; then
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║            🏷️  Git Tag Version Manager                   ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    if [[ "$HAS_TAGS" == "true" ]]; then
        echo -e "Текущая версия:  ${GREEN}${BOLD}${LATEST_TAG}${NC}"
    else
        echo -e "Текущая версия:  ${YELLOW}(тегов версий нет, начинаем с v0.0.1)${NC}"
    fi
    echo
    echo -e "${BOLD}Выберите инкремент версии:${NC}"
    echo -e "  ${BOLD}1)${NC} patch  ➔  ${GREEN}${NEXT_PATCH}${NC}  (исправление ошибок, мелкие правки)"
    echo -e "  ${BOLD}2)${NC} minor  ➔  ${GREEN}${NEXT_MINOR}${NC}  (новый функционал, обратная совместимость)"
    echo -e "  ${BOLD}3)${NC} major  ➔  ${GREEN}${NEXT_MAJOR}${NC}  (глобальные изменения, breaking changes)"
    echo -e "  ${BOLD}4)${NC} custom ➔  ввести версию вручную"
    echo
    read -p "Ваш выбор (1-4) [1]: " CHOICE
    CHOICE="${CHOICE:-1}"

    case "$CHOICE" in
        1|patch)
            NEW_TAG="$NEXT_PATCH"
            ;;
        2|minor)
            NEW_TAG="$NEXT_MINOR"
            ;;
        3|major|manor)
            NEW_TAG="$NEXT_MAJOR"
            ;;
        4|custom)
            read -p "Введите номер версии (например, v1.0.0): " CUSTOM_INPUT
            if [[ ! "$CUSTOM_INPUT" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${RED}✖ Ошибка: неверный формат версии. Требуется vX.Y.Z (например v1.0.0).${NC}" >&2
                exit 1
            fi
            [[ "$CUSTOM_INPUT" != v* ]] && CUSTOM_INPUT="v$CUSTOM_INPUT"
            NEW_TAG="$CUSTOM_INPUT"
            ;;
        *)
            echo -e "${YELLOW}Неизвестный выбор. Используется patch: ${NEXT_PATCH}${NC}"
            NEW_TAG="$NEXT_PATCH"
            ;;
    esac
else
    case "$ACTION" in
        patch)
            NEW_TAG="$NEXT_PATCH"
            ;;
        minor)
            NEW_TAG="$NEXT_MINOR"
            ;;
        major)
            NEW_TAG="$NEXT_MAJOR"
            ;;
        *)
            # Пользователь передал конкретную версию (например v1.2.0)
            [[ "$ACTION" != v* ]] && ACTION="v$ACTION"
            NEW_TAG="$ACTION"
            ;;
    esac
fi

# 5. Проверка существования тега
if git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
    echo -e "${RED}✖ Ошибка: тег '$NEW_TAG' уже существует в репозитории!${NC}" >&2
    exit 1
fi

# 6. Проверка наличия незакоммиченных изменений
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    echo
    echo -e "${YELLOW}⚠ Внимание: в рабочей директории есть незакоммиченные изменения:${NC}"
    git status --short
    echo
    if [[ "$AUTO_CONFIRM" -eq 0 ]] && [[ -t 0 ]]; then
        read -p "Создать тег $NEW_TAG для текущего коммита HEAD? (y/N) [N]: " DIRTY_REPLY
        if [[ ! "$DIRTY_REPLY" =~ ^[yYдД] ]]; then
            echo -e "${YELLOW}Операция отменена пользователем.${NC}"
            exit 0
        fi
    fi
fi

# 7. Запрос описания (сообщения) тега
if [[ -z "$MESSAGE" ]]; then
    if [[ "$AUTO_CONFIRM" -eq 0 ]] && [[ -t 0 ]]; then
        read -p "Сообщение для тега [Release $NEW_TAG]: " USER_MSG
        MESSAGE="${USER_MSG:-Release $NEW_TAG}"
    else
        MESSAGE="Release $NEW_TAG"
    fi
fi

# 8. Определение удаленного репозитория (remote)
REMOTE=$(git remote | head -n 1)
REMOTE="${REMOTE:-origin}"

# 9. Подтверждение перед созданием и отправкой
echo
echo -e "${BOLD}${CYAN}Параметры создания тега:${NC}"
if [[ "$HAS_TAGS" == "true" ]]; then
    echo -e "  Версия:     ${YELLOW}$LATEST_TAG${NC} ➔ ${GREEN}${BOLD}$NEW_TAG${NC}"
else
    echo -e "  Версия:     ${GREEN}${BOLD}$NEW_TAG${NC} (первый релиз)"
fi
echo -e "  Сообщение:  ${CYAN}$MESSAGE${NC}"
echo -e "  Коммит:     ${BOLD}$(git rev-parse --short HEAD)${NC} ($(git log -1 --pretty=%s))"
if git remote >/dev/null 2>&1 && [[ -n "$REMOTE" ]]; then
    echo -e "  Сервер:     ${BOLD}$REMOTE${NC}"
fi
echo

if [[ "$AUTO_CONFIRM" -eq 0 ]] && [[ -t 0 ]]; then
    read -p "Создать и отправить тег $NEW_TAG на сервер? (Y/n) [Y]: " CONFIRM
    CONFIRM="${CONFIRM:-y}"
    if [[ ! "$CONFIRM" =~ ^[yYдД] ]]; then
        echo -e "${YELLOW}Создание тега отменено пользователем.${NC}"
        exit 0
    fi
fi

# 10. Создание аннотированного тега
echo "==> 🏷️ Создание локального аннотированного тега: $NEW_TAG..."
git tag -a "$NEW_TAG" -m "$MESSAGE"
echo -e "${GREEN}✔ Тег $NEW_TAG успешно создан локально.${NC}"

# 11. Отправка тега на удаленный сервер (remote)
if git remote | grep -q "^$REMOTE$"; then
    echo "--> 🚀 Отправка тега $NEW_TAG в удаленный репозиторий $REMOTE..."
    if git push "$REMOTE" "$NEW_TAG"; then
        echo
        echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${GREEN}║ ✔ Тег $NEW_TAG успешно создан и отправлен в $REMOTE!      ║${NC}"
        echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    else
        echo
        echo -e "${RED}✖ Ошибка при отправке тега $NEW_TAG в $REMOTE.${NC}" >&2
        echo "Локальный тег сохранен. Вы можете отправить его вручную: git push $REMOTE $NEW_TAG"
        exit 1
    fi
else
    echo
    echo -e "${YELLOW}ℹ Удаленный сервер (remote) не найден. Тег $NEW_TAG создан только локально.${NC}"
fi
