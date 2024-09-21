#!/bin/sh
if [ "${CONFIG}x" = "x" ]; then
	CONFIG=/data/config.ini
fi

if [ ! -e $CONFIG ]; then
	cp /config.ini /data
fi
python3 /data/CiscoIOUKeygen.py > /data/.iourc

echo [license] > iourc1 | cat .iourc | grep ";" >> iourc1
mv iourc1 .iourc

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
