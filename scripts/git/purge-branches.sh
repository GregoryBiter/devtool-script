#!/usr/bin/env bash
# @name Git Purge Dead Branches
# @description Очистить локальные ветки, которые уже были удалены на origin (статус gone) или смерджены в main
# @usage dev git purge-branches [--force]
# @dangerous true

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

echo "==> 🔄 Синхронизация списка удаленных веток (git fetch --prune)..."
git fetch --prune origin

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
DEFAULT_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        DEFAULT_BRANCH="master"
    fi
fi

echo "--> Поиск веток со статусом [gone] на сервере..."
GONE_BRANCHES=()
while IFS= read -r branch; do
    [[ -n "$branch" ]] && GONE_BRANCHES+=("$branch")
done < <(git branch -vv | awk '/: gone]/ {print $1}' | tr -d '*+')

echo "--> Поиск локальных веток, уже слитых в $DEFAULT_BRANCH..."
MERGED_BRANCHES=()
while IFS= read -r branch; do
    branch_clean=$(echo "$branch" | tr -d ' *+')
    if [[ -n "$branch_clean" ]] && [[ "$branch_clean" != "$DEFAULT_BRANCH" ]] && [[ "$branch_clean" != "$CURRENT_BRANCH" ]] && [[ "$branch_clean" != "develop" ]] && [[ "$branch_clean" != "staging" ]]; then
        MERGED_BRANCHES+=("$branch_clean")
    fi
done < <(git branch --merged "$DEFAULT_BRANCH" 2>/dev/null || true)

# Объединение уникальных веток
declare -A UNIQUE_MAP
ALL_CANDIDATES=()

for b in "${GONE_BRANCHES[@]}" "${MERGED_BRANCHES[@]}"; do
    if [[ -z "${UNIQUE_MAP[$b]:-}" ]] && [[ "$b" != "$CURRENT_BRANCH" ]] && [[ "$b" != "$DEFAULT_BRANCH" ]]; then
        UNIQUE_MAP[$b]=1
        ALL_CANDIDATES+=("$b")
    fi
done

if [[ ${#ALL_CANDIDATES[@]} -eq 0 ]]; then
    echo "✔ Мертвых или уже слитых веток не обнаружено. Все чисто!"
    exit 0
fi

echo
echo "Обнаружены следующие неактуальные локальные ветки:"
for b in "${ALL_CANDIDATES[@]}"; do
    REASON="слита в $DEFAULT_BRANCH"
    for gb in "${GONE_BRANCHES[@]}"; do
        if [[ "$gb" == "$b" ]]; then
            REASON="удалена на origin [gone]"
            break
        fi
    done
    echo -e "  - \033[1;31m$b\033[0m \033[2m($REASON)\033[0m"
done
echo

DELETE_FLAG="-d"
if [[ "${1:-}" == "--force" ]] || [[ "${2:-}" == "--force" ]]; then
    DELETE_FLAG="-D"
fi

for b in "${ALL_CANDIDATES[@]}"; do
    echo "--> Удаление ветки: $b..."
    git branch "$DELETE_FLAG" "$b" || git branch -D "$b"
done

echo
echo "✔ Удалено веток: ${#ALL_CANDIDATES[@]}."
