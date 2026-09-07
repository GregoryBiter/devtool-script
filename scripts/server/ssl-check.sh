#!/usr/bin/env bash
# @name Check SSL Certificate
# @description Проверить дату истечения, оставшиеся дни и издателя SSL-сертификата домена через OpenSSL
# @usage dev server ssl-check <домен> [порт=443]
# @dangerous false

set -e

DOMAIN="${1:-}"
PORT="${2:-443}"

if [[ -z "$DOMAIN" ]]; then
    echo -n "Введите домен для проверки (например: google.com, github.com): "
    read -r DOMAIN
fi

# Удаляем https:// или http:// если случайно ввели
DOMAIN=$(echo "$DOMAIN" | sed -e 's~^https\?://~~' -e 's~/.*$~~')

if [[ -z "$DOMAIN" ]]; then
    echo "✖ Ошибка: домен не указан." >&2
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "✖ Ошибка: OpenSSL не установлен." >&2
    exit 1
fi

echo "==> 🔐 Проверка SSL-сертификата для: $DOMAIN:$PORT..."
echo

# Получаем данные сертификата
CERT_DATA=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null || true)

if [[ -z "$CERT_DATA" ]] || ! echo "$CERT_DATA" | grep -q "BEGIN CERTIFICATE"; then
    echo "✖ Не удалось подключиться или получить SSL-сертификат от $DOMAIN:$PORT" >&2
    exit 1
fi

PARSED=$(echo "$CERT_DATA" | openssl x509 -noout -dates -issuer -subject 2>/dev/null)

START_DATE=$(echo "$PARSED" | grep 'notBefore=' | cut -d= -f2)
END_DATE=$(echo "$PARSED" | grep 'notAfter=' | cut -d= -f2)
ISSUER=$(echo "$PARSED" | grep 'issuer=' | cut -d= -f2-)
SUBJECT=$(echo "$PARSED" | grep 'subject=' | cut -d= -f2-)

# Вычисление оставшихся дней
END_EPOCH=$(date -d "$END_DATE" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$END_DATE" +%s 2>/dev/null || echo "0")
NOW_EPOCH=$(date +%s)
DIFF_SEC=$((END_EPOCH - NOW_EPOCH))
DAYS_LEFT=$((DIFF_SEC / 86400))

echo -e "  \033[1mДомен:\033[0m            \033[1;36m$DOMAIN\033[0m"
echo -e "  \033[1mСубъект:\033[0m          $SUBJECT"
echo -e "  \033[1mИздатель:\033[0m         $ISSUER"
echo -e "  \033[1mДата выдачи:\033[0m      $START_DATE"
echo -e "  \033[1mИстекает:\033[0m         \033[1;33m$END_DATE\033[0m"

if [ "$DAYS_LEFT" -gt 30 ]; then
    echo -e "  \033[1mСтатус:\033[0m           \033[1;32mДействителен (осталось $DAYS_LEFT дн.)\033[0m"
elif [ "$DAYS_LEFT" -gt 0 ]; then
    echo -e "  \033[1mСтатус:\033[0m           \033[1;33mВнимание: скоро истекает (осталось $DAYS_LEFT дн.)\033[0m"
else
    echo -e "  \033[1mСтатус:\033[0m           \033[1;31mИСТЕК (${DAYS_LEFT#-} дн. назад)!\033[0m"
fi
echo
