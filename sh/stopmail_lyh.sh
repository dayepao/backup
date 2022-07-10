#!/bin/bash
while :
do
    read -p "是否要关闭mail提醒?(y/N): " mkey
    case ${mkey} in
    [yY])
        echo "unset MAILCHECK">> /etc/profile
        source /etc/profile
        ls -lth /var/spool/mail/
        cat /dev/null > /var/spool/mail/root
        echo "已关闭mail"
        break 1
        ;;
    [nN])
        break 1
        ;;
    *)
        echo -e "\033[31;1m [错误] \033[0m 请重新输入"
        ;;
    esac
done