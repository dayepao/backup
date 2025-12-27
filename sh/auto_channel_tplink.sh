#!/bin/sh

# ================= 参数获取与检查 =================
TPLINK_MAC="$1"             # 从第一个参数获取 TP-Link 路由器 MAC 地址
TPLINK_PWD="$2"             # 从第二个参数获取 TP-Link 路由器加密后的密码
TARGET_LOW="${3:-44}"       # 从第三个参数获取目标低频段信道，默认为 44
TARGET_HIGH="${4:-153}"     # 从第四个参数获取目标高频段信道，默认为 153
CAMPUS_IF="${5:-phy0-sta0}" # 从第五个参数获取校园网接口名称，默认为 phy0-sta0

# F12抓包 或 控制台执行 orgAuthPwd("password") 获取加密后的密码
if [ -z "$TPLINK_PWD" ]; then
    echo "错误: 未提供 TP-Link 路由器加密后的密码。"
    echo "用法: $0 <mac_address> <encrypted_password> [target_low] [target_high] [campus_interface]"
    echo "示例: $0 ff:ff:ff:ff:ff:ff encrypted_password 44 153 phy0-sta0"
    exit 1
fi

log() {
    # echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    logger "auto_channel_tplink: $1"
}

# ================= 核心功能函数 =================

# 根据 MAC 地址获取 IP
get_ip_by_mac() {
    local target_mac=$(echo "$1" | tr 'A-Z' 'a-z') # 转为小写，防止大小写不匹配
    local found_ip=""

    # 优先查 ARP 表 (最准确，代表设备在线)
    # /proc/net/arp 格式: IP address ... HW address ...
    found_ip=$(awk -v mac="$target_mac" 'tolower($0) ~ mac {print $1; exit}' /proc/net/arp)

    # 如果 ARP 表里没有，查 DHCP 租约表 (作为备选)
    if [ -z "$found_ip" ]; then
        # /tmp/dhcp.leases 格式: timestamp mac ip ...
        found_ip=$(awk -v mac="$target_mac" 'tolower($0) ~ mac {print $3; exit}' /tmp/dhcp.leases 2>/dev/null)
    fi

    echo "$found_ip"
}

# 获取校园网当前信道
get_campus_channel() {
    # 逻辑: 匹配 "Channel: 数字", 提取数字
    local chan=$(iwinfo "$CAMPUS_IF" info | grep -oE 'Channel: [0-9]+' | awk '{print $2}' | head -n 1)
    echo "$chan"
}

# TP-Link 登录，获取 Token
tplink_login() {
    log "正在登录 TP-Link 后台..."
    local token=$(curl -s -H "Content-Type: application/json" -X POST "http://$TPLINK_IP" -d "{\"method\":\"do\",\"login\":{\"password\":\"$TPLINK_PWD\"}}" | jsonfilter -e '@.stok')
    echo "$token"
}

# TP-Link 获取当前信道 (仅提取信道数字，用于判断)
tplink_get_channel() {
    # 注意：这里我们只取 channel 字段用于比较
    current_ch=$(curl -s -H "Content-Type: application/json" -X POST "http://$TPLINK_IP/stok=$TOKEN/ds" -d "{\"wireless\":{\"name\":[\"wlan_host_5g\"]},\"method\":\"get\"}" | jsonfilter -e '@.wireless.wlan_host_5g.channel')
    echo "$current_ch"
}

