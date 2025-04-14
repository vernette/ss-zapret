FROM alpine:3.21

ARG ZAPRET_TAG

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
    curl \
    nano \
    ipset \
    iptables \
    ip6tables \
    shadowsocks-libev

WORKDIR /opt

RUN curl -fsSL "https://github.com/bol-van/zapret/releases/download/${ZAPRET_TAG}/zapret-${ZAPRET_TAG}.tar.gz" | tar xz && \
  mv zapret-* zapret && \
  /opt/zapret/install_bin.sh

CMD ["/bin/sh", "-c", "/opt/zapret/init.d/sysv/zapret start && sleep 3 && exec ss-server -v -s 0.0.0.0 -p ${SS_PORT} -k ${SS_PASSWORD} -m ${SS_ENCRYPT_METHOD} -t ${SS_TIMEOUT} -u"]
