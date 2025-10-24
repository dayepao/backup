#!/usr/bin/env bash
set -euo pipefail

#### 输出颜色
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
plain="\033[0m"

#### 输出函数
print_color() {
    local color_code="$1"
    local message="$2"
    local color_var="${!color_code:-$plain}"
    printf "%b%s%b\n" "$color_var" "$message" "$plain"
}

info()  { print_color green  "INFO:  $*"; }
warn()  { print_color yellow "WARN:  $*"; }
error() { print_color red    "ERROR: $*"; }

#### 默认配置信息
openwrt_git="https://github.com/openwrt/openwrt.git"
openwrt_ver="24.10.4"
dev_flag=0

#### 解析参数（顺序无关）
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)                 # 例如: -v 23.05.3  或 --version 23.05.3
      [[ $# -ge 2 ]] || { error "$1 requires a value" >&2; exit 2; }
      openwrt_ver="$2"; shift 2;;
    --version=*)                  # 例如: --version=23.05.3
      openwrt_ver="${1#*=}"; shift;;
    -d|--dev|-dev)                # 开启 dev 标志（不带值）
      dev_flag=1; shift;;
    --no-dev)                     # 显式关闭（可选）
      dev_flag=0; shift;;
    --) shift; break;;            # 终止选项
    -*)
      warn "unknown option: $1 (ignored)"; shift;;
    *)
      positional+=("$1"); shift;; # 其他位置参数（如将来扩展）
  esac
done
# 如需保留剩余参数给后续命令：
# set -- "${positional[@]}" "$@"

#### 相关链接
manifest_url="https://downloads.openwrt.org/releases/${openwrt_ver}/targets/x86/64/openwrt-${openwrt_ver}-x86-64.manifest"
if [[ "$dev_flag" == "1" ]]; then
    diffconfig_url="https://downloads.openwrt.org/snapshots/targets/x86/64/config.buildinfo"
else
    diffconfig_url="https://downloads.openwrt.org/releases/${openwrt_ver}/targets/x86/64/config.buildinfo"
fi

#### 相关目录
BASE_DIR="${HOME}/compile_openwrt"
COMPILE_DIR="${BASE_DIR}/compile"
OUTPUT_DIR="${BASE_DIR}/output"

#### 创建相关目录
if [ -n "${BASE_DIR:-}" ] && [ -d "${BASE_DIR}" ]; then
    warn "删除已有目录: ${BASE_DIR}"
    rm -rf -- "${BASE_DIR}"
fi
mkdir -p "${BASE_DIR}" || { echo "创建目录失败: ${BASE_DIR}"; exit 1; }
mkdir -p "${OUTPUT_DIR}" || { echo "创建目录失败: ${OUTPUT_DIR}"; exit 1; }
# 创建临时目录并确保退出时清理
TMP_DIR=$(mktemp -d -p $BASE_DIR) || { echo "mktemp failed"; exit 1; }
trap 'rm -rf -- "$TMP_DIR"' EXIT


if [[ "${dev_flag}" == "1" ]]; then
    info "Compiling OpenWrt version: main (snapshot)"
else
    info "Compiling OpenWrt version: ${openwrt_ver}"
fi

#### WSL 环境变量
if grep -qEi "(Microsoft|WSL)" /proc/version; then
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    warn "检测到在 WSL 下运行，已设置 PATH 环境变量"
fi

#### 获取系统版本
os_id=$(awk -F= '$1=="ID" {print $2}' /etc/os-release | tr -d '"')
os_version_id=$(awk -F= '$1=="VERSION_ID" {print $2}' /etc/os-release | tr -d '"')

#### Debian 环境变量
if [[ "${os_id}" == "debian" ]]; then
    export CFLAGS="${CFLAGS:-} -Wno-error=restrict -Wno-error=maybe-uninitialized"
    export CXXFLAGS="${CXXFLAGS:-} -Wno-error=restrict -Wno-error=maybe-uninitialized"
    warn "检测到在 Debian 下运行，已设置 CFLAGS 和 CXXFLAGS 环境变量"
