#!/bin/bash
while :
do
    read -p "是否要打开aria2管理面板?（y/N）:" arkey
    case ${arkey} in
    [yY])
        wget "https://raw.githubusercontent.com/P3TERX/aria2.sh/master/aria2.sh" -O aria2.sh
        bash aria2.sh
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