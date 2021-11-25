#!/bin/bash
while :
do
    read -p "是否要运行superspeed_uxh脚本?（y/N）:" skey
    case ${skey} in
    [yY])
        bash <(curl -Lso- https://git.io/superspeed_uxh)
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