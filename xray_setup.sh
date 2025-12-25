#!/usr/bin/env bash
set -euo pipefail

apt update && apt upgrade -y

cat <<EOF > echo >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
sysctl -p

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --without-geodata

while :; do
	port=$((RANDOM % (65535 - 49152 + 1) + 49152))
	if ! lsof -i :"$port" >/dev/null 2>&1; then
		break
	fi
done
uuid=$(xray uuid)
kp=$(xray x25519)
pk=$(printf "%s\n" "$kp" | awk -F': ' '/^PrivateKey:/ {print $2}')
pw=$(printf "%s\n" "$kp" | awk -F': ' '/^Password:/ {print $2}')
sid=$(openssl rand -hex 8)
ip=$(curl -4 -s ifconfig.me)
sn="github.com"
fp="safari"

if [ -f /usr/local/etc/xray/config.json ]; then
	cp /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.bak
fi

cat <<EOF >/usr/local/etc/xray/config.json
{
    "inbounds": [
        {
            "port": $port, 
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "${sn}:443",
                    "serverNames": ["$sn"],
                    "privateKey": "$pk",
                    "shortIds": ["$sid"]
                }
            }
        }
    ],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

name="u$(head -c 100 /dev/urandom | tr -dc 'a-z0-9' | head -c 10)"
url="vless://${uuid}@${ip}:${port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sn}&fp=${fp}&pbk=${pw}&sid=${sid}&type=tcp#${name}"
mkdir ~/xray
echo ""
echo $url | tee ~/xray/vless_url

reboot
