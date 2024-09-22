#!/bin/sh
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

# Run CiscoIOUKeygen.py and log output
echo "Running CiscoIOUKeygen.py..."
python3 /data/CiscoIOUKeygen.py > /data/.iourc

# Check if .iourc was generated and contains content
if [ -s /data/.iourc ]; then
    echo ".iourc file generated successfully."
    cat /data/.iourc
else
    echo "Error: .iourc file was not generated or is empty."
fi

# Modify the iourc file with the license
{
    echo "[license]"
    grep ";" /data/.iourc
} > /data/iourc1

# Check if license modification worked
if [ -s /data/iourc1 ]; then
    echo "License file created successfully."
    mv /data/iourc1 /data/.iourc
else
    echo "Error: Failed to create iourc1 file."
fi

# Start GNS3 server with the specified configuration
gns3server -A --config $CONFIG
