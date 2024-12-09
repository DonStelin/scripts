#!/bin/sh

# Nombre del archivo: configurar_servidor.sh
# Este script combina la instalación y configuración de DHCP y Apache en FreeBSD.
# Pasos:
# 1. Instalar los paquetes necesarios
# 2. Configurar una IP estática
# 3. Configurar el servicio DHCP
# 4. Configurar el servicio Apache
# 5. Ajustar firewall para permitir tráfico HTTP

# Variables de configuración
INTERFAZ="em0"  
IP_STATIC="192.168.1.1"
NETMASK="255.255.255.0"
DHCP_RANGE_START="192.168.1.100"
DHCP_RANGE_END="192.168.1.200"
GATEWAY="192.168.1.1"
BROADCAST="192.168.1.255"
SUFIJO_DNS="unah.edu.hn"
DNS_SERVER="192.168.1.10"

# Paso 1: Actualizar paquetes e instalar dependencias
echo "Actualizando paquetes..."
pkg update && pkg upgrade -y

echo "Instalando isc-dhcp44-server y apache24..."
pkg install -y isc-dhcp44-server apache24

# Paso 2: Configurar la IP estática
echo "Configurando la IP estática en la interfaz ${INTERFAZ}..."
sysrc ifconfig_${INTERFAZ}="inet ${IP_STATIC} netmask ${NETMASK}"
service netif restart

# Paso 3: Configurar DHCP
echo "Creando archivo de configuración DHCP en /usr/local/etc/dhcpd.conf..."
cat > /usr/local/etc/dhcpd.conf <<EOL
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet ${IP_STATIC%.*}.0 netmask ${NETMASK} {
    range ${DHCP_RANGE_START} ${DHCP_RANGE_END};
    option routers ${GATEWAY};
    option broadcast-address ${BROADCAST};
    option domain-name "${SUFIJO_DNS}";
    option domain-name-servers ${DNS_SERVER};
}
EOL

echo "Validando configuración DHCP..."
dhcpd -t -cf /usr/local/etc/dhcpd.conf
if [ $? -ne 0 ]; then
    echo "Error en dhcpd.conf. Por favor, revise el archivo."
    exit 1
fi

echo "Habilitando y arrancando el servicio DHCP..."
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="${INTERFAZ}"
service isc-dhcpd restart
service isc-dhcpd status

# Paso 4: Configurar Apache
echo "Habilitando y arrancando Apache..."
sysrc apache24_enable="YES"
service apache24 start

# Paso 5: Configurar firewall para permitir HTTP
echo "Configurando firewall para permitir tráfico HTTP en el puerto 80..."
if command -v ipfw > /dev/null 2>&1; then
    echo "Configurando regla en ipfw..."
    ipfw add allow tcp from any to any 80 in
fi

if [ -f /etc/pf.conf ]; then
    echo "Configurando regla en pf..."
    echo "pass in on ${INTERFAZ} proto tcp from any to any port 80" >> /etc/pf.conf
    pfctl -f /etc/pf.conf
    pfctl -e
fi

# Crear página HTML de prueba
echo "Creando página HTML de prueba para Apache..."
echo "<h1>¡Hola desde Apache en FreeBSD!</h1>" > /usr/local/www/apache24/data/index.html
chmod -R 755 /usr/local/www/apache24/data

echo "Configuración completa. DHCP y Apache están en ejecución."
echo "Prueba Apache accediendo a: http://${IP_STATIC}"
