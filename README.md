> [!WARNING]
> Как и оригинальный проект, этот также не стремится быть "волшебной таблеткой", а лишь является удобным инструментом для развёртывания zapret в Docker

[zapret от bol-van](https://github.com/bol-van/zapret), собранный в Docker-контейнер c Shadowsocks для подключения к контейнеру.

Изначально предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`, чтобы не затрагивать основную сеть.

| ОС      | Поддерживается |
| ------- | -------------- |
| Linux   | Да             |
| Windows | Нет            |
| macOS   | ?              |

- [Использование](#использование)
- [Конфигурация](#конфигурация)
- [Поиск стратегий](#поиск-стратегий)
- [Интеграция с панелями и прокси-клиентами](#интеграция-с-панелями-и-прокси-клиентами)

## Использование

0. Установить git:

```bash
# Ubuntu/Debian
sudo apt install git

# Fedora
sudo dnf install git

# Arch Linux
sudo pacman -S git
```

1. Установить Docker:

```bash
bash <(wget -qO- https://get.docker.com)
```

2. Клонировать репозиторий и перейти в его директорию:

```bash
git clone https://github.com/vernette/ss-zapret
cd ss-zapret
```

> [!WARNING]
> Далее все команды нужно запускать из директории проекта - `ss-zapret`

3. Cоздать `.env` файл. За основу можно взять `.env.example`:

```env
SS_PORT=8388
SS_PASSWORD=SuperSecurePassword
SS_ENCRYPT_METHOD=chacha20-ietf-poly1305
SS_TIMEOUT=300
```

И отредактировать его:

```bash
cp .env.example .env
nano .env
```

> [!WARNING]
> **ВАЖНО:** Смените стандартный пароль для Shadowsocks и, при необходимости, другие переменные окружения

4. Запустить контейнер:

```bash
docker compose up -d
```

## Конфигурация

В репозитории находится конфиг, в котором сразу же включены параметры для Discord и настроенные стратегии, которые протестированы на следующих хостингах:

- [RocketCloud](https://rocketcloud.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66)
- [HSVDS](https://hsvds.ru/signup/?refid=20241026-9939487-843)
- [vds.selectel.ru MSK](https://vds.selectel.ru)
- [Aeza MSK](https://aeza.net/?ref=463603)
- [VDC MSK](https://my.vdc.ru/?affid=191) - промокод `VERNETTE` на скидку в 9%

> [!WARNING]
> Не везде всё может работать идеально, поэтому при необходимости можно внести изменения в конфиг

Для внесения изменений в конфиг открываем его в текстовом редакторе:

```bash
nano config
```

Стратегия меняется в переменной `NFQWS_OPT`, например:

```
NFQWS_OPT="
--filter-tcp=80 --methodeol --new
--filter-tcp=443 --hostlist-domains=youtube.com,googlevideo.com --dpi-desync=fakedsplit --dpi-desync-fooling=md5sig --dpi-desync-split-pos=1 --new
--filter-tcp=443 --dpi-desync=fake --dpi-desync-fooling=badseq --new
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new
--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6
"
```

- `--filter-tcp=80` - стратегия для всего HTTP трафика
- `--filter-tcp=443 --hostlist-domains=youtube.com,googlevideo.com` - стратегия для HTTPS для определенных доменов
- `--filter-tcp=443` - стратегия для всего остального HTTPS трафика
- `--filter-udp=50000-50099 --filter-l7=discord,stun` - стратегия для диапазона портов Discord (zapret >= `70.6`)
- `--filter-udp=443` - стратегия для всего HTTP3 (QUIC) трафика

После внесения изменений не забудьте перезапустить контейнер:

```bash
docker compose restart
```

## Поиск стратегий

Поиск стратегий ничем не отличается от поиска в оригинальном zapret и осуществляется скриптом `blockcheck.sh`. Этот скрипт подбирает оптимальную стратегию на основе особенностей вашего провайдера:

```bash
docker compose exec ss-zapret sh /opt/zapret/blockcheck.sh
```

> [!TIP]
> К скрипту поиска можно применять дополнительные параметры. Например, вам скорее всего не нужен режим TPWS и мы можем отключить поиск стратегий для него, чем сократим время поиска. Более подробно в [оригинальном репозитории](https://github.com/bol-van/zapret?tab=readme-ov-file#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0)

Запуск с параметрами:

```bash
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 REPEATS=8 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'
```

Парочка примеров под разные сценарии:

```bash
# Поиск стратегий для HTTP, HTTPS TLS 1.2, без HTTPS TLS 1.3 и HTTP3 (QUIC). Подходит для большинства сайтов
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=1 ENABLE_HTTPS_TLS12=1 ENABLE_HTTPS_TLS13=0 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'

# Поиск стратегий для HTTPS TLS 1.3, без HTTP, HTTPS TLS 1.2 и HTTP3 (QUIC). Подходит для серверов YouTube
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=0 ENABLE_HTTPS_TLS12=0 ENABLE_HTTPS_TLS13=1 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="xxxxxx.googlevideo.com" /opt/zapret/blockcheck.sh'
```

## Интеграция с панелями и прокси-клиентами

<details>
  <summary>3x-ui</summary>

⚠️ Если 3x-ui запущен на хосте, а не в Docker-контейнере, то не будут работать голосовые сервера в Discord. В остальном отличий от запуска в Docker нет ⚠️

### Docker, стандартный вариант

Переходим на вкладку `Xray Configs` и добавляем outbound:

![image](https://i.imgur.com/qJ20THK.png)

⚠️ Так как по-умолчанию 3x-ui использует `network_mode: host`, то мы не можем поместить его в одну сеть с нашим контейнером и использовать имя контейнера как hostname вместо IP ⚠️

Узнаём IP адрес Docker-контейнера с zapret:

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zapret-proxy
```

Выбираем протокол `Shadowsocks`, задаём тэг и заполняем параметры. В поле `Address` указываем IP из предыдущего шага:

![image](https://i.imgur.com/IY4N3AK.png)

После чего добавляем outbound кнопкой `Add Outbound`.

Переходим на вкладку `Routing Rules` и добавляем правило:

#### Для любого приходящего трафика

![image](https://i.imgur.com/dKrGz5r.png)

#### Для конкретного inbound

![image](https://i.imgur.com/xgzXhdf.png)

Добавляем правило кнопкой `Add Rule`.

После этого сохраняем настройки и перезапускаем Xray: `Save` -> `Restart Xray`

Теперь весь приходящий в панель трафик будет проходить через наш контейнер. Если требуется обрабатывать отдельные домены - изменяем правило соответствующим образом.

### Docker, интеграция с 3x-ui-aio

[3x-ui-aio](https://github.com/ampetelin/3x-ui-aio) - это проект, который запускает 3x-ui с Angie и автоматическим получением сертификатов для доменов, а также поднимает сайт "заглушку".

Клонируем оба репозитория:

```bash
git clone https://github.com/ampetelin/3x-ui-aio
git clone https://github.com/vernette/ss-zapret
```

Чтобы интегрировать наш контейнер с 3x-ui-aio, нужно внести изменения в файл `docker-compose.yml` от 3x-ui-aio:

```bash
nano 3x-ui-aio/docker-compose.yml
```

```yaml
services:
  angie:
    image: docker.angie.software/angie:latest
    container_name: angie
    volumes:
      - $PWD/angie.conf:/etc/angie/angie.conf
      - $PWD/options-ssl-angie.conf:/etc/angie/options-ssl-angie.conf
      - 3x-ui-aio-volume:/var/lib/angie/acme/
    ports:
      - "0.0.0.0:80:80"
      - "0.0.0.0:443:443"
    restart: unless-stopped
    networks:
      - 3x-ui-aio-network

  3x-ui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: 3x-ui
    volumes:
      - 3x-ui-aio-volume:/etc/x-ui/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
      X_UI_ENABLE_FAIL2BAN: "false"
    tty: true
    restart: unless-stopped
    networks:
      - 3x-ui-aio-network

  authorization-stub:
    image: ampetelin/authorization-stub
    container_name: authorization-stub
    environment:
      HOST: "0.0.0.0"
      PORT: "5000"
    restart: unless-stopped
    networks:
      - 3x-ui-aio-network

  ss-zapret:
    image: vernette/ss-zapret:latest
    container_name: zapret-proxy
    cap_add:
      - NET_ADMIN
    ports:
      - "${SS_PORT}:${SS_PORT}"
    volumes:
      - ./zapret_config:/opt/zapret/config
    environment:
      - SS_PORT=${SS_PORT}
      - SS_PASSWORD=${SS_PASSWORD}
      - SS_ENCRYPT_METHOD=${SS_ENCRYPT_METHOD}
      - SS_TIMEOUT=${SS_TIMEOUT}
    restart: unless-stopped
    networks:
      - 3x-ui-aio-network

networks:
  3x-ui-aio-network:
    name: 3x-ui-aio-network

volumes:
  3x-ui-aio-volume:
    name: 3x-ui-aio-volume
```

Тут мы добавляем `ss-zapret` в сеть `3x-ui-aio-network` и меняем название конфига zapret в `volumes`.

Создаём или копируем файл `.env`, а также копируем конфиг zapret из `ss-zapret` в директорию с `3x-ui-aio`:

```bash
cp ss-zapret/.env.example 3x-ui-aio/.env # или если он уже есть - cp ss-zapret/.env 3x-ui-aio/.env
cp ss-zapret/config 3x-ui-aio/zapret_config
```

Далее следуем инструкции из 3x-ui-aio. Когда панель будет доступна, то добавляем outbound следующим образом:

![image](https://i.imgur.com/WlLDl9d.png)

Настройка правил не отличается от инструкции выше.

</details>

<details>
  <summary>Marzban</summary>

WIP

</details>

<details>
  <summary>sing-box</summary>

Добавляем outbound в конфиг:

```json
"outbounds": [
  {
    "tag": "ss-zapret-out",
    "type": "shadowsocks",
    "server": "127.0.0.1",
    "server_port": 8388,
    "method": "chacha20-ietf-poly1305",
    "password": "SuperSecurePassword"
  }
]
```

> Обратите внимание на `server`: если контейнер и sing-box запущены на одном хосте - то указываем `127.0.0.1`, иначе указываем IP сервера или контейнера.

Добавляем нужные правила:

```json
"route": {
  "rules": [
    {
      "domain_suffix": ["amnezia.org"],
      "outbound": "ss-zapret-out"
    }
  ]
}
```

</details>

<details>
  <summary>Xray</summary>

Добавляем outbound в конфиг:

```json
"outbounds": [
  {
    "tag": "zapret",
    "protocol": "shadowsocks",
    "settings": {
      "servers": [
        {
          "address": "127.0.0.1",
          "port": 8388,
          "password": "SuperSecurePassword",
          "method": "chacha20-ietf-poly1305"
        }
      ]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "none",
      "tcpSettings": {
        "header": {
          "type": "none"
        }
      }
    }
  }
]
```

> Обратите внимание на `address`: если контейнер и sing-box запущены на одном хосте - то указываем `127.0.0.1`, иначе указываем IP сервера или контейнера.

Добавляем нужные правила:

```json
"routing": {
  "rules": [
    {
      "type": "field",
      "domain": ["domain:amnezia.org"],
      "outboundTag": "zapret"
    }
  ]
}
```

</details>

## Итог

Мы получаем крохотный (~30 МБ) Docker-контейнер с zapret и запущенным Shadowsocks.

Он может работать:

- на домашнем сервере - изолированно, чтобы не затрагивать основную сеть
- в облаке - как единая точка входа

Контейнер удобно использовать для прокидывания определённых доменов/сервисов через sing-box, Xray, другие прокси-клиенты или панели, или же для маршрутизации в него всего трафика.

## Разработка

Чтобы собрать образ с другой версией zapret, укажите нужный тег при сборке:

```bash
docker build -t ss-zapret:v70.5 --build-arg ZAPRET_TAG=v70.5 .
```

После чего отредактируйте `docker-compose.yml`:

```yaml
...
ss-zapret:
  image: ss-zapret:v70.5
...
```

## Вклад в разработку

На данный момент проект находится в **очень** сыром состоянии, поэтому я буду рад любой помощи в его улучшении.

Если у вас есть идеи для улучшения проекта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issue](https://github.com/vernette/ss-zapret/issues) или отправлять [pull request](https://github.com/vernette/ss-zapret/pulls).

## TODO

- [ ] Добавить примеры подключения к контейнеру
- [x] Обновить zapret до версии 70.6
