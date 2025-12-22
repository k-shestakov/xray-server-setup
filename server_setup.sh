#!/usr/bin/env bash

apt update && apt upgrade -y
apt install sudo curl openssl -y

cat >/etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
sysctl net.ipv4.tcp_congestion_control

sysctl --system

user="u$(tr -dc a-z0-9 </dev/urandom | head -c 10)"
adduser --disabled-password --gecos "" $user
usermod -aG sudo $user
passwd $user

while :; do
  port=$((RANDOM % (65535 - 49152 + 1) + 49152))
  if ! lsof -i :"$port" >/dev/null 2>&1; then
    break
  fi
done

sed -i -e 's/#Port 22/Port '"$port"'/g' -e 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd

ip=$(curl -4 -s ifconfig.me)

echo ""
echo "ssh -p $port $user@$ip"
echo ""

bash <(curl -fsSL https://raw.githubusercontent.com/k-shestakov/xray-server-setup/refs/heads/main/xray-setup)