fi

#### 下载 OpenWrt 源码
info "Downloading OpenWrt source code"

git clone "${openwrt_git}" "${COMPILE_DIR}"
cd -- "${COMPILE_DIR}"

# 切换到指定版本
if [[ "$dev_flag" == "1" ]]; then
    info "Switching to branch: main"
    git checkout main
else
    # info "Switching to branch: openwrt-${openwrt_ver%.*}"
    # git checkout openwrt-${openwrt_ver%.*}
    info "Switching to tag: v${openwrt_ver}"
    git checkout "v${openwrt_ver}"
fi
if [[ $? -ne 0 ]]; then
    error "Switching failed, exiting the script"
    exit 1
fi

#### 添加自定义文件
info "Adding custom files"
mkdir -p files/etc
wget -O files/etc/openwrt_TJDORMWIFI.sh https://raw.githubusercontent.com/dayepao/backup/refs/heads/main/sh/openwrt_TJDORMWIFI.sh
wget -O files/etc/openwrt_wifi_check.sh https://raw.githubusercontent.com/dayepao/backup/refs/heads/main/sh/openwrt_wifi_check.sh
wget -O files/etc/openwrt_wifi_init.sh https://raw.githubusercontent.com/dayepao/backup/refs/heads/main/sh/openwrt_wifi_init.sh

#### 添加第三方软件包
info "Adding third-party packages"

# luci-app-turboacc
curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh --no-sfe

cd -- "${COMPILE_DIR}/package"

# luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git

# luci-app-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall.git

# luci-app-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages.git

# luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash.git "${TMP_DIR}/openclash_tmp"
cp -r "${TMP_DIR}/openclash_tmp/luci-app-openclash" "${COMPILE_DIR}/package/luci-app-openclash"

cd -- "${COMPILE_DIR}"

#### 添加 feeds 源
# passwall
# echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >>feeds.conf.default
# echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >>feeds.conf.default

#### 修补 feeds 源
sed -i "s#\(src-git telephony https://git.openwrt.org/feed/telephony.git\)\^.*#\1^11e9c73bff6be34ff2fdcd4bc0e81a4723d78652#" feeds.conf.default

#### 更新 feeds 软件包
info "Updating feeds"
./scripts/feeds clean

./scripts/feeds update -a
if [[ $? -ne 0 ]]; then
    ./scripts/feeds update -a
    if [[ $? -ne 0 ]]; then
        error "Update of feeds failed, exiting the script"
        exit 1
    fi
fi

if [ "$dev_flag" != "1" ]; then
    # 下载 ${TMP_DIR}/packages
    info "Downloading ${TMP_DIR}/packages"

    TMP_PKG_DIR="${TMP_DIR}/packages"
    if [[ -d "${TMP_PKG_DIR}" ]]; then
        warn "删除已有目录: ${TMP_PKG_DIR}"
        rm -rf -- "${TMP_PKG_DIR}"
    fi

    git clone https://github.com/openwrt/packages "${TMP_PKG_DIR}"
    if [[ $? -ne 0 ]]; then
        git clone https://github.com/openwrt/packages "${TMP_PKG_DIR}"
        if [[ $? -ne 0 ]]; then
            error "Download of packages failed, exiting the script"
            exit 1
        fi
    fi
    cd -- "${TMP_PKG_DIR}"

    # 更新 golang 包
    # 切换到指定版本
    TMP_SOURCE_DIR="${TMP_PKG_DIR}/lang/golang"
    TMP_TARGET_DIR="${COMPILE_DIR}/feeds/packages/lang/golang"
    info "Switching to branch: master"
    git checkout master
    if [[ $? -ne 0 ]]; then
        error "Switching failed, exiting the script"
        exit 1
    fi
    info "Updating ${TMP_TARGET_DIR}"
    if [[ -d "${TMP_TARGET_DIR}" ]]; then
        warn "删除已有目录: ${TMP_TARGET_DIR}"
        rm -rf -- "${TMP_TARGET_DIR}"
    fi
    cp -r "${TMP_SOURCE_DIR}" "${TMP_TARGET_DIR}"

    cd -- "${COMPILE_DIR}"
