#!/bin/bash
while :
do
    echo ""
    echo ""
    echo "功能列表:"
    echo "1.剧集重命名           2.内核自带bbr"
    echo "3.一键bbr脚本          4.安装onelist"
    echo "5.安装rclone           6.linux关闭mail提示"
    echo "7.编译openwrt依赖      8.安装cuteone"
    echo "9.aria2管理面板        10.添加开机启动项"
    echo "11.v2-ui面板           12.trojan面板"
    echo "13.LemonBench跑分      14.VPS跑分多合一"
    echo "15.修复Ubuntu中文乱码  0.退出"
    read -p "请输入序号:" shkey
    case ${shkey} in
        0)
            break 1
            ;;
        1)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/rename_lyh.sh)
            ;;
        2)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/bbr_lyh.sh)
            ;;
        3)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/bbr_all.sh)
            ;;
        4)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/onelist_lyh.sh)
            ;;
        5)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/rclone_lyh.sh)
            ;;
        6)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/stopmail_lyh.sh)
            ;;
        7)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/require.sh)
            ;;
        8)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/cuteone_lyh.sh)
            ;;
        9)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/aria2_lyh.sh)
            rm -rf aria2.sh
            ;;
        10)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/service_lyh.sh)
            ;;
        11)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/v2ui_lyh.sh)
            rm -rf v2ui_install.sh
            ;;
        12)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/trojan.sh)
            ;;
        13)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/bench_lyh.sh)
            rm -rf LemonBench.Result.txt
            ;;
        14)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/speedtest.sh)
            rm -rf vpsTest
            ;;
        15)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/fix_ubuntu_zhcn.sh)
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done