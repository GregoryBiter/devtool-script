#!/usr/bin/env bash
# @name Git Undo Commit
# @description Интерактивный откат коммитов: soft (в staging), mixed (в файлы), hard (удалить) или возврат из reflog
# @usage dev git undo [--soft|--mixed|--hard|--reflog]
# @dangerous true

set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: текущая директория не является Git-репозиторием." >&2
    exit 1
fi

MODE="${1:-}"

LAST_COMMIT=$(git log -1 --oneline)
echo "==> Последний коммит в текущей ветке:"
echo "  \033[1;33m$LAST_COMMIT\033[0m"
echo

if [[ -z "$MODE" ]]; then
    echo "Выберите режим отката:"
    echo "  1) soft   — отменить коммит, но оставить изменения в staged (готовыми к коммиту)"
    echo "  2) mixed  — отменить коммит и unstaged изменения (файлы останутся на диске)"
    echo "  3) hard   — полностью удалить коммит и все изменения в файлах (НЕОБРАТИМО!)"
    echo "  4) reflog — показать историю перемещений HEAD для восстановления потерянного коммита"
    echo "  q) отмена"
    echo
    echo -n "Ваш выбор [1-4, q]: "
    read -r choice
    case "$choice" in
        1|soft)   MODE="--soft" ;;
        2|mixed)  MODE="--mixed" ;;
        3|hard)   MODE="--hard" ;;
        4|reflog) MODE="--reflog" ;;
        *)        echo "Отмена."; exit 0 ;;
    esac
fi

case "$MODE" in
    --soft)
        git reset --soft HEAD~1
        echo "✔ Коммит отменен. Изменения сохранены в staging области (git status)."
        ;;
    --mixed)
        git reset HEAD~1
        echo "✔ Коммит отменен. Файлы сохранены на диске как неотслеживаемые/измененные."
        ;;
    --hard)
        git reset --hard HEAD~1
        echo "✔ Коммит и все изменения в файлах удалены."
        ;;
    --reflog)
        echo "==> Последние 10 записей git reflog:"
        git reflog -n 10
        echo
        echo "💡 Для возврата к любой точке используйте: git reset --hard <HEAD@{N}>"
        ;;
    *)
        echo "✖ Неизвестный режим: $MODE" >&2
        exit 1
        ;;
esac
