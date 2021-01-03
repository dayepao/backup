#!/bin/bash
autostart(){
    echo "nohup uwsgi --ini ${installpath}/CuteOne/uwsgi.ini &" >> /etc/rc.d/rc.local
}


installCuteOne(){
git clone -b dev https://github.com/Hackxiaoya/CuteOne.git
cd CuteOne
bash install.sh
installpatht=${installpath//\//\\/}
sed -i "s/chdir = \/www\/wwwroot\/CuteOne/chdir = ${installpatht}\/CuteOne/g" uwsgi.ini
nohup uwsgi --ini uwsgi.ini &
sleep 2s
echo "请通过Nginx反向代理端口5000，访问 http://你的域名/admin/ 完成剩余安装步骤"
echo "如果访问不行，就执行：pgrep -f uwsgi 看看有没有运行起来"
echo "如果没有返回ID，就执行一下： nohup uwsgi --ini uwsgi.ini &"
echo "到驱动的位置添加个驱动，然后添加个网盘，然后更新一下缓存就可以了"
echo "如果后台账号密码不对，就用默认账号密码，都是admin"
echo "如果报错502，就是网站没启动"
while [ "$key2" != "y" ] && [ "$key2" != "n" ]
do
    read -p "是否配置CuteOne自启动?(y/n):" key2
done
if [ "${key2}" == "y" ];then
    autostart
    echo "自启动配置完成"
else
    exit 0
fi
}

while :
do
    read -p "是否要安装 cuteone ?（y/N）：" ckey
    case ${ckey} in
    [yY])
        echo "环境要求："
        echo "Linux
        Nginx
        Python3
        python-devel(例如dnf install python36-devel)
        Mysql >= 5.5
        MongoDB"


        while [ "${key1}" != "y" ] && [ "${key1}" != "n" ]
        do
            read -p "是否满足环境要求?(y/n):" key1
        done

        if [ "${key1}" == "y" ];then
            read -p "请输入要安装CuteOne的路径(例如/cuteone):" installpath
            mkdir ${installpath}
            chmod 777 ${installpath}
            cd ${installpath}
            installCuteOne
            echo "应用机密：u~52~hX5kRnrBQ7K_k6_3iLGRNWxo-18-B"
            echo "应用ID：b8e0db74-c8fa-4db3-8c48-3bac450f93b8"
        else
            exit 0
        fi
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