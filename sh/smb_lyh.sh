#!/bin/bash
MOUNT_PATHS=("nas_m2" "nas")
# MOUNT_PATHS=("nas")

CUR_MOUNT_PATHS=()
for cur_mount_path in $(grep "^[^#]*//192.168.1.3" /etc/fstab | sed "s/^ //g" | sed "s/\/\/192.168.1.3\/.* \(\/mnt\/.*\) cifs.*/\1/g")
do
    CUR_MOUNT_PATHS[${#CUR_MOUNT_PATHS[*]}]=${cur_mount_path}
done

while :
do
    echo "1.配置SMB挂载"
    echo "2.清除SMB挂载"
    echo "0.退出"
    read -p "请选择操作: " skey
    case ${skey} in
        1)
            echo -e "\033[32;1m -----------------------安装SMB组件并创建共享目录-------------------------------- \033[0m"
            apt install -y cifs-utils
            for mount_path in ${MOUNT_PATHS[*]}
            do
                mkdir /mnt/${mount_path}
            done
            echo -e "\033[32;1m -----------------------创建密码文件------------------------------ \033[0m"
            read -p "请输入 SMB 用户名: " username
            read -p "请输入 SMB 密码: " password
            echo "username=${username}" > /root/.nassmb
            echo "password=${password}" >> /root/.nassmb
            echo -e "\033[32;1m -----------------------设置开机自动挂载 SMB------------------------------ \033[0m"
            for mount_path in ${MOUNT_PATHS[*]}
            do
                if ! [[ ${CUR_MOUNT_PATHS[*]} =~ "/mnt/${mount_path}" ]];then
                    echo "//192.168.1.3/${mount_path} /mnt/${mount_path} cifs rw,dir_mode=0777,file_mode=0777,credentials=/root/.nassmb,nobrl" >> /etc/fstab
                fi
            done
            wget "https://raw.githubusercontent.com/dayepao/backup/main/src/autosmb.sh" -O autosmb.sh
            mv autosmb.sh /root/autosmb.sh
            if [[ $(grep "/root/autosmb.sh check" /etc/crontab) == "" ]];then
                echo "*/1 * * * * root /usr/bin/bash /root/autosmb.sh check" >> /etc/crontab
            fi
            /usr/bin/bash /root/autosmb.sh start
            echo -e "\033[32;1m -----------------------配置 SMB 挂载完成------------------------------ \033[0m"
            echo "SMB 挂载目录:"
            for mount_path in ${MOUNT_PATHS[*]}
            do
                echo "/mnt/${mount_path}"
            done
            break 1
            ;;
        2)
            sed -i "/autosmb.sh check/d" /etc/crontab
            MOUNT_PATHS=()
            for mount_path in $(grep "^[^#]*//192.168.1.3" /etc/fstab | sed "s/^ //g" | sed "s/\/\/192.168.1.3\/.* \(\/mnt\/.*\) cifs.*/\1/g")
            do
                MOUNT_PATHS[${#MOUNT_PATHS[*]}]=${mount_path}
            done

            for mount_path in ${MOUNT_PATHS[*]}
            do
                echo "umount ${mount_path}"
                umount ${mount_path}
                sed -i "/${mount_path//\//\\/}/d" /etc/fstab
                if [[ $(mount | grep ${mount_path}) == "" ]];then
                    rm -rf ${mount_path}
                fi
            done
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