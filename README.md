> [!WARNING]
> Как и оригинальный проект, этот также не стремится быть "волшебной таблеткой" от всего, а лишь удобным инструментом для развёртывания zapret в Docker

[zapret от bol-van](https://github.com/bol-van/zapret), собранный в Docker контейнер c shadowsocks для подключения к контейнеру.

Изначально предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`, чтобы не затрагивать основную сеть.

## Зависимости

Для удобного управления сборкой, запуском, остановкой, обновления и просмотра логов через Makefile на основной системе потребуется `make` и `git`. После первой сборки можно использовать `docker compose` вместо `make`.

Во всех популярных дистрибутивах оба устанавливаются через пакетный менеджер. Пара примеров:

```bash
# Ubuntu/Debian
sudo apt install make git

# Fedora
sudo dnf install make git

# Arch Linux
sudo pacman -S make git
```

Для других дистрибутивов можно найти название пакета на [pkgs.org](https://pkgs.org/download/make)

## Использование

Для начала нужно клонировать репозиторий и перейти в его директорию:

```bash
git clone https://github.com/vernette/ss-zapret
cd ss-zapret
```

После этого нужно создать `.env` файл (за основу можно взять `.env.example`). Используйте свой любимый текстовый редактор:

```bash
cp .env.example .env
nano .env
```

> [!WARNING]
> **Обязательно** измените пароль для shadowsocks и, при желании, другие переменные окружения

Теперь можно собрать образ и запустить его:

```bash
make build
make up
```

Для внесения изменений в конфиг (а также для использования `blockcheck.sh`) можно войти в контейнер:

```bash
docker exec -it ss-zapret sh
cd zapret
```

По-умолчанию копируется **дефолтный** конфиг для `zapret`, в котором изначально отключены все режимы. Для включения нужного режима откройте конфиг и включите нужный режим, выставив ему `1` вместо `0`:

```bash
nano /opt/zapret/config
```

> [!NOTE]
> После внесения изменений в конфиг нужно перезапустить контейнер командами `make down` и `make up`

В итоге мы получаем контейнер с zapret и запущенным shadowsocks, к которому вы можете подключиться с помощью клиента shadowsocks, или направить туда необходимые сайты через панель (3x-ui, marzban, etc).

> [!NOTE]
> По-умолчанию shadowsocks работает на всех интерфейсах и порте `8388`

## Управление контейнером

Все команды, для управления контейнером через `make`:

| Команда       | Описание                                                                                             |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| `make build`  | Собрать образ                                                                                        |
| `make up`     | Запустить контейнер                                                                                  |
| `make down`   | Остановить контейнер                                                                                 |
| `make logs`   | Просмотреть логи контейнера                                                                          |
| `make update` | Обновить версию zapret (если такая есть) в `.env` файле. После этого нужно будет вновь собрать образ |

## Свой конфиг

Чтобы использовать свой конфиг для `zapret`, нужно раскомментировать блок `volumes` в `docker-compose.yml` и положить конфиг с названием `config` в корневую директорию (где лежит `docker-compose.yml`).

Также по-умолчанию копируется custom.d скрипт для Discord. При желании вы можете отключить его, просто закомментировав строчку в `Dockerfile`.

## Вклад в разработку

На данный момент проект находится в **очень** сыром состоянии, поэтому я буду рад любой помощи в его улучшении.

Если у вас есть идеи для улучшения скрипта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issues](https://github.com/vernette/ss-zapret/issues) или отправлять [pull requests](https://github.com/vernette/ss-zapret/pulls).

## TODO

- [ ] Разобраться, почему не работают голосовые чаты в Discord
