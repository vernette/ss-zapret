ARG ALPINE_VERSION=3.21
ARG ZAPRET_TAG=v72.1
ARG CURL_VERSION=8.13.0

FROM alpine:${ALPINE_VERSION} AS build

ARG ZAPRET_TAG
ARG CURL_VERSION
ARG TARGETPLATFORM

WORKDIR /opt

RUN wget -qO- "https://github.com/bol-van/zapret/releases/download/${ZAPRET_TAG}/zapret-${ZAPRET_TAG}.tar.gz" | tar xz && \
    mv zapret-* zapret && \
    /opt/zapret/install_bin.sh

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") ARCH="x86_64" ;; \
      "linux/arm64") ARCH="aarch64" ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -qO- "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-${ARCH}-glibc-${CURL_VERSION}.tar.xz" | tar -xJf - -C /opt && \
    chmod +x /opt/curl

FROM alpine:${ALPINE_VERSION}

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
    ipset \
    iptables \
    ip6tables \
    netcat-openbsd \
    shadowsocks-libev

EXPOSE 1080 8388

WORKDIR /opt

COPY --from=build /opt/zapret /opt/zapret
COPY --from=build /opt/curl /usr/bin/curl
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
