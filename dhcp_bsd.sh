#!/bin/sh

# Nombre del archivo: configurar_dhcp.sh
# Este script configura un servidor DHCP en FreeBSD.

# Configurar variables
INTERFAZ="em0"  # Cambia esto por el nombre de tu interfaz de red
IP_STATIC="192.168.1.1"
NETMASK="255.255.255.0"
DHCP_RANGE_START="192.168.1.100"
DHCP_RANGE_END="192.168.1.200"
GATEWAY="192.168.1.1"
BROADCAST="192.168.1.255"

# Paso 1: Actualizar paquetes
echo "Actualizando paquetes..."
pkg update && pkg upgrade -y

# Paso 2: Instalar el paquete DHCP
echo "Instalando isc-dhcp44-server..."
pkg install -y isc-dhcp44-server

# Paso 3: Configurar la interfaz de red
echo "Configurando la interfaz de red..."
sysrc ifconfig_${INTERFAZ}="inet ${IP_STATIC} netmask ${NETMASK}"

# Reiniciar la interfaz de red
service netif restart

# Paso 4: Configurar el archivo dhcpd.conf
echo "Creando archivo de configuración DHCP en /usr/local/etc/dhcpd.conf..."
cat > /usr/local/etc/dhcpd.conf <<EOL
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet ${IP_STATIC} netmask ${NETMASK} {
    range ${DHCP_RANGE_START} ${DHCP_RANGE_END};
    option routers ${GATEWAY};
    option broadcast-address ${BROADCAST};
}
EOL

# Paso 5: Habilitar el servicio DHCP en rc.conf
echo "Habilitando el servicio DHCP..."
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="${INTERFAZ}"

# Paso 6: Iniciar el servicio DHCP
echo "Iniciando el servicio DHCP..."
service isc-dhcpd start

# Verificar el estado del servicio
echo "Verificando el estado del servicio DHCP..."
service isc-dhcpd status

echo "Configuración de DHCP completada."
