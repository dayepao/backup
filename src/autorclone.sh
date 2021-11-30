#!/bin/bash
NAME="onedrive"
REMOTE="VPS"
LOCAL="/onedrive"
PARAMETER="--contimeout=5s --tpslimit 10 --tpslimit-burst 30 --timeout=10s --transfers 8 --buffer-size 128M --low-level-retries 10 --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit 1G --vfs-cache-mode writes"
case $1 in
    start)
        fusermount -zu ${LOCAL} >/dev/null 2>&1
        if [[ $(pgrep rclone) == "" ]];then
            rm -rf ${LOCAL}
        fi
        mkdir -p ${LOCAL}
        rclone mount ${NAME}:${REMOTE} ${LOCAL} ${PARAMETER} --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000
        ;;
    stop)
        fusermount -zu ${LOCAL} >/dev/null 2>&1
        sleep 5
        ;;
    check)
        rclone_log=$(journalctl -b -u rclone -n 3)
        if [[ ${rclone_log} =~ "10/10" ]] || [[ ${rclone_log} =~ "cannot create directory" ]];then
            sleep 30
            systemctl restart rclone
        fi
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 参数错误"
        ;;
esac
