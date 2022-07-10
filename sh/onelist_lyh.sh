#!/bin/bash
autostart(){
cat > /etc/systemd/system/onelist.service <<EOF
[Unit]
Description=onelist
After=network.target

[Service]
Type=simple
ExecStart=${startcommand}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


systemctl enable onelist
systemctl start onelist
}

startonelist(){
    while :
    do
        read -p "是否配置开机启动?(y/N):" autostartkey
        case ${autostartkey} in
            [yY])
                autostart
                break 1
                ;;
            [nN])
                nohup ${startcommand} >/dev/null 2>&1 &
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
}

modifyconf(){
    while :
    do
        echo ""
        echo "修改配置文件: "
        echo "1.修改读取OneDrive根目录（支持根目录\"/\"）"
        echo "2.修改隐藏目录"
        echo "3.修改加密目录"
        echo "0.退出"
        read -p "请选择: " mokey
        case ${mokey} in
            1)
                echo ""
                echo -e "\033[31;1m [警告] \033[0m 此操作会覆盖原有配置"
                echo -ne "\033[32;1m 当前配置为 \033[0m"
                grep "RootPath" config.json
                read -p "请输入要设为onelist列表根目录的OneDrive目录, 例如/test: " rootpath
                rootpatht=${rootpath//\//\\/}
                sed -i "s/^[ ]*\"RootPath\":.*$/\ \ \ \ \"RootPath\": \"${rootpatht}\",/g" config.json
                echo ""
                echo -ne "修改完成,\033[32;1m 修改后配置为 \033[0m"
                grep "RootPath" config.json
                echo ""
                ;;
            2)
                echo ""
                echo -e "\033[31;1m [警告] \033[0m 此操作会覆盖原有配置"
                echo -ne "\033[32;1m 当前配置为 \033[0m"
                grep "HidePath" config.json
                echo "条目之间用\"|\"分隔, 例如/Test/path01|/Test/file02"
                read -p "请输入要隐藏的目录: " hidepath
                hidepatht=${hidepath//\//\\/}
                sed -i "s/^[ ]*\"HidePath\":.*$/\ \ \ \ \"HidePath\": \"${hidepatht}\",/g" config.json
                echo ""
                echo -ne "修改完成,\033[32;1m 修改后配置为 \033[0m"
                grep "HidePath" config.json
                echo ""
                ;;
            3)
                echo ""
                echo -e "\033[31;1m [警告] \033[0m 此操作会覆盖原有配置"
                echo -ne "\033[32;1m 当前配置为 \033[0m"
                grep "AuthPath" config.json
                echo "目录和用户名密码间使用 \"?\" 分割, 用户名密码使用 \":\" 分割, 条目间使用 \"|\" 分割"
                echo "例如/Test/Auth01?user01:pwd01|/Test/Auth02?user02:pwd02"
                read -p "请输入要加密的目录: " authpath
                authpatht=${authpath//\//\\/}
                sed -i "s/^[ ]*\"AuthPath\":.*$/\ \ \ \ \"AuthPath\": \"${authpatht}\",/g" config.json
                echo ""
                echo -ne "修改完成,\033[32;1m 修改后配置为 \033[0m"
                grep "AuthPath" config.json
                echo ""
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


installonelist(){
    echo -e "\033[31;1m 国际版, 个人版(家庭版) \033[0m"
    echo "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=78d4dc35-7e46-42c6-9023-2d39314433a5&response_type=code&redirect_uri=http://localhost/onedrive-login&response_mode=query&scope=offline_access%20User.Read%20Files.ReadWrite.All"
    echo -e "\033[31;1m 中国版(世纪互联) \033[0m"
    echo "https://login.chinacloudapi.cn/common/oauth2/v2.0/authorize?client_id=dfe36e60-6133-48cf-869f-4d15b8354769&response_type=code&redirect_uri=http://localhost/onedrive-login&response_mode=query&scope=offline_access%20User.Read%20Files.ReadWrite.All"
    echo "请复制好localhost开头打不开的链接"
    read -p "请输入复制的localhost开头打不开的链接: " url
    read -p "请输入安装onelist的路径: " installpath
    read -p "请指定网盘地址后缀, 比如http://domain.com/onedrive, 请输入/onedrive。(可以为/):" urlpath


    mkdir ${installpath}
    chmod 777 ${installpath}
    mv $0 ${installpath}
    echo -e "\033[31;1m [注意] \033[0m 此脚本已被移动至所选安装路径"
    cd ${installpath}


    echo ""
    echo "请选择系统架构"
    echo "1.64位linux系统"
    echo "2.32位linux系统"
    echo "3.arm架构系统"
    while :
    do
        read -p "请选择（1、2、3）: " key2
        case ${key2} in
            1)
                wget "https://raw.githubusercontent.com/MoeClub/OneList/master/Rewrite/amd64/linux/OneList"
                break 1
                ;;
            2)
                wget "https://raw.githubusercontent.com/MoeClub/OneList//master/Rewrite/i386/linux/OneList"
                break 1
                ;;
            3)
                wget "https://raw.githubusercontent.com/MoeClub/OneList/master/Rewrite/arm/linux/OneList"
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
    chmod +x OneList


    echo ""
    echo "请选择onedrive版本: "
    echo "1.国际版"
    echo "2.个人版（家庭版）"
    echo "3.中国版(世纪互联)"
    while :
    do
        read -p "请选择（1、2、3）: " key3
        case ${key3} in
            1)
                ./OneList -a "$url" -s "$urlpath"
                break 1
                ;;
            2)
                ./OneList -ms -a "$url" -s "$urlpath"
                break 1
                ;;
            3)
                ./OneList -cn -a "$url" -s "$urlpath"
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done


    modifyconf


    wget "https://raw.githubusercontent.com/MoeClub/OneList/master/Rewrite/%40Theme/HaorWu/index.html" -O index.html


    read -p "请输入要监听的端口: " port


    while :
    do
        read -p "是否启用cdn代理?(y/N): " cdnkey
        case ${cdnkey} in
            [yY])
                read -p "请输入你的SharePoint域名（XXX-my.sharepoint.com）: " cdn1
                read -p "请输入你的加速域名（xxx.example.com）: " cdn2
                startcommand="${installpath}/OneList -bind 0.0.0.0 -port ${port} -P \"${cdn1}|${cdn2}\""
                startonelist
                break 1
                ;;
            [nN])
                startcommand="${installpath}/OneList -bind 0.0.0.0 -port ${port}"
                startonelist
                break 1
                ;;
            *)
                echo -e "\033[31;1m [错误] \033[0m 请重新输入"
                ;;
        esac
    done
    
    
    echo "onelist部署完成, 请访问http://IP:${port}"
    echo "刚启动会加载列表, 如果提示No Found请稍等一会"
    echo "若已设置自启, 可输入 systemctl status onelist 查看状态"
    echo -e "\033[31;1m [注意] \033[0m 请不要忘记开放${port}端口"
}


echo ""
echo "请选择操作: "
echo "1.安装并配置onelist"
echo "2.修改onelist配置文件"
echo "0.退出"
while :
do
    read -p "请选择: " key1
    case ${key1} in
        1)
            installonelist
            break 1
            ;;
        2)
            modifyconf
            break 1
            ;;
        0)
            break 1
            ;;
        *)
            echo -e "\033[31;1m [错误] \033[0m 请重新输入"
            ;;
    esac
done