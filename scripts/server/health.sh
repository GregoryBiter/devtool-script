#!/usr/bin/env bash
# @name Server Health
# @description Диагностика состояния сервера: диск, оперативная память, нагрузка CPU и сеть
# @usage dev server health
# @dangerous false

set -e

echo "==> 🩺 Диагностика системы"
echo

echo -e "\033[1;36m[1] Нагрузка системы и Uptime:\033[0m"
uptime
echo

echo -e "\033[1;36m[2] Свободное место на дисках:\033[0m"
df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null || df -h
echo

echo -e "\033[1;36m[3] Оперативная память:\033[0m"
free -h 2>/dev/null || free -m
echo

echo -e "\033[1;36m[4] Слушающие сетевые порты (TCP/UDP):\033[0m"
if command -v ss >/dev/null 2>&1; then
    ss -tuln | head -n 20
elif command -v netstat >/dev/null 2>&1; then
    netstat -tuln | head -n 20
else
    echo "  (утилиты ss и netstat не найдены)"
fi
echo

echo -e "\033[1;36m[5] Топ процессов по использованию памяти:\033[0m"
ps aux --sort=-%mem | head -n 6
