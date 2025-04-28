> [!WARNING]
> Как и оригинальный проект, этот также не стремится быть "волшебной таблеткой", а лишь является удобным инструментом для развёртывания zapret в Docker

[zapret от bol-van](https://github.com/bol-van/zapret), собранный в Docker-контейнер c Shadowsocks для подключения к контейнеру.

Изначально предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`, чтобы не затрагивать основную сеть.

> [!CAUTION]
> Работа контейнера гарантируется **только на Linux**. Точно не работает на Windows и скорее всего на macOS (не тестировалось)

- [Использование](#использование)
- [Конфигурация](#конфигурация)
- [Поиск стратегий](#поиск-стратегий)
- [Работа Instagram в браузере](#работа-instagram-в-браузере)
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

5. (опционально) Разрешить подключение только с localhost:

```bash
iptables -I DOCKER-USER -p tcp --dport 8388 ! -s 127.0.0.1 -j DROP
```

> Поменяйте порт в команде, если изменяли его в `.env`

## Конфигурация

В репозитории находится конфиг, в котором сразу же включены параметры для Discord и настроенные стратегии, которые протестированы на следующих хостингах:

| Хостинг                                                                                    | Дата-центр     | Апстрим  |
| ------------------------------------------------------------------------------------------ | -------------- | -------- |
| [RocketCloud](https://rocketcloud.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66) | M9             | Rascom   |
| [HSVDS](https://hsvds.ru/signup/?refid=20241026-9939487-843)                               | Собственный ДЦ | WestCall |
| [VDS Selectel MSK](https://vds.selectel.ru)                                                | Selectel       | Rascom   |
| [Aeza MSK](https://aeza.net/?ref=463603)                                                   | M9             | Rascom   |
| [VDC MSK](https://my.vdc.ru/?affid=191) - промокод `VERNETTE` на скидку в 9%               | DataCheap, M9  | INETCOM  |

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
# Поиск стратегий для HTTP, HTTPS TLS 1.2, без HTTPS TLS 1.3 и HTTP3 (QUIC). Подходит для сайтов, которые не поддерживают TLS 1.3 (таких мало, но они есть)
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=1 ENABLE_HTTPS_TLS12=1 ENABLE_HTTPS_TLS13=0 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'

# Поиск стратегий для HTTPS TLS 1.3, без HTTP, HTTPS TLS 1.2 и HTTP3 (QUIC). Подходит для большинства сайтов и серверов YouTube
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=0 ENABLE_HTTPS_TLS12=0 ENABLE_HTTPS_TLS13=1 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="xxxxxx.googlevideo.com" /opt/zapret/blockcheck.sh'
```

## Работа Instagram в браузере

> [!WARNING]
> Этот пункт выполняется на **удалённом сервере**. Если контейнер работает в локальной сети, то прописывайте IP на роутере или шлюзе

> [!WARNING]
> Не всегда на клиентах сразу заработает Instagram в браузере, возможно придётся поиграться с DNS

Чаще всего IP Instagram будет заблокирован, поэтому Instagram будет работать только в мобильном приложении.

Чтобы решить эту проблему, нам нужно найти незаблокированный IP и прописать его в `/etc/hosts` на сервере:

```bash
sudoedit /etc/hosts
```

Вписываем следующее в самый конец:

```
незаблокированный_ip instagram.com www.instagram.com
```

> Например 11.22.33.44 instagram.com www.instagram.com

После этого нам нужно будет установить `systemd-resolved`, чтобы файл `/etc/hosts` читался нашим контейнером, а именно `nslookup` в нём (чтобы при необходимости можно было искать стратегии для Instagram):

```bash
apt install systemd-resolved
systemctl enable --now systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

После чего перезапустить контейнер `ss-zapret`, чтобы он увидел новый `/etc/hosts`:

```bash
docker container restart zapret-proxy
```

## Интеграция с панелями и прокси-клиентами

Узнаём IP адрес Docker-контейнера с zapret:

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' zapret-proxy
```

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
  
  > Обратите внимание на `server`: если контейнер и sing-box запущены на одном хосте - то указываем `127.0.0.1`, иначе указываем IP устройства, на котором запущен контейнер
  
  Добавляем нужные правила:
  
  ```json
  "route": {
    "rules": [
      {
        "network": "udp",
        "port": 443,
        "port_range": "50000-50099",
        "outbound": "ss-zapret-out"
      },
      {
        "network": "tcp",
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
  
  > Обратите внимание на `address`: если контейнер и Xray запущены на одном хосте - то указываем `127.0.0.1`, иначе указываем IP устройства, на котором запущен контейнер

  Добавляем нужные правила:
  
  ```json
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
</details>

## Итог

Мы получаем крохотный (~30 МБ) Docker-контейнер с zapret и запущенным Shadowsocks для **локального подключения** к контейнеру.

> [!IMPORTANT]
> Не используйте Shadowsocks напрямую, так как он детектируется и блокируется

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
