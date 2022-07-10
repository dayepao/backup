#!/bin/bash
fix_onedrive(){
    git clone https://github.com/magnific0/wondershaper.git
    cd wondershaper
    rm -rf wondershaper.service
    wget "https://raw.githubusercontent.com/dayepao/backup/main/src/wondershaper.service" -O wondershaper.service
    wget "https://raw.githubusercontent.com/dayepao/backup/main/src/autowondershaper.sh" -O autowondershaper.sh
    mv wondershaper /usr/sbin/wondershaper
    mv wondershaper.service /etc/systemd/system/wondershaper.service
    mv autowondershaper.sh /root/autowondershaper.sh
    systemctl enable wondershaper
    systemctl start wondershaper
    cd ..
    rm -rf wondershaper
}
while :
do
    read -p "是否要修复斯巴达OneDrive上传问题?(y/N):" fkey
    case ${fkey} in
    [yY])
        fix_onedrive
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