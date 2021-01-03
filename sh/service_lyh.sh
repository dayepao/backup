#!/bin/bash
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