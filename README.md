> [!WARNING]
> Как и оригинальный проект, этот также не стремится быть "волшебной таблеткой", а лишь является удобным инструментом для развёртывания zapret в Docker

[zapret от bol-van](https://github.com/bol-van/zapret), собранный в Docker-контейнер c Shadowsocks для подключения к контейнеру.

Изначально предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`, чтобы не затрагивать основную сеть.

- [Использование](#использование)
- [Поиск стратегий](#поиск-стратегий)
- [Конфигурация](#конфигурация)
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
bash <(curl -sSL https://get.docker.com)
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

## Поиск стратегий

Поиск стратегий ничем не отличается от поиска в оригинальном zapret.

Запускаем скрипт `blockcheck.sh`. Этот скрипт подбирает оптимальную стратегию на основе особенностей вашего провайдера:

```bash
docker compose exec ss-zapret sh /opt/zapret/blockcheck.sh
```

> [!TIP]
> К скрипту поиска можно применять дополнительные параметры. Например, вам скорее всего не нужен режим TPWS и мы можем отключить поиск стратегий для него, чем сократим время поиска. Более подробно в [оригинальном репозитории](https://github.com/bol-van/zapret?tab=readme-ov-file#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0)

Пример запуска с параметрами:

```bash
docker compose exec ss-zapret sh -c 'SKIP_TPWS=1 REPEATS=8 DOMAINS="amnezia.org discord.com" /opt/zapret/blockcheck.sh'
```

## Конфигурация

В репозитории находится конфиг, в котором сразу же включены параметры для Discord и настроенные стратегии, которые протестированы на следующих VPS:

- [RocketCloud](https://rocketcloud.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66)
- [HSVDS](https://hsvds.ru/signup/?refid=20241026-9939487-843)

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
--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6
"
```

После внесения изменений не забудьте перезапустить контейнер:

```bash
docker compose restart
```

## Интеграция с панелями и прокси-клиентами

<details>
  <summary>3x-ui</summary>

⚠️ Если 3x-ui запущен на хосте, а не в Docker-контейнере, то не будут работать голосовые сервера в Discord. В остальном отличий от запуска в Docker нет ⚠️

Переходим на вкладку `Xray Configs` и добавляем outbound:

![image](https://i.imgur.com/qJ20THK.png)

⚠️ Так как 3x-ui использует `network_mode: host`, то мы не можем поместить его в одну сеть с нашим контейнером и использовать имя контейнера как hostname вместо IP ⚠️

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

</details>

<details>
  <summary>Marzban</summary>

WIP

</details>

<details>
  <summary>sing-box</summary>

WIP

</details>

<details>
  <summary>Xray</summary>

WIP

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

Если у вас есть идеи для улучшения скрипта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issue](https://github.com/vernette/ss-zapret/issues) или отправлять [pull request](https://github.com/vernette/ss-zapret/pulls).

## TODO

- [ ] Добавить примеры подключения к контейнеру
- [ ] Обновить zapret до версии 70.6
