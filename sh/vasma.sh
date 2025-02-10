#!/bin/bash
while :
do
    read -p "是否要安装 科学上网一键脚本 ?(y/N):" xkey
    case ${xkey} in
    [yY])
        wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
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