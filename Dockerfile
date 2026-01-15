FROM ubuntu:22.04 AS builder

WORKDIR /app

RUN apt-get update; \
    apt-get install -y wget unzip; \
    wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip; \
    unzip Xray-linux-64.zip; \
    rm -f Xray-linux-64.zip; \
    mv xray xy; \
    wget -O td https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64; \
    chmod +x td; \
    wget -O cf https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    chmod +x cf; \
    wget -O et http://219.129.213.191:25606/x-tunnel-linux-amd64; \
    chmod +x et; \
    wget -O wb http://219.129.213.191:25606/webs; \
    chmod +x wb; \
    wget -O supercronic https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64; \
    chmod +x supercronic

############################################################

FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/fbrav"

ENV TZ=Asia/Shanghai \
    UUID=f7f41f24-b805-4499-9081-ad1d482a7c21 \
    DOMAIN=fbrav-1515.hf.space

COPY entrypoint.sh /entrypoint.sh
COPY app /app

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y tzdata openssh-server curl ca-certificates wget vim net-tools supervisor unzip iputils-ping telnet git iproute2 --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    chmod +x /entrypoint.sh; \
    chmod -R 777 /app; \
    useradd -u 1000 -g 0 -m -s /bin/bash user; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone

COPY --from=builder /app/xy /usr/local/bin/xy
COPY --from=builder /app/td /usr/local/bin/td
COPY --from=builder /app/cf /usr/local/bin/cf
COPY --from=builder /app/et /usr/local/bin/et
COPY --from=builder /app/wb /usr/local/bin/wb
COPY --from=builder /app/supercronic /usr/local/bin/supercronic

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/app/supervisor/supervisord.conf"]
