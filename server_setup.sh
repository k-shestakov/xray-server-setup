#!/usr/bin/env bash
set -euo pipefail

apt update && apt upgrade -y
apt install -y curl lsof openssl

cat <<EOF > echo >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
sysctl -p

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --without-geodata

mkdir ~/xray
curl -L -o ~/xray/xray_setup.sh https://raw.githubusercontent.com/k-shestakov/xray-server-setup/refs/heads/main/xray_setup.sh
bash ~/xray/xray_setup.sh

reboot