#!/usr/bin/env bash
# @name DevTool Update
# @description Обновить devtool-script до последней версии из Git-репозитория
# @usage dev update
# @dangerous false

set -e

REPO_DIR="${DEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

echo "==> 🚀 Обновление DevTool из Git..."
echo "  Каталог: $REPO_DIR"
echo

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✖ Ошибка: $REPO_DIR не является Git-репозиторием." >&2
    exit 1
fi

BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
OLD_HASH=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "--> git fetch origin $BRANCH..."
git -C "$REPO_DIR" fetch origin "$BRANCH" --prune

REMOTE_HASH=$(git -C "$REPO_DIR" rev-parse --short "origin/$BRANCH" 2>/dev/null || echo "unknown")

if [[ "$OLD_HASH" == "$REMOTE_HASH" ]]; then
    echo "✔ У вас уже установлена самая актуальная версия ($OLD_HASH)."
else
    echo "--> Применение обновлений ($OLD_HASH -> $REMOTE_HASH)..."
    git -C "$REPO_DIR" pull --ff-only origin "$BRANCH" || {
        echo "⚠ Не удалось выполнить fast-forward pull (локальные изменения). Синхронизация с origin/$BRANCH..."
        git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
    }
    echo
    echo "Новые изменения:"
    git -C "$REPO_DIR" log --oneline "${OLD_HASH}..${REMOTE_HASH}" || true
    echo
fi

USER_DIR="${DEV_USER_SCRIPTS_DIR:-$HOME/.dev-tools-scripts}"
mkdir -p "$USER_DIR"

if [[ ! -f "$USER_DIR/README.md" ]]; then
    cat << 'EOF' > "$USER_DIR/README.md"
# 🛠 Персональные скрипты DevTool

Каталог для добавления собственных скриптов для DevTool CLI (`dev`).

## Быстрый старт:

В каталоге `example/` находится готовый скрипт-пример:
```bash
dev example sample
```

## Как создать свой скрипт:

1. **Скопировать пример**:
   ```bash
   mkdir -p ~/.dev-tools-scripts/mytools
   cp ~/.dev-tools-scripts/example/sample.sh ~/.dev-tools-scripts/mytools/mycommand.sh
   ```

2. **Или использовать команду генератора**:
   ```bash
   dev dev create mytools mycommand
   ```

3. **Или создать вручную**:
   Создайте `.sh` файл в подпапке категории или прямо в корне каталога и сделайте исполняемым (`chmod +x`).
EOF
fi

EXAMPLE_SCRIPT="$USER_DIR/example/sample.sh"
if [[ ! -f "$EXAMPLE_SCRIPT" ]]; then
    echo "--> 📝 Добавление шаблона-примера пользовательского скрипта ($EXAMPLE_SCRIPT)..."
    mkdir -p "$(dirname "$EXAMPLE_SCRIPT")"
    cat << 'EOF' > "$EXAMPLE_SCRIPT"
#!/usr/bin/env bash
# @name Пример пользовательского скрипта
# @description Шаблон для создания ваших собственных команд DevTool
# @usage dev example sample [ваше_имя]
# @dangerous false

set -e

# ==============================================================================
# 💡 Как создать свой скрипт на основе этого шаблона:
# 1. Скопируйте этот файл под новым именем или в другую категорию:
#    cp ~/.dev-tools-scripts/example/sample.sh ~/.dev-tools-scripts/mytools/mycmd.sh
# 2. Отредактируйте метаданные выше (@name, @description, @usage, @dangerous)
# 3. Напишите вашу bash-логику ниже
# 4. Скрипт сразу появится в 'dev list' и будет готов к запуску:
#    dev mytools mycmd
# ==============================================================================

NAME="${1:-Разработчик}"

echo "👋 Привет, $NAME!"
echo "✔ Скрипт успешно выполнен из: ~/.dev-tools-scripts/example/sample.sh"
echo
echo "💡 Чтобы добавить собственную команду:"
echo "   1) Скопируйте этот файл: cp ~/.dev-tools-scripts/example/sample.sh ~/.dev-tools-scripts/<категория>/<команда>.sh"
echo "   2) Или используйте генератор: dev dev create <категория> <команда>"
EOF
    chmod +x "$EXAMPLE_SCRIPT"
    echo "✔ Шаблон-пример создан: $EXAMPLE_SCRIPT"
fi

if [[ -d "$USER_DIR/.git" ]]; then
    echo "--> 🔄 Обновление пользовательских скриптов ($USER_DIR)..."
    if git -C "$USER_DIR" fetch origin 2>/dev/null; then
        U_BRANCH=$(git -C "$USER_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        if git -C "$USER_DIR" pull --ff-only origin "$U_BRANCH" 2>/dev/null; then
            echo "✔ Пользовательские скрипты в $USER_DIR успешно обновлены."
        else
            echo "⚠ Не удалось автоматически выполнить fast-forward pull для $USER_DIR."
        fi
    fi
    echo
fi

echo "--> Проверка прав на исполнение..."
chmod +x "$REPO_DIR/bin/dev" "$REPO_DIR/lib/utils.sh"
find "$REPO_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
find "$USER_DIR" -mindepth 1 \( -name '.*' -prune -o -type f -name "*.sh" -exec chmod +x {} + \) 2>/dev/null || true
chmod +x "$REPO_DIR/install.sh" "$REPO_DIR/uninstall.sh" 2>/dev/null || true

echo
echo "✔ DevTool готов к работе (версия: $(git -C "$REPO_DIR" rev-parse --short HEAD))."
