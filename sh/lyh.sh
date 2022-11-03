#!/bin/bash
while :
do
    echo ""
    echo ""
    echo -e "\033[32;1m功能列表:\033[0m"
    
    echo "*********************************************************************"
    echo "0.退出"

    echo -e "\033[32;1m工具:\033[0m"
    echo "001.剧集重命名                      002.安装onelist"
    echo "003.安装rclone                      004.安装编译openwrt依赖"
    echo "005.安装cuteone                     006.aria2管理面板"
    echo "007.为IPv4 only服务器添加IPv6支持   008.修复Ubuntu中文乱码"
    echo "009.重新安装vim                     010.添加开机启动项"
    echo "011.配置bash代理                    012.添加hostname解析"

    echo -e "\033[32;1mVPS配置:\033[0m"
    echo "101.内核自带bbr                     102.bbr多合一脚本"
    echo "103.配置IPv4或IPv6优先              104.修复斯巴达同网段路由问题"
    echo "105.阻止Plex本地网络发现功能        106.linux关闭mail提示"
    echo "107.斯巴达DD后添加IPv6              108.PVE配置UPS连接"

    echo -e "\033[32;1mVPS测试:\033[0m"
    echo "201.LemonBench跑分                  202.superspeed_uxh脚本"
    echo "203.流媒体解锁检测"

    echo -e "\033[32;1m科学:\033[0m"
    echo "301.安装lnmp                        302.获取网站SSL证书文件路径"
    echo "303.x-ui面板                        304.trojan面板"
    
    echo "*********************************************************************"
    read -p "请输入序号:" shkey
    case ${shkey} in
        0)
            break 1
            ;;
        001)
            bash <(curl -sL https://sh.dayepao.com/rename_lyh.sh)
            ;;
        002)
            bash <(curl -sL https://sh.dayepao.com/onelist_lyh.sh)
            ;;
        003)
            bash <(curl -sL https://sh.dayepao.com/rclone_lyh.sh)
            ;;
        004)
            bash <(curl -sL https://sh.dayepao.com/openwrt_require.sh)
            ;;
        005)
            bash <(curl -sL https://sh.dayepao.com/cuteone_lyh.sh)
            ;;
        006)
            bash <(curl -sL https://sh.dayepao.com/aria2_lyh.sh)
            rm -rf aria2.sh
            ;;
        007)
            bash <(curl -sL https://sh.dayepao.com/ipv4only_enable_ipv6.sh)
            ;;
        008)
            bash <(curl -sL https://sh.dayepao.com/fix_ubuntu_zhcn.sh)
            ;;
        009)
            bash <(curl -sL https://sh.dayepao.com/reinstall_vim.sh)
            ;;
        010)
            bash <(curl -sL https://sh.dayepao.com/service_lyh.sh)
            ;;
        011)
            bash <(curl -sL https://sh.dayepao.com/set_bash_proxy.sh)
            ;;
        012)
            bash <(curl -sL https://sh.dayepao.com/add_hostname_to_hosts.sh)
            ;;
        101)
            bash <(curl -sL https://sh.dayepao.com/bbr_lyh.sh)
            ;;
        102)
            bash <(curl -sL https://sh.dayepao.com/bbr_all.sh)
            ;;
        103)
            bash <(curl -sL https://sh.dayepao.com/prefer_ipv4_or_ipv6.sh)
            ;;
        104)
            bash <(curl -sL https://sh.dayepao.com/fix_spt_route.sh)
            ;;
        105)
            bash <(curl -sL https://sh.dayepao.com/prevent_plex_discovery.sh)
            ;;
        106)
            bash <(curl -sL https://sh.dayepao.com/stopmail_lyh.sh)
            ;;
        107)
            bash <(curl -sL https://sh.dayepao.com/spt_add_netplan_ipv6.sh)
            ;;
        108)
            bash <(curl -sL https://sh.dayepao.com/pve_ups.sh)
            ;;
        201)
            bash <(curl -sL https://sh.dayepao.com/lemonbench.sh)
            ;;
        202)
            bash <(curl -sL https://sh.dayepao.com/superspeed_uxh.sh)
            ;;
        203)
            bash <(curl -sL https://sh.dayepao.com/media_check.sh)
            ;;
        301)
            bash <(curl -sL https://sh.dayepao.com/lnmp_lyh.sh)
            break 1
            ;;
        302)
            bash <(curl -sL https://sh.dayepao.com/get_cert_path.sh)
            ;;
        303)
            bash <(curl -sL https://sh.dayepao.com/x-ui_lyh.sh)
            ;;
        304)
            bash <(curl -sL https://sh.dayepao.com/trojan.sh)
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done