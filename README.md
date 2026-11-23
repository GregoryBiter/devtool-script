# dev — лаунчер личных скриптов

Один файл на Bash (`bin/dev`), который находит ваши `.sh`-скрипты и запускает их одной командой.
В этом репозитории **нет самих скриптов** — только лаунчер. Скрипты живут в ваших собственных папках/репозиториях.

## Установка

```bash
curl -fsSL https://raw.githubusercontent.com/GregoryBiter/devtool-script/main/install.sh | bash
```

Сразу подключить свой репозиторий со скриптами:

```bash
curl -fsSL https://raw.githubusercontent.com/GregoryBiter/devtool-script/main/install.sh | bash -s -- --pack git@github.com:me/my-scripts.git
```

Нужны только `bash 4+` и `git`. `fzf` — по желанию (поиск с превью).

## Как это устроено

```text
~/.dev-scripts/                 ← DEV_SCRIPTS_HOME
├── base/                       ← пакет = обычная папка (обычно git-репозиторий)
│   ├── git/tag.sh              → dev git tag
│   └── docker/nuke.sh          → dev docker nuke
└── work/                       ← ещё один пакет (другой репозиторий)
    ├── deploy.sh               → dev deploy
    └── _lib/common.sh          ← «_» и «.» в начале = не команда (общий код)

./.dev/                         ← скрипты текущего проекта (пакет project)
    └── test/e2e.sh             → dev test e2e
```

**Путь файла = команда.** Никаких реестров и конфигов: положили файл — команда появилась.

## Создать скрипт

```bash
dev new                         # спросит имя, пакет, описание, опасность
dev new git cleanup             # сразу с именем
dev new git cleanup -p work -d "Удалить слитые ветки" --dangerous --no-edit
```

Получится готовый к правке файл:

```bash
#!/usr/bin/env bash
# @desc Удалить слитые ветки
# @usage dev git cleanup [аргументы]
# @dangerous true

set -euo pipefail
...
```

## Автодополнение по Tab

`install.sh` подключает его сам. Вручную — добавить в `~/.bashrc` (или `~/.zshrc` с `zsh`):

```bash
eval "$(dev completion bash)"
```

Дополняются команды и папки (`dev git <Tab>`), `dev edit/help`, пакеты в `dev new -p <Tab>`.
Аргументы самого скрипта — из строки в шапке:

```bash
# @complete patch minor major list delete
```

Новые скрипты видны в дополнении сразу, перезапуск терминала не нужен.

## Метаданные

Все строки `@...` необязательны. `@dangerous true` — лаунчер спросит `[y/N]` перед запуском (пропустить: `dev -y ...`).

## Команды

| Команда | Что делает |
| :--- | :--- |
| `dev` | меню выбора (fzf или нумерованный список) |
| `dev <команда> [арг...]` | запуск: `dev git tag patch`, также `dev git:tag`, `dev tag` (если имя уникально) |
| `dev <папка>` | меню внутри папки: `dev git` |
| `dev new [команда]` | создать скрипт из шаблона |
| `dev edit <команда>` | открыть скрипт в `$EDITOR` |
| `dev list [папка]` | список команд |
| `dev help <команда>` | описание, вызов, путь к файлу |
| `dev packs` | список пакетов |
| `dev add <git-url\|папка> [имя]` | подключить пакет (клон или ссылка на папку) |
| `dev update` | `git pull --ff-only` ядра и всех пакетов |
| `dev doctor` | проверка окружения |
| `dev completion [bash\|zsh]` | скрипт автодополнения по Tab |

Если одна и та же команда есть в нескольких пакетах, побеждает `project`, затем пакеты по алфавиту.

## Переменные

| Переменная | По умолчанию | Назначение |
| :--- | :--- | :--- |
| `DEV_SCRIPTS_HOME` | `~/.dev-scripts` | где лежат пакеты |
| `DEV_PACK_DIR` | — | передаётся скрипту: корень его пакета (для `source "$DEV_PACK_DIR/_lib/x.sh"`) |
| `DEV_FORCE` | `0` | `1` при запуске с `-y` |

## Удаление

```bash
~/.devtools/uninstall.sh          # убрать ссылку dev
~/.devtools/uninstall.sh --purge  # и удалить ~/.devtools
```

Ваши скрипты в `~/.dev-scripts` не удаляются.
