#!/bin/bash
makeservice(){
read -p "请输入要创建的service名称：" service_name
read -p "请输入service要执行的命令：" todo
cat > /etc/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name}
After=network.target

[Service]
Type=simple
ExecStart=${todo}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ${service_name}
systemctl start ${service_name}
}

while :
do
    read -p "是否要添加开机启动项?（y/N）:" skey
    case ${skey} in
    [yY])
        makeservice
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