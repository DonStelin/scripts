#!/bin/bash

CONFIG_FILE="/etc/network/interfaces"

INTERFACE="enp0s3"

sudo cat <<EOL > $CONFIG_FILE
# auto lo
# iface lo inet loopback

auto $INTERFACE
iface $INTERFACE inet static
address 192.168.1.10
netmask 255.255.255.0
gateway 192.168.1.1
network 192.168.1.0
broadcast 192.168.1.255
dns-nameservers 192.168.1.100
dns-search unah.edu.hn
EOL

echo "Configuración cambiada a IP estática para la interfaz $INTERFACE."

sudo systemctl restart networking
