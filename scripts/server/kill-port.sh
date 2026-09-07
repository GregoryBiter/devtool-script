#!/usr/bin/env bash
# @name Kill Port Process
# @description Найти процесс, слушающий сетевой порт (например, 80, 3000, 8080), и завершить его
# @usage dev server kill-port <номер_порта> [-9]
# @dangerous true

set -e

PORT="${1:-}"

if [[ -z "$PORT" ]]; then
    echo -n "Введите номер порта для проверки (например: 80, 3000, 8080): "
    read -r PORT
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "✖ Ошибка: укажите корректный номер порта (1-65535)." >&2
    exit 1
fi

SIGNAL="-15"
if [[ "${2:-}" == "-9" ]] || [[ "${2:-}" == "--force" ]]; then
    SIGNAL="-9"
fi

echo "==> 🔍 Поиск процессов на порту $PORT..."

# Поиск через fuser, lsof или ss
PIDS=()
if command -v lsof >/dev/null 2>&1; then
    while IFS= read -r pid; do
        [[ -n "$pid" ]] && PIDS+=("$pid")
    done < <(lsof -ti :"$PORT" 2>/dev/null || true)
elif command -v fuser >/dev/null 2>&1; then
    while IFS= read -r pid; do
        [[ -n "$pid" ]] && PIDS+=("$pid")
    done < <(fuser "$PORT"/tcp 2>/dev/null || true)
elif command -v ss >/dev/null 2>&1; then
    while IFS= read -r pid; do
        [[ -n "$pid" ]] && PIDS+=("$pid")
    done < <(ss -lptn "sport = :$PORT" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 || true)
fi

# Устранение дубликатов
UNIQUE_PIDS=($(printf "%s\n" "${PIDS[@]}" | sort -u))

if [[ ${#UNIQUE_PIDS[@]} -eq 0 ]]; then
    echo "✔ На порту $PORT нет активных процессов."
    exit 0
fi

echo "Обнаружены процессы, использующие порт $PORT:"
printf "  %-8s %-12s %-10s %s\n" "PID" "ПОЛЬЗОВАТЕЛЬ" "RAM" "КОМАНДА"
echo "  ──────────────────────────────────────────────────────────────────"

for pid in "${UNIQUE_PIDS[@]}"; do
    ps -p "$pid" -o pid=,user=,%mem=,comm= 2>/dev/null | while read -r p u m c; do
        printf "  %-8s %-12s %-10s %s\n" "$p" "$u" "$m%" "$c"
    done
done
echo

for pid in "${UNIQUE_PIDS[@]}"; do
    echo "--> Отправка сигнала $SIGNAL процессу PID: $pid..."
    kill "$SIGNAL" "$pid" 2>/dev/null || sudo kill "$SIGNAL" "$pid" || true
done

sleep 1

# Проверка результата
REMAINING=0
for pid in "${UNIQUE_PIDS[@]}"; do
    if ps -p "$pid" >/dev/null 2>&1; then
        echo "⚠ Процесс $pid не завершился. Попробуйте принудительно: dev server kill-port $PORT -9"
        REMAINING=1
    fi
done

if [[ $REMAINING -eq 0 ]]; then
    echo "✔ Порт $PORT успешно освобожден."
fi
