#!/bin/bash
read -p "请输入网站的域名: " vhost_name
path_to_vhost_config="/usr/local/nginx/conf/vhost/${vhost_name}.conf"
cert_path=$(grep -E "^ *ssl_certificate " ${path_to_vhost_config} | sed 's/ *ssl_certificate //g' | sed 's/;//g')
key_path=$(grep -E "^ *ssl_certificate_key " ${path_to_vhost_config} | sed 's/ *ssl_certificate_key //g' | sed 's/;//g')
echo -e "证书公钥文件路径为:\033[32;1m ${cert_path} \033[0m"
echo -e "证书密钥文件路径为:\033[32;1m ${key_path} \033[0m"
