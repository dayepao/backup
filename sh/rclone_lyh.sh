#!/bin/bash
autostart(){
wget "https://raw.githubusercontent.com/dayepao/backup/main/src/rclone.service" -O rclone.service
wget "https://raw.githubusercontent.com/dayepao/backup/main/src/autorclone.sh" -O autorclone.sh
mv rclone.service /etc/systemd/system/rclone.service
mv autorclone.sh /root/autorclone.sh
read -p "请输入远程文件夹路径(例如: VPS): " remotepath
rclonename=$(grep "\[" /root/.config/rclone/rclone.conf)
rclonename=${rclonename//\[/}
rclonename=${rclonename//\]/}

sed -i "s/NAME=\"onedrive\"/NAME=\"${rclonename}\"/g" /root/autorclone.sh
sed -i "s/REMOTE=\"VPS\"/REMOTE=\"${remotepath//\//\\/}\"/g" /root/autorclone.sh
sed -i "s/LOCAL=\"\/onedrive\"/LOCAL=\"${mountpath//\//\\/}\"/g" /root/autorclone.sh
systemctl enable rclone
systemctl start rclone
echo "*/1 * * * * /usr/bin/bash /root/autorclone.sh check" >> /var/spool/cron/crontabs/root
crontab /var/spool/cron/crontabs/root
}

while :
do
    read -p "是否要安装并配置 rclone ?(y/N): " rckey
    case ${rckey} in
        [yY])
            echo -e "\033[32;1m -----------------------开始安装fuse、zip-------------------------------- \033[0m"
            apt install -y fuse zip
            echo -e "\033[32;1m -----------------------开始安装rclone------------------------------ \033[0m"
            curl https://rclone.org/install.sh | sudo bash
            echo -e "\033[32;1m -----------------------开始配置rclone------------------------------ \033[0m"
            # echo -e "\033[32;1m ----------Client ID（客户端 ID）: 3d008f3b-d44f-47be-a3d6-a97440eb8917--------------- \033[0m"
            # echo -e "\033[32;1m ----------Client secret（客户端密码）: 6_?9I0rap?]ncqONc0p]Oba314JC4rwy--------------- \033[0m"
            read -p "按回车键继续"
            rclone config
            while :
            do
                read -p "是否配置开机启动?(y/N):" autostartkey
                case ${autostartkey} in
                    [yY])
                        read -p "请输入要在本地挂载的路径(例如: /onedrive): " mountpath
                        mkdir ${mountpath}
                        chmod 777 ${mountpath}
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
            echo -e "安装完成, 假如配置了开机启动, 你可以输入\033[32;1m systemctl status rclone \033[0m查看运行情况"
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