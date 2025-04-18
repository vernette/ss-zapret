FROM alpine:3.21

ARG ZAPRET_TAG

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
    nano \
    ipset \
    iptables \
    ip6tables \
    netcat-openbsd \
    shadowsocks-libev

WORKDIR /opt

RUN wget -qO- "https://github.com/bol-van/zapret/releases/download/${ZAPRET_TAG}/zapret-${ZAPRET_TAG}.tar.gz" | tar xz && \
  mv zapret-* zapret && \
  /opt/zapret/install_bin.sh

# curl with HTTP3 (QUIC) support
RUN wget -qO- https://github.com/stunnel/static-curl/releases/download/8.13.0/curl-linux-x86_64-glibc-8.13.0.tar.xz | tar -xJf - -C /usr/bin && \
  rm /usr/bin/SHA256SUMS && \
  chmod +x /usr/bin/curl

CMD ["/bin/sh", "-c", "/opt/zapret/init.d/sysv/zapret start && sleep 3 && exec ss-server -v -s 0.0.0.0 -p ${SS_PORT} -k ${SS_PASSWORD} -m ${SS_ENCRYPT_METHOD} -t ${SS_TIMEOUT} -u"]
