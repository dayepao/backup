#!/bin/bash
makeservice(){
cat > /etc/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name}
After=network.target

[Service]
Type=forking
ExecStart=${todo}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ${service_name}
systemctl start ${service_name}
}

autorun(){
echo "$(date)"
#在此行后输入要开机自动运行的命令
}

service_name=${0%.*}
service_name=${service_name##*/}
todo="sudo bash $(pwd)/$0"

if [ ! -f /etc/systemd/system/${service_name}.service ];then
    makeservice
else
    autorun
fi
