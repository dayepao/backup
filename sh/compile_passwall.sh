#!/bin/bash

passwall="xiaorouji/openwrt-passwall"
packages="xiaorouji/openwrt-passwall-packages"
sdk_ver="23.05"
luci_ver="23.05"
sdk_url="https://downloads.openwrt.org/releases/23.05.3/targets/x86/64/openwrt-sdk-23.05.3-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz"

# WSL2 环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin

# 创建编译目录
cd ~
rm -rf passwall
mkdir -p passwall
cd passwall

# 下载 SDK
wget $sdk_url
file_name=$(basename $sdk_url)
rm -rf sdk
mkdir sdk && tar -xJf $file_name -C sdk --strip-components=1

# 编译 passwall
# 编译前准备
cd sdk
echo "开始编译 passwall"
echo "src-git base https://github.com/openwrt/openwrt.git;openwrt-${sdk_ver}" > feeds.conf
echo "src-git packages https://github.com/openwrt/packages.git;openwrt-${sdk_ver}" >> feeds.conf
echo "src-git luci https://github.com/openwrt/luci.git;openwrt-${luci_ver}" >> feeds.conf
echo "src-git routing https://git.openwrt.org/feed/routing.git;openwrt-${sdk_ver}"  >> feeds.conf
echo "src-git passwall_packages https://github.com/${packages}.git;main" >> feeds.conf
echo "src-git passwall https://github.com/${passwall}.git;main" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -d n luci-app-passwall


# 编译
echo "CONFIG_ALL_NONSHARED=n" > .config
echo "CONFIG_ALL_KMODS=n" >> .config
echo "CONFIG_ALL=n" >> .config
echo "CONFIG_AUTOREMOVE=n" >> .config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall=m" >> .config

make defconfig
make package/luci-app-passwall/download -j8

make package/luci-app-passwall/{clean,compile} -j$(nproc)
if [ $? -ne 0 ]; then
    make package/luci-app-passwall/{clean,compile} -j$(nproc)
    if [ $? -ne 0 ]; then
        make package/luci-app-passwall/{clean,compile} -j1 V=s
        echo "Compilation of passwall failed, exiting the script."
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
echo "passwall 编译完成，ipk 文件在 ~/passwall/ipk/passwall 目录下"

# 编译 passwall-packages
# 可能需要的依赖: https://github.com/smallprogram/OpenWrtAction/raw/main/diy_script/official_dependence
# 编译前准备
cd sdk
echo "开始编译 passwall-packages"
./scripts/feeds update -a
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang
./scripts/feeds install -a -f -p passwall_packages
./scripts/feeds install luci-app-passwall

# 编译
echo "CONFIG_ALL_NONSHARED=n" > .config
echo "CONFIG_ALL_KMODS=n" >> .config
echo "CONFIG_ALL=n" >> .config
echo "CONFIG_AUTOREMOVE=n" >> .config
echo "CONFIG_SIGNED_PACKAGES=n" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall=m" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ChinaDNS_NG=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=y" >> .config

make defconfig
make download -j8

for package in $(ls feeds/passwall_packages); do
    if [ -d "feeds/passwall_packages/${package}" ]; then
        make package/feeds/passwall_packages/${package}/compile -j$(nproc) 2>/dev/null
    fi
    if [ $? -ne 0 ]; then
        make package/feeds/passwall_packages/${package}/compile -j$(nproc) 2>/dev/null
        if [ $? -ne 0 ]; then
            make package/feeds/passwall_packages/${package}/compile -j1 V=s
            echo "Compilation of passwall_packages/${package} failed, exiting the script."
            # exit 1
            read -p "Compilation of passwall_packages/${package} failed" choice
        fi
    fi
done

# 后处理
cp -r bin/packages/x86_64/passwall_packages/ ~/passwall/ipk/passwall_packages/
cd ~
echo "passwall-packages 编译完成，ipk 文件在 ~/passwall/ipk/passwall_packages 目录下"
