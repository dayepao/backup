#!/bin/bash
autostart(){
wget "https://raw.githubusercontent.com/dayepao/backup/main/src/rclone.service" -O rclone.service
mv rclone.service /etc/systemd/system/rclone.service
systemctl enable rclone
systemctl start rclone
}

while :
do
    read -p "是否要安装并配置 rclone ?（y/N）：" rckey
    case ${rckey} in
        [yY])
            echo -e "\033[32;1m -----------------------开始安装fuse、zip-------------------------------- \033[0m"
            apt install -y fuse zip
            echo -e "\033[32;1m -----------------------开始安装rclone------------------------------ \033[0m"
            curl https://rclone.org/install.sh | sudo bash
            echo -e "\033[32;1m -----------------------开始配置rclone------------------------------ \033[0m"
            echo -e "\033[32;1m ----------Client ID（客户端 ID）：3d008f3b-d44f-47be-a3d6-a97440eb8917--------------- \033[0m"
            echo -e "\033[32;1m ----------Client secret（客户端密码）：6_?9I0rap?]ncqONc0p]Oba314JC4rwy--------------- \033[0m"
            echo -e "\033[31;1m [注意] \033[0m rclone配置文件name必须为onedrive才可以配置开机启动，否则需要修改\033[32;1m /etc/systemd/system/rclone.service \033[0m"
            read -p "按回车键继续"
            rclone config
            read -p "请输入要在本地挂载的路径(例如：/onedrive)：" mountpath
            mkdir ${mountpath}
            chmod 777 ${mountpath}
            while :
            do
                read -p "是否配置开机启动?（y/n）:" autostartkey
                case ${autostartkey} in
                    [yY])
                        autostart
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
            echo -e "安装完成，假如配置了开机启动，你可以输入\033[32;1m systemctl status rclone \033[0m查看运行情况"
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