fi

#### 安装 feeds 软件包
info "Installing feeds"
./scripts/feeds install -a

if [[ "$dev_flag" != "1" ]]; then
    #### 修正 vermagic
    info "Fixing vermagic"
    curl -s "${manifest_url}" | grep "kernel" | awk -F "-" '
    {
        match($0, /[0-9a-f]{32,}/, hash);
        if (hash[0] != "") print hash[0];
    }' > .vermagic
    sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
    cat .vermagic
fi

#### 修改默认 IP 为 192.168.1.100
# sed -i 's/ipaddr:-"192.168.1.1"/ipaddr:-"192.168.1.100"/' package/base-files/files/bin/config_generate

#### 修改默认密码 openwrt/package/base-files/files/etc/shadow

#### 设置默认时区为 CST-8
# CONFIG_PACKAGE_zoneinfo-asia=y
#
sed -i "/set system.@system\[-1\].timezone=/c\		set system.@system[-1].timezone='CST-8'" package/base-files/files/bin/config_generate
sed -i "/set system.@system\[-1\].timezone='CST-8'/a\		set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

#### 修改默认主题
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile

#### 下载 diffconfig
# ./scripts/diffconfig.sh > diffconfig
info "Downloading diffconfig"

if [[ -f .config ]]; then
    warn "Removing .config"
    rm -f -- .config
fi
if [[ -f .config.old ]]; then
    warn "Removing .config.old"
    rm -f -- .config.old
fi

wget -O .config $diffconfig_url
if [[ $? -ne 0 ]]; then
    wget -O .config $diffconfig_url
    if [[ $? -ne 0 ]]; then
        error "Download of diffconfig failed, exiting the script"
        exit 1
    fi
fi

#### 修改 .config
info "Modifying .config"

# skip kmod-pf-ring
# echo "CONFIG_PACKAGE_kmod-pf-ring=n" >>.config

# Target Images
echo "CONFIG_TARGET_KERNEL_PARTSIZE=512" >>.config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >>.config

# AX411 Driver
## Firmware -> iwlwifi-firmware-ax411
echo "CONFIG_PACKAGE_iwlwifi-firmware-ax411=y" >>.config
## Kernel modules -> Wireless Drivers -> kmod-iwlwifi
echo "CONFIG_PACKAGE_kmod-iwlwifi=y" >>.config

# RTL8922AE Driver
## Firmware -> rtl8922ae-firmware
echo "CONFIG_PACKAGE_rtl8922ae-firmware=y" >>.config
## Kernel modules -> Wireless Drivers -> kmod-rtw89-8922ae
echo "CONFIG_PACKAGE_kmod-rtw89-8922ae=y" >>.config

# Network -> WirelessAPD -> wpad
echo "CONFIG_PACKAGE_wpad=y" >>.config

# Base system -> dnsmasq-full
echo "CONFIG_PACKAGE_dnsmasq=m" >>.config
echo "CONFIG_PACKAGE_dnsmasq-full=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dhcp=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_dnssec=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_auth=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_ipset=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_nftset=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_conntrack=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_noid=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_broken_rtc=y" >>.config
echo "CONFIG_PACKAGE_dnsmasq_full_tftp=y" >>.config

# Utilities -> Virtualization -> qemu-ga
echo "CONFIG_PACKAGE_qemu-ga=y" >>.config

# Luci -> Modules -> Translations -> zh_Hans
echo "CONFIG_LUCI_LANG_zh_Hans=y" >>.config

# Luci -> Themes -> luci-theme-argon
echo "CONFIG_PACKAGE_luci-theme-argon=y" >>.config

# Luci -> Applications -> luci-app-nft-qos
echo "CONFIG_PACKAGE_luci-app-nft-qos=y" >>.config

# Luci -> Applications -> luci-app-passwall
echo "CONFIG_PACKAGE_luci-app-passwall=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Geoview=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadow_TLS=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y" >>.config
echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=y" >>.config

