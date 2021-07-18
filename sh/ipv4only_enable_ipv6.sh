prefeipv6(){
    while :
    do
        echo ""
        echo "是否设置ipv6优先:"
        echo "1.设置ipv6优先"
        echo "2.取消ipv6优先"
        echo "0.退出"
        if grep -qE '^[ ]*label[ ]*2002::/16[ ]*2' /etc/gai.conf;then
            echo -e "当前状态:\033[32;1m ipv6优先 \033[0m"
        else
            echo -e "当前状态:\033[31;1m ipv4优先 \033[0m"
        fi
        read -p "请选择:" preferipv6key
        case ${preferipv6key} in
            1)
                grep -qE '^[ ]*label[ ]*2002::/16[ ]*2' /etc/gai.conf || echo 'label 2002::/16   2' | sudo tee -a /etc/gai.conf
                echo "设置完成"
                ;;
            2)
                sed -i "/^[ ]*label[ ]*2002::\/16[ ]*2/d" /etc/gai.conf
                echo "设置完成"
                ;;
            0)
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
}

configuration_wire­guard(){
    rm -rf wgcf-account.toml
    rm -rf wgcf-profile.conf
    systemctl stop wg-quick@wgcf
    systemctl disable wg-quick@wgcf
    systemctl daemon-reload
    systemctl reset-failed
    sudo apt install wireguard
    sudo apt install resolvconf
    curl -fsSL git.io/wgcf.sh | sudo bash
    wgcf register
    wgcf generate
    sed -i "s/engage.cloudflareclient.com/162.159.192.1/g" wgcf-profile.conf
    sed -i "/^.*AllowedIPs = 0.0.0.0\/0/d" wgcf-profile.conf
    sudo cp wgcf-profile.conf /etc/wireguard/wgcf.conf
    sudo wg-quick up wgcf
    curl -6 ip.p3terx.com
    while :
    do
        read -p "是否显示了ipv6地址?（y/n）:" ipv6key
        case ${ipv6key} in
            [yY])
                sudo wg-quick down wgcf
                sudo systemctl start wg-quick@wgcf
                sudo systemctl enable wg-quick@wgcf
                echo ""
                echo "已经正式启用 Wire­Guard 网络接口并设置开机启动"
                break 1
                ;;
            [nN])
                sudo wg-quick down wgcf
                echo "出现错误，已关闭 Wire­Guard 临时网络接口，请自行查找原因"
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
    prefeipv6
}

enableipv6(){
    key=$(command -v wg-quick)
    if [[ ${key} =~ "wg-quick" ]];then
        echo -e "Wire­Guard状态:\033[32;1m 已安装 \033[0m"
        while :
        do
            read -p "是否跳过配置Wire­Guard?（y/N）:" wgkey
            case ${wgkey} in
            [yY])
                prefeipv6
                break 1
                ;;
            [nN])
                configuration_wire­guard
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
            esac
        done
    else
        echo -e "Wire­Guard状态:\033[31;1m 未安装 \033[0m"
        configuration_wire­guard
    fi
}


while :
do
    read -p "是否要为ipv4 only服务器添加ipv6支持?（y/N）:" enableipv6key
    case ${enableipv6key} in
    [yY])
        enableipv6
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