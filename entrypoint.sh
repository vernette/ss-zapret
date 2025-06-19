#!/usr/bin/env sh

/opt/zapret/init.d/sysv/zapret start

if [ "${SS_VERBOSE:-1}" = "0" ]; then
  exec >/dev/null 2>&1
fi

ss-local -b 0.0.0.0 -s 127.0.0.1 -p "${SS_PORT}" -l "${SOCKS_PORT}" -k "${SS_PASSWORD}" -m "${SS_ENCRYPT_METHOD}" -t "${SS_TIMEOUT}" -u &
exec ss-server -s 0.0.0.0 -p "${SS_PORT}" -k "${SS_PASSWORD}" -m "${SS_ENCRYPT_METHOD}" -t "${SS_TIMEOUT}" -u
