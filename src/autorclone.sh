#!/bin/bash
NAME="onedrive"
REMOTE="VPS"
LOCAL="/onedrive"
PARAMETER="--contimeout=5s --tpslimit 60 --tpslimit-burst 30 --timeout=10s --transfers 20 --buffer-size 256M --low-level-retries 200 --vfs-read-chunk-size 256M --vfs-read-chunk-size-limit 1G --vfs-cache-mode writes"
case $1 in
    start)
        fusermount -u ${LOCAL} >/dev/null 2>&1
        mkdir -p ${LOCAL}
        rclone mount ${NAME}:${REMOTE} ${LOCAL} ${PARAMETER} --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000
        ;;
    stop)
        fusermount -u ${LOCAL} >/dev/null 2>&1
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 参数错误"
        ;;
esac