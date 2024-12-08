#!/bin/sh

# Nombre del archivo: configurar_dhcp.sh
# Este script configura un servidor DHCP en FreeBSD con correcciones para la subred y configuración del DNS.

# Configurar variables
INTERFAZ="em0"  # Cambia esto por el nombre de tu interfaz de red
IP_STATIC="192.168.1.1"
NETMASK="255.255.255.0"
DHCP_RANGE_START="192.168.1.100"
DHCP_RANGE_END="192.168.1.200"
GATEWAY="192.168.1.1"
BROADCAST="192.168.1.255"
SUFIJO_DNS="unah.edu.hn"  # Sufijo DNS
DNS_SERVER="192.168.1.10"  # Dirección del servidor DNS (puedes ajustarlo)

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

subnet ${IP_STATIC%.*}.0 netmask ${NETMASK} {  # Usar dirección base de la red
    range ${DHCP_RANGE_START} ${DHCP_RANGE_END};
    option routers ${GATEWAY};  # Puerta de enlace predeterminada
    option broadcast-address ${BROADCAST};  # Dirección de broadcast
    option domain-name "${SUFIJO_DNS}";  # Sufijo DNS
    option domain-name-servers ${DNS_SERVER};  # Servidor DNS
}
EOL

# Validar el archivo de configuración
echo "Validando archivo de configuración DHCP..."
dhcpd -t -cf /usr/local/etc/dhcpd.conf
if [ $? -ne 0 ]; then
    echo "Error en la configuración de dhcpd.conf. Revise el archivo y los parámetros."
    exit 1
fi

# Paso 5: Habilitar el servicio DHCP en rc.conf
echo "Habilitando el servicio DHCP..."
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="${INTERFAZ}"

# Paso 6: Iniciar el servicio DHCP
echo "Iniciando el servicio DHCP..."
service isc-dhcpd restart

# Verificar el estado del servicio
echo "Verificando el estado del servicio DHCP..."
service isc-dhcpd status

echo "Configuración de DHCP completada. Verifique el funcionamiento desde los clientes."
