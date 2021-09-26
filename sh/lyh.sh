#!/bin/bash
while :
do
    echo ""
    echo ""
    echo "功能列表:"
    echo "1.剧集重命名           2.内核自带bbr"
    echo "3.bbr多合一脚本        4.安装onelist"
    echo "5.安装rclone           6.linux关闭mail提示"
    echo "7.安装编译openwrt依赖  8.安装cuteone"
    echo "9.aria2管理面板        10.添加开机启动项"
    echo "11.x-ui面板            12.trojan面板"
    echo "13.LemonBench跑分      14.VPS跑分多合一"
    echo "15.修复Ubuntu中文乱码  16.流媒体解锁检测"
    echo "17.为ipv4 only服务器添加ipv6支持"
    echo "18.配置bash代理        19.安装lnmp"
    echo "20.获取网站SSL证书文件路径"
    echo "0.退出"
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
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/openwrt_require.sh)
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
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/x-ui_lyh.sh)
            ;;
        12)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/trojan.sh)
            ;;
        13)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/lemonbench.sh)
            ;;
        14)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/bench_all.sh)
            ;;
        15)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/fix_ubuntu_zhcn.sh)
            ;;
        16)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/media_check.sh)
            ;;
        17)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/ipv4only_enable_ipv6.sh)
            ;;
        18)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/set_bash_proxy.sh)
            ;;
        19)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/lnmp_lyh.sh)
            ;;
        20)
            bash <(curl -sL https://raw.githubusercontent.com/dayepao/backup/main/sh/get_cert_path.sh)
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done