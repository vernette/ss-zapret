> [!WARNING]
> Образ собирался под себя, может что-то пойти не так на ваших конфигах

<h2 align="center">ss-zapret</h2>

[zapret от bol-van](https://github.com/bol-van/zapret) собранный в докер c shadowsocks для подключения к контейнеру

Предназначался для маршрутизации в него доменов/подсетей Discord из sing-box и модификации очереди `nfqueue` в режиме `nfqws`

Запускается на дефолтном конфиге из репозитория zapret, но можно прокинуть свои 

```shell
docker run -d \
  --name=ss-zapret \
  --cap-add=NET_ADMIN \
  -e SS_SERVER_HOST=0.0.0.0 \
  -e SS_SERVER_PORT=8388 \
  -e SS_PASSWORD="$(hostname)" \
  -e SS_ENCRYPT_METHOD="chacha20-ietf-poly1305" \
  -e SS_TIMEOUT=86400 \
  -p 0.0.0.0:8388:8388/tcp \
  -p 0.0.0.0:8388:8388/udp \
  -v /path/to/zapret/config:/opt/zapret/config `#optional` \
  -v /path/to/zapret/custom.d:/opt/zapret/init.d/sysv/custom.d `#optional` \
  --restart unless-stopped \
  ss-zapret
```