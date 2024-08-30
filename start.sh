#!/bin/sh

# Start OpenVPN in the background
openvpn --config /etc/openvpn/openvpn.conf &
MAX_WAIT=30
WAIT_INTERVAL=2
TOTAL_WAIT=0

echo "Waiting for OpenVPN to establish a connection..."

while ! ip a | grep -q "tun0"; do
    sleep $WAIT_INTERVAL
    TOTAL_WAIT=$((TOTAL_WAIT + WAIT_INTERVAL))

    if [ $TOTAL_WAIT -ge $MAX_WAIT ]; then
        echo "OpenVPN failed to establish a connection within the maximum wait time ($MAX_WAIT seconds)."
        exit 1
    fi

    echo "Still waiting for VPN tunnel... (${TOTAL_WAIT}s elapsed)"
done

echo "VPN tunnel established after ${TOTAL_WAIT}s. Starting GNS3 server."


if [ "${CONFIG}x" == "x" ]; then
	CONFIG=/data/config.ini
fi

if [ ! -e $CONFIG ]; then
	cp /config.ini /data
fi

brctl addbr virbr0
ip link set dev virbr0 up
if [ "${BRIDGE_ADDRESS}x" == "x" ]; then
  BRIDGE_ADDRESS=172.21.1.1/24
fi
ip ad add ${BRIDGE_ADDRESS} dev virbr0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

dnsmasq -i virbr0 -z -h --dhcp-range=172.21.1.10,172.21.1.250,4h
dockerd --storage-driver=vfs --data-root=/data/docker/ &
gns3server -A --config $CONFIG
