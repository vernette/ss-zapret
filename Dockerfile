FROM alpine:3.21 AS build

ARG ZAPRET_TAG=v70.6
ARG CURL_VERSION=8.13.0

WORKDIR /opt

RUN wget -qO- "https://github.com/bol-van/zapret/releases/download/${ZAPRET_TAG}/zapret-${ZAPRET_TAG}.tar.gz" | tar xz && \
    mv zapret-* zapret && \
    /opt/zapret/install_bin.sh

RUN wget -qO- "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-x86_64-glibc-${CURL_VERSION}.tar.xz" | tar -xJf - -C /opt && \
    chmod +x /opt/curl

FROM alpine:3.21

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
    ipset \
    iptables \
    ip6tables \
    netcat-openbsd \
    shadowsocks-libev

WORKDIR /opt

COPY --from=build /opt/zapret /opt/zapret
COPY --from=build /opt/curl /usr/bin/curl
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
