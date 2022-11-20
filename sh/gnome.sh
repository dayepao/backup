#!/bin/bash
while :
do
    echo "1.安装GNOME桌面，并配置自动登录root用户"
    echo "2.卸载GNOME桌面"
    echo "0.退出"
    read -p "请选择操作:" gkey
    case ${gkey} in
        1)
            apt install task-gnome-desktop
            sed -i "/AutomaticLoginEnable =/cAutomaticLoginEnable = true" /etc/gdm3/daemon.conf
            sed -i "/AutomaticLogin =/cAutomaticLogin = root" /etc/gdm3/daemon.conf
            sed -i "/AllowRoot/d" /etc/gdm3/daemon.conf
            sed -i "/\[security\]/aAllowRoot = true" /etc/gdm3/daemon.conf
            sed -i '/user != root/ s/^\([^#].*\)$/# \1/g' /etc/pam.d/gdm-password
            sed -i '/user != root/ s/^\([^#].*\)$/# \1/g' /etc/pam.d/gdm-autologin
            sudo startx >/dev/null 2>&1 &
            sleep 5
            export DISPLAY=:0
            gtk-launch gnome-control-center >/dev/null 2>&1 &
            gsettings set "org.gnome.settings-daemon.plugins.power" sleep-inactive-ac-type "nothing"
            gsettings set "org.gnome.settings-daemon.plugins.power" sleep-inactive-battery-type "nothing"
            gsettings set "org.gnome.settings-daemon.plugins.power" power-button-action "interactive"
            gsettings set "org.gnome.desktop.session" idle-delay 0
            ;;
        2)
            apt purge gdm3
            apt purge gnome*
            apt autopurge
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