# TP-Link 设置新信道 (读取关键配置 -> 手动拼接洁净JSON -> 推送)
tplink_set_channel() {
    local new_ch="$1"

    log "准备将 TP-Link 信道修改为: $new_ch"

    # A. 获取完整的 5G 配置 JSON 对象
    # jsonfilter -e '@.wireless.wlan_host_5g' 会输出整个对象的 JSON 字符串，例如: {"enable":1, "channel":149, "ssid":"xxx"...}
    log "步骤 1/3: 拉取当前配置信息..."
    CURRENT_CONFIG=$(curl -s -H "Content-Type: application/json" -X POST "http://$TPLINK_IP/stok=$TOKEN/ds" -d "{\"wireless\":{\"name\":[\"wlan_host_5g\"]},\"method\":\"get\"}" | jsonfilter -e '@.wireless.wlan_host_5g')

    if [ -z "$CURRENT_CONFIG" ]; then
        log "错误: 无法拉取到无线配置，放弃修改。"
        return 1
    fi

    # B. 提取关键参数 (使用 jsonfilter)
    # 这一步是为了“保活”，确保发回去的包里，SSID和密码还是原来的
    local enable=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.enable')
    local ssid=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.ssid')
    local key=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.key')
    local auth=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.auth')
    local ssidbrd=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.ssidbrd')
    local encryption=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.encryption')
    # 跳过 channel
    local mode=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.mode')
    local bandwidth=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.bandwidth')
    local twt=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.twt')
    local ofdma=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.ofdma')
    local vhtmubfer=$(echo "$CURRENT_CONFIG" | jsonfilter -e '@.vhtmubfer')

    # 防止提取为空的保护措施 (若为空则警告并退出脚本)
    [ -z "$enable" ] && {
        log "警告: 无法提取 enable 参数。"
        exit 1
    }
    [ -z "$ssid" ] && {
        log "警告: 无法提取 ssid 参数。"
        exit 1
    }
    [ -z "$key" ] && {
        log "警告: 无法提取 key 参数。"
        exit 1
    }
    [ -z "$auth" ] && {
        log "警告: 无法提取 auth 参数。"
        exit 1
    }
    [ -z "$ssidbrd" ] && {
        log "警告: 无法提取 ssidbrd 参数。"
        exit 1
    }
    [ -z "$encryption" ] && {
        log "警告: 无法提取 encryption 参数。"
        exit 1
    }
    [ -z "$mode" ] && {
        log "警告: 无法提取 mode 参数。"
        exit 1
    }
    [ -z "$bandwidth" ] && {
        log "警告: 无法提取 bandwidth 参数。"
        exit 1
    }
    [ -z "$twt" ] && {
        log "警告: 无法提取 twt 参数。"
        exit 1
    }
    [ -z "$ofdma" ] && {
        log "警告: 无法提取 ofdma 参数。"
        exit 1
    }
    [ -z "$vhtmubfer" ] && {
        log "警告: 无法提取 vhtmubfer 参数。"
        exit 1
    }

    # C. 手动拼接 JSON (严格按照抓包的格式：数字不带引号，字符串带引号)
    # 注意: 这里 channel 用的是变量 $new_ch
    # wlan_bs 也被强制加进去了
    log "步骤 2/3: 构建请求体..."
    PAYLOAD=$(
        cat <<EOF
{
    "method": "set",
    "wireless": {
        "wlan_host_5g": {
            "enable": $enable,
            "ssid": "$ssid",
            "key": "$key",
            "auth": "$auth",
            "ssidbrd": $ssidbrd,
            "encryption": $encryption,
            "channel": $new_ch,
            "mode": $mode,
            "bandwidth": $bandwidth,
            "twt": $twt,
            "ofdma": $ofdma,
            "vhtmubfer": $vhtmubfer
        },
        "wlan_bs": {
            "bs_enable": "0"
        }
    }
}
EOF
    )

    # D. 发送修改请求
    log "步骤 3/3: 推送新配置..."
    RESULT=$(curl -s -H "Content-Type: application/json" -X POST "http://$TPLINK_IP/stok=$TOKEN/ds" -d "$PAYLOAD")

    # E. 检查结果
    ERR_CODE=$(echo "$RESULT" | jsonfilter -e '@.error_code')
    if [ "$ERR_CODE" = "0" ]; then
        log "成功: 信道已修改为 $new_ch"
    else
        log "失败: 修改请求被拒绝，返回信息: $RESULT"
    fi
}

# ================= 主逻辑流程 =================

# 获取 TP-Link IP
TPLINK_IP=$(get_ip_by_mac "$TPLINK_MAC")

if [ -z "$TPLINK_IP" ]; then
    log "严重错误: 无法根据 MAC ($TPLINK_MAC) 找到 TP-Link 的 IP 地址。"
    log "请确保设备已连接并在 ARP 表或 DHCP 租约中。"
    exit 1
fi
log "检测到 TP-Link IP: $TPLINK_IP"

# 检查校园网信道
CAMPUS_CHAN=$(get_campus_channel)

if [ -z "$CAMPUS_CHAN" ]; then
    log "错误: 无法获取接口 $CAMPUS_IF 的信道信息。可能未连接。"
    exit 1
fi
log "校园网当前信道: $CAMPUS_CHAN"

# 登录 TP-Link
TOKEN=$(tplink_login)
if [ -z "$TOKEN" ]; then
    log "错误: TP-Link 登录失败，无法获取 Token。"
    exit 1
fi

# 获取 TP-Link 当前信道
MY_CHAN=$(tplink_get_channel)
if [ -z "$MY_CHAN" ]; then
    log "错误: 登录失败。请检查 IP 或密码。"
    exit 1
fi
log "TP-Link 当前信道: $MY_CHAN"

# 冲突判断与处理
C_NUM=$(echo "$CAMPUS_CHAN" | grep -oE '[0-9]+')
M_NUM=$(echo "$MY_CHAN" | grep -oE '[0-9]+')

# 安全检查，不通过则退出
[ -z "$C_NUM" ] && {
    log "警告: 无法解析校园网信道数字。"
    exit 1
}
[ -z "$M_NUM" ] && {
    log "警告: 无法解析 TP-Link 信道数字。"
    exit 1
}

# 阈值判断 (100 为分界线，实际低频段 36-64，高频段 149-165)
if [ "$C_NUM" -gt 100 ] && [ "$M_NUM" -gt 100 ]; then
    log "冲突检测: 双方都在高频段 (Campus:$C_NUM, Mine:$M_NUM)。"
    if [ "$M_NUM" -ne "$TARGET_LOW" ]; then
        log "动作: 切换 TP-Link 至低频段 ($TARGET_LOW)。"
        tplink_set_channel "$TARGET_LOW"
    else
        log "状态: TP-Link 已在目标信道 ($TARGET_LOW)，无需操作。"
    fi

elif [ "$C_NUM" -le 100 ] && [ "$M_NUM" -le 100 ]; then
    log "冲突检测: 双方都在低频段 (Campus:$C_NUM, Mine:$M_NUM)。"
    if [ "$M_NUM" -ne "$TARGET_HIGH" ]; then
        log "动作: 切换 TP-Link 至高频段 ($TARGET_HIGH)。"
        tplink_set_channel "$TARGET_HIGH"
    else
        log "状态: TP-Link 已在目标信道 ($TARGET_HIGH)，无需操作。"
    fi

else
    log "状态良好: 频段已错开 (Campus:$C_NUM, Mine:$M_NUM)，无需操作。"
fi

exit 0
