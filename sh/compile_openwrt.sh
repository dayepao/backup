#!/bin/bash

# 配置信息
openwrt_git="https://github.com/openwrt/openwrt.git"
openwrt_ver="23.05.3"

# 相关链接
manifest_url="https://downloads.openwrt.org/releases/${openwrt_ver}/targets/x86/64/openwrt-${openwrt_ver}-x86-64.manifest"
diffconfig_url="https://downloads.openwrt.org/releases/${openwrt_ver}/targets/x86/64/config.buildinfo"

# 输出颜色
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
plain="\033[0m"

# WSL 环境变量
if grep -qEi "(Microsoft|WSL)" /proc/version; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    echo -e "${yellow}检测到在WSL下运行，已设置 PATH 环境变量${plain}"
fi

# 获取系统版本
os_id=$(awk -F= '$1=="ID" {print $2}' /etc/os-release | tr -d '"')
os_version_id=$(awk -F= '$1=="VERSION_ID" {print $2}' /etc/os-release | tr -d '"')

# Debian 环境变量
if [ "${os_id}" == "debian" ]; then
    export CFLAGS="$CFLAGS -Wno-error=restrict -Wno-error=maybe-uninitialized"
    export CXXFLAGS="$CXXFLAGS -Wno-error=restrict -Wno-error=maybe-uninitialized"
    echo -e "${yellow}检测到在Debian下运行，已设置 CFLAGS 和 CXXFLAGS 环境变量${plain}"
fi

# 下载 OpenWrt 源码
echo -e "${green}Downloading OpenWrt source code...${plain}"
cd ~
rm -rf openwrt
git clone $openwrt_git openwrt
cd openwrt

# 切换到指定版本
git checkout v$openwrt_ver
if [ $? -ne 0 ]; then
    echo -e "${red}Switch to v$openwrt_ver failed, exiting the script.${plain}"
    exit 1
fi

# 添加第三方软件包
echo -e "${green}Adding third-party packages...${plain}"
cd package
# luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git
cd -

# 添加 feeds 源
# passwall
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >>feeds.conf.default
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >>feeds.conf.default

# 更新并安装 feeds 软件包
echo -e "${green}Updating and installing feeds...${plain}"
./scripts/feeds clean

./scripts/feeds update -a
if [ $? -ne 0 ]; then
    ./scripts/feeds update -a
    if [ $? -ne 0 ]; then
        echo -e "${red}Update of feeds failed, exiting the script.${plain}"
        exit 1
    fi
fi

rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang
if [ $? -ne 0 ]; then
    git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang
    if [ $? -ne 0 ]; then
        echo -e "${red}Download of packages_lang_golang failed, exiting the script.${plain}"
        exit 1
    fi
fi

./scripts/feeds install -a

# 修正 vermagic
echo -e "${green}Fixing vermagic...${plain}"
curl -s "${manifest_url}" | grep "kernel" | awk -F "-" '{print $NF}' >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# 修改默认 IP 为 192.168.1.100
# sed -i 's/ipaddr:-"192.168.1.1"/ipaddr:-"192.168.1.100"/' package/base-files/files/bin/config_generate

# 修改默认密码 openwrt/package/base-files/files/etc/shadow

# 设置默认时区为 CST-8
# CONFIG_PACKAGE_zoneinfo-asia=y
#
# sed -i -e "/set system.@system\[-1\].timezone=/ {
#     c\        set system.@system[-1].timezone='CST-8'
#     a\        set system.@system[-1].zonename='Asia/Shanghai'
# }" package/base-files/files/bin/config_generate
#
# sed -i "/set system.@system\[-1\].timezone=/c\        set system.@system[-1].timezone='CST-8'" package/base-files/files/bin/config_generate

# 修改默认主题
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile

# 下载 diffconfig
# ./scripts/diffconfig.sh > diffconfig
echo -e "${green}Downloading diffconfig...${plain}"
wget -O .config $diffconfig_url

# 修改 .config
echo -e "${green}Modifying .config...${plain}"
# skip kmod-pf-ring
echo "CONFIG_PACKAGE_kmod-pf-ring=n" >>.config

# Target Images
echo "CONFIG_TARGET_KERNEL_PARTSIZE=512" >>.config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >>.config

# Base system
echo "CONFIG_PACKAGE_dnsmasq-full=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_auth=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_broken_rtc=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_conntrack=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dhcp=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dnssec=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_ipset=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_nftset=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_noid=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_tftp=y" >>.config

# zh_Hans
echo "CONFIG_LUCI_LANG_zh_Hans=y" >>.config

# theme
# luci-theme-argon
echo "CONFIG_PACKAGE_luci-theme-argon=y" >>.config

# applications
# luci-app-nft-qos
echo "CONFIG_PACKAGE_luci-app-nft-qos=y" >>.config

# luci-app-passwall
echo "CONFIG_PACKAGE_luci-app-passwall=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y" >>.config

# luci-app-ttyd
echo "CONFIG_PACKAGE_luci-app-ttyd=y" >>.config

make defconfig

# 编译
echo -e "${green}Compiling...${plain}"
make download -j8
output=$(find dl -size -1024c -exec ls -l {} \;)
if [ -n "$output" ]; then
    find dl -size -1024c -exec rm -f {} \;
    make download -j8
    output=$(find dl -size -1024c -exec ls -l {} \;)
    if [ -n "$output" ]; then
        echo -e "${red}Download of packages failed, exiting the script.${plain}"
        exit 1
    fi
fi

make -j$(nproc) || make -j1 || make -j1 V=s
if [ $? -ne 0 ]; then
    echo -e "${red}Build failed, exiting the script.${plain}"
    exit 1
fi
echo -e "${green}Build succeeded, the firmware file is in bin/targets/x86/64.${plain}"
