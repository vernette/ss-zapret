FROM alpine:3.21 AS build

ARG ZAPRET_TAG

WORKDIR /opt

RUN wget -qO- "https://github.com/bol-van/zapret/releases/download/${ZAPRET_TAG}/zapret-${ZAPRET_TAG}.tar.gz" | tar xz && \
    mv zapret-* zapret && \
    /opt/zapret/install_bin.sh

RUN wget -qO- https://github.com/stunnel/static-curl/releases/download/8.13.0/curl-linux-x86_64-glibc-8.13.0.tar.xz | tar -xJf - -C /opt && \
    chmod +x /opt/curl

FROM alpine:3.21

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
    iptables \
    ip6tables \
    netcat-openbsd \
    shadowsocks-libev

WORKDIR /opt

COPY --from=build /opt/zapret /opt/zapret
COPY --from=build /opt/curl /usr/bin/curl

CMD ["/bin/sh", "-c", "/opt/zapret/init.d/sysv/zapret start && exec ss-server -v -s 0.0.0.0 -p ${SS_PORT} -k ${SS_PASSWORD} -m ${SS_ENCRYPT_METHOD} -t ${SS_TIMEOUT} -u"]
