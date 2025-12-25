#!/usr/bin/env bash
set -euo pipefail

echo "Enter port (49152-65535) or press Enter for random selection:"
read -r input_port
if [ -z "$input_port" ]; then
	while :; do
		port=$((RANDOM % (65535 - 49152 + 1) + 49152))
		if ! lsof -i :"$port" >/dev/null 2>&1; then
			break
		fi
	done
	echo "Selected random port: $port"
else
	if ! [[ "$input_port" =~ ^[0-9]+$ ]] || [ "$input_port" -lt 49152 ] || [ "$input_port" -gt 65535 ]; then
		echo "Error: port must be a number in range 49152-65535"
		exit 1
	fi
	if lsof -i :"$input_port" >/dev/null 2>&1; then
		echo "Error: port $input_port is already in use"
		exit 1
	fi
	port=$input_port
fi

echo "Enter server name (e.g., github.com) or press Enter for default (github.com):"
read -r input_sn
if [ -z "$input_sn" ]; then
	sn="github.com"
	echo "Using default value: $sn"
else
	if ! [[ "$input_sn" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+[a-zA-Z0-9]$ ]]; then
		echo "Error: invalid domain name"
		exit 1
	fi
	sn="$input_sn"
fi

valid_fps=("chrome" "firefox" "safari" "ios" "android" "edge" "360" "qq" "random" "randomized")
echo "Enter fingerprint (chrome, firefox, safari, ios, android, edge, 360, qq, random, randomized) or press Enter for default (safari):"
read -r input_fp
if [ -z "$input_fp" ]; then
	fp="safari"
	echo "Using default value: $fp"
else
	fp_valid=false
	for valid_fp in "${valid_fps[@]}"; do
		if [ "$input_fp" = "$valid_fp" ]; then
			fp_valid=true
			break
		fi
	done
	if [ "$fp_valid" = false ]; then
		echo "Error: invalid fingerprint value. Valid values: ${valid_fps[*]}"
		exit 1
	fi
	fp="$input_fp"
fi

uuid=$(xray uuid)
kp=$(xray x25519)
pk=$(printf "%s\n" "$kp" | awk -F': ' '/^PrivateKey:/ {print $2}')
pw=$(printf "%s\n" "$kp" | awk -F': ' '/^Password:/ {print $2}')
sid=$(openssl rand -hex 8)
ip=$(curl -4 -s ifconfig.me)

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

systemctl restart xray

name="u$(head -c 100 /dev/urandom | tr -dc 'a-z0-9' | head -c 10)"
url="vless://${uuid}@${ip}:${port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sn}&fp=${fp}&pbk=${pw}&sid=${sid}&type=tcp#${name}"
echo ""
echo "VLESS connection URL:"
echo $url | tee ~/xray/vless_url