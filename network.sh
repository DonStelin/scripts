#!/bin/bash

CONFIG_FILE="/etc/network/interfaces"

INTERFACE="enp0s3"

set_dynamic_ip() {
    sudo cat <<EOL > $CONFIG_FILE
# Configuración dinámica
auto lo
iface lo inet loopback
EOL
    echo "Configuración cambiada a IP dinámica."
}

set_static_ip() {
    sudo cat <<EOL > $CONFIG_FILE
# Configuración estática
auto lo
iface lo inet loopback

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
    echo "Configuración cambiada a IP estática."
}

# Verificar configuración actual
if grep -q "iface $INTERFACE inet static" $CONFIG_FILE; then
    echo "Actualmente está configurado como IP estática."
    set_dynamic_ip
else
    echo "Actualmente está configurado como IP dinámica o no configurado correctamente."
    set_static_ip
fi

sudo systemctl restart networking
