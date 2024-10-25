FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y ipset curl dnsutils git shadowsocks-libev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --depth 1 https://github.com/bol-van/zapret

RUN /opt/zapret/install_bin.sh && \
    cp /opt/zapret/config.default /opt/zapret/config && \
    cp /opt/zapret/ipset/zapret-hosts-user-exclude.txt.default /opt/zapret/ipset/zapret-hosts-user-exclude.txt && \
    echo nonexistent.domain > /opt/zapret/ipset/zapret-hosts-user.txt && \
    touch /opt/zapret/ipset/zapret-hosts-user-ipban.txt

CMD ["/bin/bash", "-c", "/opt/zapret/init.d/sysv/zapret start && sleep 3 && exec ss-server -v -s $SS_SERVER_HOST -p $SS_SERVER_PORT -k $SS_PASSWORD -m $SS_ENCRYPT_METHOD -t $SS_TIMEOUT -u"]