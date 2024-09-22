#!/bin/sh

# Ensure the script fails on errors
set -e

# Check if CiscoIOUKeygen.py exists
if [ ! -f /data/CiscoIOUKeygen.py ]; then
    echo "Error: CiscoIOUKeygen.py not found in /data"
    exit 1
fi

# Run the Cisco IOU Keygen script
python3 /data/CiscoIOUKeygen.py > /data/.iourc

# Check if .iourc was generated successfully
if [ -s /data/.iourc ]; then
    echo ".iourc file generated successfully."
    cat /data/.iourc
else
    echo "Error: .iourc file was not generated or is empty."
    exit 1
fi

# Modify the .iourc file with the license
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
    exit 1
fi

# Set up configuration
if [ "${CONFIG}x" = "x" ]; then
    CONFIG=/data/config.ini
fi

if [ ! -e "$CONFIG" ]; then
    cp /config.ini /data
fi

# Set up network bridge
brctl addbr virbr0
ip link set dev virbr0 up
if [ "${BRIDGE_ADDRESS}x" = "x" ]; then
    BRIDGE_ADDRESS=172.21.1.1/24
fi
ip addr add ${BRIDGE_ADDRESS} dev virbr0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Start DHCP server
dnsmasq -i virbr0 -z -h --dhcp-range=172.21.1.10,172.21.1.250,4h

# Start Docker daemon
dockerd --storage-driver=vfs --data-root=/data/docker/ &

# Start GNS3 server
gns3server -A --config "$CONFIG"
