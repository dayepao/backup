#!/bin/bash
NAME="onedrive"
REMOTE="VPS"
LOCAL="/onedrive"
PARAMETER="--contimeout=10s --timeout=30s --transfers 20 --vfs-cache-mode writes"
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