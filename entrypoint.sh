#!/usr/bin/env sh

/opt/zapret/init.d/sysv/zapret start

ss-local -b 0.0.0.0 -s 127.0.0.1 -p "${SS_PORT}" -l "${SOCKS_PORT}" -k "${SS_PASSWORD}" -m "${SS_ENCRYPT_METHOD}" -t "${SS_TIMEOUT}" -u &

case "${SS_VERBOSE:-1}" in
  0)
    VERBOSE_FLAG=""
    ;;
  *)
    VERBOSE_FLAG="-v"
    ;;
esac

exec ss-server "${VERBOSE_FLAG}" -s 0.0.0.0 -p "${SS_PORT}" -k "${SS_PASSWORD}" -m "${SS_ENCRYPT_METHOD}" -t "${SS_TIMEOUT}" -u