# Luci -> Applications -> luci-app-openclash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >>.config

# Luci -> Applications -> luci-app-ttyd
echo "CONFIG_PACKAGE_luci-app-ttyd=y" >>.config

# Luci -> Applications -> luci-app-turboacc
echo "CONFIG_PACKAGE_luci-app-turboacc=y" >>.config
echo "CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_OFFLOADING=y" >>.config
echo "CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_BBR_CCA=y" >>.config
echo "CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_NFT_FULLCONE=y" >>.config

# tailscale
# echo "CONFIG_PACKAGE_tailscale=y" >>.config

if [[ "$dev_flag" == "1" ]]; then
    # 编译相关组件
    echo "CONFIG_IMAGEOPT=y" >>.config
    echo "CONFIG_PACKAGE_cgi-io=y" >>.config
    echo "CONFIG_PACKAGE_libiwinfo=y" >>.config
    echo "CONFIG_PACKAGE_libiwinfo-data=y" >>.config
    echo "CONFIG_PACKAGE_liblucihttp=y" >>.config
    echo "CONFIG_PACKAGE_liblucihttp-ucode=y" >>.config
    echo "CONFIG_PACKAGE_luci=y" >>.config
    echo "CONFIG_PACKAGE_luci-app-firewall=y" >>.config
    echo "CONFIG_PACKAGE_luci-app-package-manager=y" >>.config
    echo "CONFIG_PACKAGE_luci-base=y" >>.config
    echo "CONFIG_PACKAGE_luci-light=y" >>.config
    echo "CONFIG_PACKAGE_luci-mod-admin-full=y" >>.config
    echo "CONFIG_PACKAGE_luci-mod-network=y" >>.config
    echo "CONFIG_PACKAGE_luci-mod-status=y" >>.config
    echo "CONFIG_PACKAGE_luci-mod-system=y" >>.config
    echo "CONFIG_PACKAGE_luci-proto-ipv6=y" >>.config
    echo "CONFIG_PACKAGE_luci-proto-ppp=y" >>.config
    echo "CONFIG_PACKAGE_luci-ssl=y" >>.config
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >>.config
    echo "CONFIG_PACKAGE_px5g-mbedtls=y" >>.config
    echo "CONFIG_PACKAGE_rpcd=y" >>.config
    echo "CONFIG_PACKAGE_rpcd-mod-file=y" >>.config
    echo "CONFIG_PACKAGE_rpcd-mod-iwinfo=y" >>.config
    echo "CONFIG_PACKAGE_rpcd-mod-luci=y" >>.config
    echo "CONFIG_PACKAGE_rpcd-mod-rrdns=y" >>.config
    echo "CONFIG_PACKAGE_rpcd-mod-ucode=y" >>.config
    echo "CONFIG_PACKAGE_ucode-mod-html=y" >>.config
    echo "CONFIG_PACKAGE_ucode-mod-math=y" >>.config
    echo "CONFIG_PACKAGE_uhttpd=y" >>.config
    echo "CONFIG_PACKAGE_uhttpd-mod-ubus=y" >>.config
fi

make defconfig
make defconfig

#### 编译
info "Downloading"
make download -j8
download_status=$?
output=$(find dl -size -1024c -exec ls -l {} \;)
if [[ $download_status -ne 0 ]] || [[ -n "$output" ]]; then
    find dl -size -1024c -exec rm -f {} \;
    make download -j8 V=s
    download_status=$?
    output=$(find dl -size -1024c -exec ls -l {} \;)
    if [[ $download_status -ne 0 ]] || [[ -n "$output" ]]; then
        error "Download of packages failed, exiting the script"
        exit 1
    fi
fi

info "Compiling"
make -j$(nproc) || make -j1 V=s
if [[ $? -ne 0 ]]; then
    error "Build failed, exiting the script"
    exit 1
fi

cp -rf "${COMPILE_DIR}/bin/targets/x86/64/*" "${OUTPUT_DIR}"
info "Build succeeded, the firmware file is in ${OUTPUT_DIR}"
