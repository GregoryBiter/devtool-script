#!/usr/bin/env bash
# @name Git Sync Hosting Files
# @description Привязать локальную папку с файлами хостинга к удаленному репозиторию Git и свести изменения без потери данных
# @usage dev git sync-hosting [remote_url] [branch=main]
# @dangerous true

set -e

REMOTE_URL="${1:-}"
TARGET_BRANCH="${2:-}"

echo "================================================================"
echo "    🌐 Синхронизация файлов хостинга с Git-репозиторием         "
echo "================================================================"
echo

# 1. Проверка наличия Git
if ! command -v git >/dev/null 2>&1; then
    echo "✖ Ошибка: Git не установлен." >&2
    exit 1
fi

# 2. Инициализация Git при необходимости
if [[ ! -d ".git" ]]; then
    echo "--> [1/5] Инициализация локального Git-репозитория в текущей папке..."
    git init
    echo "✔ Репозиторий инициализирован."
else
    echo "--> [1/5] Локальный Git-репозиторий уже инициализирован."
fi

# 3. Настройка Remote URL
EXISTING_ORIGIN=$(git remote get-url origin 2>/dev/null || true)

if [[ -z "$REMOTE_URL" ]]; then
    if [[ -n "$EXISTING_ORIGIN" ]]; then
        echo "Найден существующий origin: $EXISTING_ORIGIN"
        echo -n "Использовать этот remote URL? [Y/n] или введите новый URL: "
        read -r input_url
        if [[ "$input_url" =~ ^[nNнН] ]]; then
            echo -n "Введите новый Git URL: "
            read -r REMOTE_URL
        elif [[ -n "$input_url" ]] && [[ ! "$input_url" =~ ^[yYдД] ]]; then
            REMOTE_URL="$input_url"
        else
            REMOTE_URL="$EXISTING_ORIGIN"
        fi
    else
        echo -n "Введите Git URL удаленного репозитория (ssh или https): "
        read -r REMOTE_URL
    fi
fi

if [[ -z "$REMOTE_URL" ]]; then
    echo "✖ Ошибка: Git URL репозитория не указан." >&2
    exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi
echo "✔ Remote origin настроен: $REMOTE_URL"

# 4. Выбор ветки
echo "--> [2/5] Подключение к удаленному репозиторию и получение метаданных..."
git fetch origin --prune

if [[ -z "$TARGET_BRANCH" ]]; then
    # Пробуем определить главную ветку репозитория
    DETECTED_BRANCH=""
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        DETECTED_BRANCH="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        DETECTED_BRANCH="master"
    fi

    if [[ -n "$DETECTED_BRANCH" ]]; then
        echo -n "Целевая ветка по умолчанию: [$DETECTED_BRANCH]. Нажмите Enter или укажите другую: "
        read -r input_branch
        TARGET_BRANCH="${input_branch:-$DETECTED_BRANCH}"
    else
        echo -n "Введите имя ветки для сведения (например: main, master): "
        read -r TARGET_BRANCH
    fi
fi

if ! git show-ref --verify --quiet "refs/remotes/origin/$TARGET_BRANCH"; then
    echo "✖ Ошибка: ветка '$TARGET_BRANCH' не найдена на remote origin." >&2
    echo "Доступные удаленные ветки:"
    git branch -r
    exit 1
fi

# 5. Сведение файлов хостинга с историей ветки (без перезаписи локальных файлов!)
echo
echo "--> [3/5] Безопасная привязка локальных файлов хостинга к origin/$TARGET_BRANCH..."
# Переключаем указатель HEAD на ветку без перезаписи рабочей копии
git symbolic-ref HEAD "refs/heads/$TARGET_BRANCH"

# Сбрасываем индекс на состояние origin/TARGET_BRANCH
# Это оставляет ВСЕ локальные файлы с хостинга нетронутыми, но Git теперь знает базовое состояние репозитория
git reset origin/"$TARGET_BRANCH"

# Настраиваем upstream для дальнейших pull/push
git branch --set-upstream-to="origin/$TARGET_BRANCH" "$TARGET_BRANCH" 2>/dev/null || true

# 6. Анализ изменений между хостингом и репозиторием
echo
echo "--> [4/5] Сравнение файлов хостинга с репозиторием origin/$TARGET_BRANCH:"
echo "────────────────────────────────────────────────────────────────"

MOD_COUNT=$(git diff --name-only --diff-filter=M | wc -l)
DEL_COUNT=$(git diff --name-only --diff-filter=D | wc -l)
ADD_COUNT=$(git status --short | grep '^[?]' | wc -l)

echo -e "  Изменено на хостинге: \033[1;33m$MOD_COUNT\033[0m файлов"
echo -e "  Удалено на хостинге:  \033[1;31m$DEL_COUNT\033[0m файлов"
echo -e "  Добавлено на хостинге:\033[1;32m$ADD_COUNT\033[0m новых файлов"
echo

if [[ "$MOD_COUNT" -eq 0 ]] && [[ "$DEL_COUNT" -eq 0 ]] && [[ "$ADD_COUNT" -eq 0 ]]; then
    echo "✔ Файлы хостинга полностью идентичны ветке origin/$TARGET_BRANCH! Различий нет."
    exit 0
fi

echo "Краткий статус первых изменений:"
git status --short | head -n 20
if [ "$(git status --short | wc -l)" -gt 20 ]; then
    echo "  ... и еще $(( $(git status --short | wc -l) - 20 )) файлов (запустите 'git status' для полного списка)"
fi
echo "────────────────────────────────────────────────────────────────"

# 7. Выбор дальнейших действий
echo
echo "--> [5/5] Что вы хотите сделать с зафиксированными изменениями?"
echo "  1) Создать отдельную ветку для хостинга и сделать коммит (Рекомендуется)"
echo "     (ветка: hosting-sync-$(date +%Y%m%d), удобно для создания PR или объединения через git merge)"
echo "  2) Закоммитить изменения прямо в текущую ветку '$TARGET_BRANCH'"
echo "  3) Оставить файлы как есть в рабочей копии (не коммитить, разберусь вручную)"
echo
echo -n "Ваш выбор [1-3]: "
read -r action_choice

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

case "$action_choice" in
    1)
        SYNC_BRANCH="hosting-sync-${TIMESTAMP}"
        git checkout -b "$SYNC_BRANCH"
        git add -A
        git commit -m "sync: snapshot from hosting $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "✔ Создана ветка '$SYNC_BRANCH' со слепком хостинга!"
        echo "Для слияния изменений в $TARGET_BRANCH выполните:"
        echo "  git checkout $TARGET_BRANCH"
        echo "  git merge $SYNC_BRANCH"
        echo "Или отправьте ветку на сервер: git push origin $SYNC_BRANCH"
        ;;
    2)
        git add -A
        git commit -m "sync: snapshot from hosting $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "✔ Изменения успешно закоммичены в ветку '$TARGET_BRANCH'!"
        echo "Для отправки на сервер выполните: git push origin $TARGET_BRANCH"
        ;;
    3|*)
        echo
        echo "✔ Изменения оставлены в рабочей копии."
        echo "Вы можете просмотреть отличия через 'git diff' или добавить файлы через 'git add'."
        ;;
esac

echo
echo "Синхронизация успешно завершена. Теперь вы можете безопасно продолжать разработку!"
