#!/usr/bin/env sh

sed -i "s/UUID/$UUID/g" /app/xy/config.json
sed -i "s/DOMAIN/$DOMAIN/g" /app/keepalive.sh

cp /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

nohup cf tunnel run --token eyJhIjoiOWRhNWIzNTJmNTc0MmJjOGExOWVkOWI0MjUwZWZmZGQiLCJ0IjoiM2IzYzU4ZDAtZDkxNy00Mjk3LTk5NmEtMGQ2NjhiN2NjYmY2IiwicyI6Ik1qa3pNell6TURBdE5qTTJOQzAwTVdOa0xXSmxZak10T0Rka09UY3dPVGczWldRNSJ9 >/dev/null 2>&1 &
nohup et -l ws://:2096 -token sliao530 >/dev/null 2>&1 &

# (crontab -l 2>/dev/null; echo "*/5 * * * * /app/keepalive.sh") | crontab -

exec "$@"
