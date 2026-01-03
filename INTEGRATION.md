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
