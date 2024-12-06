
#!/bin/bash

sudo apt install -y isc-dhcp-server

INTERFACES_FILE="/etc/default/isc-dhcp-server"

sudo sed -i 's/^INTERFACESV4=.*/INTERFACESV4="enp0s3"/' "$INTERFACES_FILE" || echo 'INTERFACESV4="enp0s3"' | sudo tee -a "$INTERFACES_FILE"

DHCPD_CONF="/etc/dhcp/dhcpd.conf"

DHCP_CONFIG='
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.25 192.168.1.125;
    option domain-name-servers 192.168.1.100;
    option domain-name "unah.edu.hn";
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
    default-lease-time 600;
    max-lease-time 7200;
}'

# Agregar la configuración al final de /etc/dhcp/dhcpd.conf
    echo "$DHCP_CONFIG" | sudo tee -a "$DHCPD_CONF"
    echo "Configuración agregada a $DHCPD_CONF."
else
    echo "La configuración ya existe en $DHCPD_CONF."
fi
