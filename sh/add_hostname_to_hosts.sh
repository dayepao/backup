#!/bin/bash
while :
do
    read -p "是否要添加hostname解析?(y/N):" ahkey
    case ${ahkey} in
    [yY])
        hostname=$(hostname)
        nline=$(sed -n "/^127\.0\.0\.1.localhost/p" /etc/hosts | sed "s/localhost/${hostname}/g")
        grep -q "${nline}" /etc/hosts || sed -i "/^127\.0\.0\.1.localhost/a${nline}" /etc/hosts
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