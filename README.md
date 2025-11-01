![Zapret Version](https://img.shields.io/badge/zapret-v72.2-red)
![Docker Pulls](https://img.shields.io/docker/pulls/vernette/ss-zapret?logo=docker)

Docker-контейнер на основе [zapret от bol-van](https://github.com/bol-van/zapret) с интегрированным Shadowsocks и SOCKS5 для подключения к контейнеру. Предназначен для удобной маршрутизации трафика через изолированную среду без модификации основной сети.

- Изоляция zapret в отдельном контейнере
- Простая интеграция с sing-box, Xray и другими прокси-клиентами

> [!CAUTION]
> В режиме `nfqws` контейнер работает только на Linux из-за отсутствия `nfqueue` на других ОС

## Содержание

- [Быстрый старт](#быстрый-старт)
  - [Предварительные требования](#предварительные-требования)
  - [Установка и запуск](#установка-и-запуск)
- [Конфигурация](#конфигурация)
- [Расширенные возможности](#расширенные-возможности)
  - [Поиск стратегий](#поиск-стратегий)
  - [Интеграция с прокси-клиентами](#интеграция-с-прокси-клиентами)
    - [sing-box](#интеграция-с-sing-box)
    - [Xray](#интеграция-с-xray)
    - [Интеграция в существующий проект](#интеграция-в-существующий-проект)
- [Работа Instagram в браузере](#работа-instagram-в-браузере)
- [Предупреждение про Shadowsocks и SOCKS5](#предупреждение-про-shadowsocks-и-socks5)

## Быстрый старт

### Предварительные требования

1. Установка git:

```bash
# Ubuntu/Debian
sudo apt install git

# Fedora
sudo dnf install git

# Arch Linux
sudo pacman -S git
```

2. Установка Docker:

```bash
bash <(wget -qO- https://get.docker.com)
```

### Установка и запуск

1. Клонируйте репозиторий:

```bash
git clone https://github.com/vernette/ss-zapret
cd ss-zapret
```

2. Скопируйте стандартный конфиг zapret:

```bash
cp config.default config
```

3. Cоздайте `.env` файл. За основу можно взять `.env.example`:

```bash
cp .env.example .env
nano .env
```

Пример содержимого `.env`:

```env
SS_PORT=8388                                # Порт Shadowsocks
SOCKS_PORT=1080                             # Порт SOCKS5
SS_PASSWORD=SuperSecurePassword             # Пароль (рекомендуется изменить!)
SS_ENCRYPT_METHOD=chacha20-ietf-poly1305    # Метод шифрования
SS_TIMEOUT=300                              # Таймаут подключения
```

> [!NOTE]
> Необязательно использовать `.env` файл. Вы можете задать переменные окружения вручную прямо в `docker-compose.yml`

Список переменных окружения в `docker-compose.yml`:

| Переменная                                  | Описание                                                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| SS_PORT: `8388`                             | Порт Shadowsocks                                                                                       |
| SOCKS_PORT: `1080`                          | Порт SOCKS5                                                                                            |
| SS_PASSWORD: `SuperSecurePassword`          | Пароль для Shadowsocks                                                                                 |
| SS_ENCRYPT_METHOD: `chacha20-ietf-poly1305` | Метод шифрования Shadowsocks                                                                           |
| SS_TIMEOUT: `300`                           | Таймаут сокета Shadowsocks в секундах                                                                  |
| SS_VERBOSE: `0`, `1`                        | Логгирование Shadowsocks. Если переменная не установлена или равна `1`, то по-умолчанию будет включено |

4. Запустите контейнер:

```bash
docker compose up -d
```

## Конфигурация

В репозитории находится конфиг, в котором включены параметры для Discord и настроенные стратегии, которые протестированы на следующих хостингах:

| Хостинг                                                                                           | Дата-центр               | Апстрим    |
| ------------------------------------------------------------------------------------------------- | ------------------------ | ---------- |
| [RocketCloud](https://rocketcloud.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66)        | M9                       | Rascom     |
| [HSVDS](https://hsvds.ru/signup/?refid=20241026-9939487-843)                                      | Собственный ДЦ           | WestCall   |
| [VDS Selectel MSK](https://vds.selectel.ru)                                                       | Selectel                 | Rascom     |
| [Aeza MSK](https://aeza.net/?ref=463603)                                                          | M9                       | Rascom     |
| [VDC MSK](https://my.vdc.ru/?affid=191) - промокод `VERNETTE` на скидку в 9%                      | DataCheap, M9            | INETCOM    |
| [RUVDS MSK](https://ruvds.com)                                                                    | Собственный ДЦ (Rucloud) | RETN       |
| [4VPS](https://4vps.su/r/v4LLSnpUc6Yv) - проверялся сервер в Кемерово. Скидка 20% на первый заказ | Yacolo                   | ER-Telecom |

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
- `--filter-udp=50000-50099 --filter-l7=discord,stun` - стратегия для диапазона портов Discord (с версии zapret >= 70.6)
- `--filter-udp=443` - стратегия для всего HTTP3 (QUIC) трафика

После внесения изменений не забудьте перезапустить контейнер:

```bash
docker compose restart
```

## Расширенные возможности

### Поиск стратегий

> [!WARNING]
> Перед поиском стратегий нужно обязательно остановить zapret командой `docker compose exec ss-zapret sh /opt/zapret/init.d/sysv/zapret stop`

Поиск стратегий осуществляется скриптом `blockcheck.sh`. Этот скрипт подбирает оптимальные стратегии для вашего домашнего/хостинг провайдера:

```bash
docker compose exec ss-zapret sh /opt/zapret/blockcheck.sh
```

> [!TIP]
> К скрипту поиска можно применять дополнительные параметры. Например, вам скорее всего не нужен режим TPWS и мы можем отключить поиск стратегий для него, чем сократим время поиска. Более подробно в [оригинальном репозитории](https://github.com/bol-van/zapret?tab=readme-ov-file#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0)

Запуск с параметрами:

```bash
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 REPEATS=8 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'
```

#### Поиск стратегий для HTTP, HTTPS TLS 1.2, без HTTPS TLS 1.3 и HTTP3 (QUIC). Подходит для сайтов, которые не поддерживают TLS 1.3 (таких мало, но они есть)

```bash
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=1 ENABLE_HTTPS_TLS12=1 ENABLE_HTTPS_TLS13=0 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'
```

#### Поиск стратегий для HTTPS TLS 1.3, без HTTP, HTTPS TLS 1.2 и HTTP3 (QUIC). Подходит для большинства сайтов и серверов YouTube

```bash
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=0 ENABLE_HTTPS_TLS12=0 ENABLE_HTTPS_TLS13=1 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="xxxxxx.googlevideo.com" /opt/zapret/blockcheck.sh'
```

После поиска стратегий запустите zapret командой `docker compose exec ss-zapret sh /opt/zapret/init.d/sysv/zapret start`, либо перезапустив контейнер.

### Интеграция с прокси-клиентами

#### Получение IP адреса контейнера

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zapret-proxy
```

#### Интеграция с sing-box

**Shadowsocks**

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
],
"route": {
  "rules": [
    {
      "network": "udp",
      "port": 443,
      "port_range": "50000:50099",
      "outbound": "ss-zapret-out"
    },
    {
      "network": "tcp",
      "outbound": "ss-zapret-out"
    }
  ]
}
```

**SOCKS5**

```json
"outbounds": [
  {
    "tag": "ss-zapret-out",
    "type": "socks",
    "server": "127.0.0.1",
    "server_port": 1080
  }
],
"route": {
  "rules": [
    {
      "network": "udp",
      "port": 443,
      "port_range": "50000:50099",
      "outbound": "ss-zapret-out"
    },
    {
      "network": "tcp",
      "outbound": "ss-zapret-out"
    }
  ]
}
```

> [!IMPORTANT]
> Обратите внимание на `server`: При обычном использовании указываем IP устройства, на котором запущен контейнер. Если используется панель, то нужно указывать [IP контейнера](#получение-ip-адреса-контейнера) или поместить контейнер в одну сеть с панелью и обращаться к нему по названию сервиса (`ss-zapret`) для корректной работы UDP трафика

#### Интеграция с Xray

**Shadowsocks**

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
],
"routing": {
  "rules": [
    {
      "type": "field",
      "network": "UDP",
      "port": "443,50000-50099",
      "outboundTag": "zapret"
    },
    {
      "type": "field",
      "network": "TCP",
      "outboundTag": "zapret"
    }
  ]
}
```

**SOCKS5**

```json
"outbounds": [
  {
    "tag": "zapret",
    "protocol": "socks",
    "settings": {
      "servers": [
        {
          "address": "127.0.0.1",
          "port": 1080
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
],
"routing": {
  "rules": [
    {
      "type": "field",
      "network": "UDP",
      "port": "443,50000-50099",
      "outboundTag": "zapret"
    },
    {
      "type": "field",
      "network": "TCP",
      "outboundTag": "zapret"
    }
  ]
}
```

> [!IMPORTANT]
> Обратите внимание на `address`: При обычном использовании указываем IP устройства, на котором запущен контейнер. Если используется панель, то нужно указывать [IP контейнера](#получение-ip-адреса-контейнера) или поместить контейнер в одну сеть с панелью и обращаться к нему по названию сервиса (`ss-zapret`) для корректной работы UDP трафика

#### Интеграция в существующий проект

Вы можете интегрировать контейнер ss-zapret в существующий проект, например, с Xray или sing-box, используя внешнюю Docker-сеть. Это позволит контейнерам разных проектов взаимодействовать друг с другом через имена сервисов вместо IP-адресов.

Покажу интеграцию на примере другого моего репозитория - [steal-oneself-examples](https://github.com/vernette/steal-oneself-examples)

##### Создание внешней сети

Создайте общую Docker-сеть, которую будут использовать оба проекта:

```bash
docker network create selfsteal
```

> В данном случае `selfsteal` - пример названия сети, можете использовать своё

##### Настройка ss-zapret

Клонируйте репозиторий:

```bash
git clone https://github.com/vernette/ss-zapret
cd ss-zapret
```

Создайте файл `.env` на основе примера:

```bash
cp .env.example .env
```

Отредактируйте `docker-compose.yml` для подключения к внешней сети, добавив в конфигурацию созданную сеть:

```yaml
services:
  ss-zapret:
    ...
    volumes:
      - ./config:/opt/zapret/config
    networks:
      - selfsteal
    ...

networks:
  selfsteal:
    external: true
```

##### Настройка основного проекта

В основном проекте добавляем подключение к той же внешней сети:

```yaml
services:
  caddy:
    image: caddy:2.9
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./caddy/data:/data
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./caddy/templates:/srv
    networks:
      - selfsteal

  xray:
    image: ghcr.io/xtls/xray-core:25.6.8
    restart: always
    ports:
      - "443:443"
    volumes:
      - ./xray:/usr/local/etc/xray/
    networks:
      - selfsteal

networks:
  selfsteal:
    external: true
```

#### Запуск проектов

Запустите оба проекта:

```bash
# В директории ss-zapret
docker-compose up -d

# В директории вашего основного проекта
docker-compose up -d
```

##### Использование в конфигурации

В конфигурации Xray или sing-box используйте имя сервиса `ss-zapret` для подключения:

```json
{
  "outbounds": [
    {
      "tag": "ss-zapret-out",
      "type": "shadowsocks",
      "server": "ss-zapret",
      "server_port": 8388,
      "method": "chacha20-ietf-poly1305",
      "password": "SuperSecurePassword"
    }
  ]
}
```

Docker автоматически разрешит имя сервиса в IP-адрес внутри общей сети `selfsteal`.

## Работа Instagram в браузере

> [!WARNING]
> Этот пункт выполняется на **удалённом сервере**. Если контейнер работает в локальной сети, то прописывайте IP на роутере или шлюзе

> [!WARNING]
> Не всегда на клиентах сразу заработает Instagram в браузере, возможно придётся поиграться с DNS

Чаще всего IP Instagram будет заблокирован и будет работать только в мобильном приложении.

Чтобы решить эту проблему, нам нужно найти незаблокированный IP и прописать его в `docker-compose.yml` на сервере:

```yaml
ss-zapret:
  image: vernette/ss-zapret:v71.4
  container_name: zapret-proxy
  restart: unless-stopped
  ...
  healthcheck:
    test: [
      "CMD-SHELL",
      "nc -z localhost ${SS_PORT} && nc -z localhost ${SOCKS_PORT} || exit 1"
    ]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 3s
  extra_hosts:
    instagram.com: "незаблокированный_ip"
    www.instagram.com: "незаблокированный_ip"
  cap_add:
    - NET_ADMIN
```

> Например instagram.com: "11.22.33.44"

После чего перезапустить compose, чтобы он прописал изменения в файл `/etc/hosts` контейнера:

```bash
docker compose down && docker compose up -d
```

## Сценарии использования

- **Локальное использование**: Запуск контейнера на домашнем сервере для изолированной работы zapret без модификации основной сети
- **Серверное использование**: Развертывание на удалённом VPS как единая точка подключения

## Разработка

Сборка образа с другой версией zapret:

```bash
docker build -t ss-zapret:v70.5 --build-arg ZAPRET_TAG=v70.5 .
```

Затем отредактируйте `docker-compose.yml`:

```yaml
ss-zapret:
  image: ss-zapret:v70.5
```

## Вклад в разработку

Если у вас есть идеи для улучшения проекта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issue](https://github.com/vernette/ss-zapret/issues) или отправлять [pull request](https://github.com/vernette/ss-zapret/pulls).

## Предупреждение про Shadowsocks и SOCKS5

> [!IMPORTANT]
> Shadowsocks и SOCKS5 предназначены только для подключения в **локальной** сети. Не рекомендуется использовать их для внешнего подключения, так как это может скомпрометировать сервер
