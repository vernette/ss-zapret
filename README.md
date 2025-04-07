> [!WARNING]
> Как и оригинальный проект, этот также не стремится быть "волшебной таблеткой" от всего, а лишь является удобным инструментом для развёртывания zapret в Docker

[zapret от bol-van](https://github.com/bol-van/zapret), собранный в Docker контейнер c Shadowsocks для подключения к контейнеру.

Изначально предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`, чтобы не затрагивать основную сеть.

## Использование

1. Установить Docker:

```bash
bash <(curl -sSL https://get.docker.com)
```

2. Клонировать репозиторий и перейти в его директорию:

```bash
git clone https://github.com/vernette/ss-zapret
cd ss-zapret
```

3. Cоздать `.env` файл (за основу можно взять `.env.example`) и отредактировать его. Используйте свой любимый текстовый редактор:

```bash
cp .env.example .env
nano .env
```

> [!WARNING] > **ВАЖНО** Смените стандартный пароль для Shadowsocks и, при необходимости, другие переменные окружения

4. Запустить контейнер:

```bash
docker compose up -d
```

## Поиск стратегий

Поиск стратегий ничем не отличается от поиска в оригинальном zapret. Входим в контейнер:

```bash
docker compose exec ss-zapret sh
```

Переходим в директорию `zapret`:

```bash
cd zapret
```

Запускаем скрипт `blockcheck.sh`. Этот скрипт подбирает оптимальную стратегию на основе особенностей вашего провайдера:

> [!TIP]
> К скрипту поиска можно применять дополнительные параметры. Например, вам скорее всего не нужен будет режим TPWS и мы можем отключить поиск стратегий для него, чем сократим время поиска. Более подробно в [оригинальном репозитории](https://github.com/bol-van/zapret?tab=readme-ov-file#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0)

```bash
./blockcheck.sh

# Пример запуска с параметрами
SKIP_TPWS=1 REPEATS=8 ./blockcheck.sh
```

## Конфигурация

В репозитории находится конфиг, в котором сразу же включены параметры для Discord и настроенные стратегии для запуска на [RocketCloud](https://rocketcloud.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66).

Для внесения изменений в конфиг открываем его в текстовом редакторе:

```bash
nano config
```

Стратегия меняется в переменной `NFQWS_OPT`, например:

```
NFQWS_OPT="
--filter-tcp=80 --methodeol --new
--filter-tcp=443 --hostlist-domains=googlevideo.com --dpi-desync=fakedsplit --dpi-desync-fooling=md5sig --dpi-desync-split-pos=1 --new
--filter-tcp=443 --dpi-desync=multisplit --dpi-desync-split-pos=2 --dpi-desync-split-seqovl=336 --dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --new
--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6
"
```

После внесения изменений не забудьте перезапустить контейнер:

```bash
docker compose restart
```

В итоге мы получаем крохотный (30 МБ) контейнер с zapret и запущенным Shadowsocks, который можно запустить на своём домашнем (чтобы не затрагивать основную сеть) или облачном сервере и к которому вы можете подключиться с помощью клиента Shadowsocks, или направить туда необходимые сайты через панель (3x-ui, Marzban, etc).

## Вклад в разработку

На данный момент проект находится в **очень** сыром состоянии, поэтому я буду рад любой помощи в его улучшении.

Если у вас есть идеи для улучшения скрипта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issue](https://github.com/vernette/ss-zapret/issues) или отправлять [pull requests](https://github.com/vernette/ss-zapret/pulls).

## TODO

- [ ] Добавить примеры подключения к контейнеру
- [ ] Обновить zapret до версии 70.6
