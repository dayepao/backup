#!/bin/bash

passwall="xiaorouji/openwrt-passwall"
packages="xiaorouji/openwrt-passwall-packages"
sdk_ver="23.05"
luci_ver="23.05"
sdk_url="https://downloads.openwrt.org/releases/23.05.3/targets/x86/64/openwrt-sdk-23.05.3-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz"

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

# 创建编译目录
cd ~
rm -rf passwall
mkdir -p passwall
cd passwall
rm -rf sdk
rm -rf ipk
mkdir sdk
mkdir ipk

# 下载 SDK
echo -e "${green}开始下载 OpenWrt SDK (Version: ${sdk_ver})${plain}"
wget $sdk_url
if [ $? -ne 0 ]; then
    wget $sdk_url
    if [ $? -ne 0 ]; then
        echo -e "${red}Download of SDK failed, exiting the script.${plain}"
        exit 1
    fi
fi
file_name=$(basename $sdk_url)
tar -xJf $file_name -C sdk --strip-components=1

# 编译 passwall
# 编译前准备
cd sdk
echo -e "${green}开始编译 passwall${plain}"
echo "src-git base https://github.com/openwrt/openwrt.git;openwrt-${sdk_ver}" >feeds.conf
echo "src-git packages https://github.com/openwrt/packages.git;openwrt-${sdk_ver}" >>feeds.conf
echo "src-git luci https://github.com/openwrt/luci.git;openwrt-${luci_ver}" >>feeds.conf
echo "src-git routing https://git.openwrt.org/feed/routing.git;openwrt-${sdk_ver}" >>feeds.conf
echo "src-git passwall https://github.com/${passwall}.git;main" >>feeds.conf
echo "src-git passwall_packages https://github.com/${packages}.git;main" >>feeds.conf

./scripts/feeds clean
./scripts/feeds update -a
if [ $? -ne 0 ]; then
    ./scripts/feeds update -a
    if [ $? -ne 0 ]; then
        echo -e "${red}Update of feeds failed, exiting the script.${plain}"
        exit 1
    fi
fi

./scripts/feeds install -a -f -p passwall

# 编译
echo "CONFIG_ALL_NONSHARED=n" >.config
echo "CONFIG_ALL_KMODS=n" >>.config
echo "CONFIG_ALL=n" >>.config
echo "CONFIG_AUTOREMOVE=n" >>.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall=m" >>.config

make defconfig
make package/luci-app-passwall/download -j8

make package/luci-app-passwall/{clean,compile} -j$(nproc)
if [ $? -ne 0 ]; then
    make package/luci-app-passwall/{clean,compile} -j$(nproc)
    if [ $? -ne 0 ]; then
        make package/luci-app-passwall/{clean,compile} -j1 V=s
        echo -e "${red}Compilation of passwall failed, exiting the script.${plain}"
        exit 1
    fi
fi

# 后处理
cp -r bin/packages/x86_64/passwall/ ~/passwall/ipk/passwall
make clean
rm .config .config.old
rm -rf feeds/passwall feeds/passwall.*
cd ~/passwall/ipk/passwall
for i in $(ls); do mv $i luci-${luci_ver}_$i; done
cd ~/passwall
echo -e "${green}passwall 编译完成，ipk 文件在 ~/passwall/ipk/passwall 目录下${plain}"

# 编译 passwall-packages
# 可能需要的依赖: https://github.com/smallprogram/OpenWrtAction/raw/main/diy_script/official_dependence
# 编译前准备
cd sdk
echo -e "${green}开始编译 passwall-packages${plain}"
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

./scripts/feeds install -a -f -p passwall_packages
./scripts/feeds install -a -f -p passwall

# 编译
echo "CONFIG_ALL_NONSHARED=n" >.config
echo "CONFIG_ALL_KMODS=n" >>.config
echo "CONFIG_ALL=n" >>.config
echo "CONFIG_AUTOREMOVE=n" >>.config
echo "CONFIG_SIGNED_PACKAGES=n" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall=m" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ChinaDNS_NG=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=y" >>.config

make defconfig
make download -j8

for package in $(ls feeds/passwall_packages); do
    if [ -d "feeds/passwall_packages/${package}" ]; then
        make package/feeds/passwall_packages/${package}/compile -j$(nproc) 2>/dev/null
        if [ $? -ne 0 ]; then
            make package/feeds/passwall_packages/${package}/compile -j1 V=s
            if [ $? -ne 0 ]; then
                echo -e "${red}Compilation of passwall_packages/${package} failed, exiting the script.${plain}"
                exit 1
            fi
        fi
    fi
done

# 后处理
cp -r bin/packages/x86_64/passwall_packages/ ~/passwall/ipk/passwall_packages/
cd ~
echo -e "${green}passwall-packages 编译完成，ipk 文件在 ~/passwall/ipk/passwall_packages 目录下${plain}"
