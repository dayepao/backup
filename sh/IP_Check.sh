#!/bin/bash
while :
do
    read -p "是否要测试IP质量?(y/N):" key
    case ${key} in
    [yY])
        bash <(curl -Ls IP.Check.Place)
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