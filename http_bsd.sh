#!/bin/sh

# Nombre del archivo: configurar_apache_cliente.sh
# Este script configura Apache en FreeBSD y permite el acceso desde una máquina cliente.

# Configurar variables
INTERFAZ="em0"  # Cambia esto si usas una interfaz diferente
IP_STATIC="192.168.1.1"  # Dirección IP estática del servidor FreeBSD
NETMASK="255.255.255.0"
DHCP_RANGE_START="192.168.1.100"
DHCP_RANGE_END="192.168.1.200"

# Paso 1: Actualizar el sistema
echo "Actualizando el sistema..."
pkg update && pkg upgrade -y

# Paso 2: Instalar Apache
echo "Instalando Apache..."
pkg install -y apache24

# Paso 3: Habilitar y arrancar el servicio Apache
echo "Habilitando Apache en /etc/rc.conf..."
sysrc apache24_enable="YES"

echo "Iniciando Apache..."
service apache24 start

# Paso 4: Configurar el firewall para permitir tráfico HTTP
echo "Configurando el firewall para permitir tráfico HTTP en el puerto 80..."
# Si estás usando ipfw
if command -v ipfw > /dev/null 2>&1; then
    echo "Detectado ipfw. Configurando regla para permitir tráfico HTTP."
    ipfw add allow tcp from any to any 80 in
fi

# Si estás usando pf
if [ -f /etc/pf.conf ]; then
    echo "Detectado pf. Configurando regla para permitir tráfico HTTP."
    echo "pass in on ${INTERFAZ} proto tcp from any to any port 80" >> /etc/pf.conf
    pfctl -f /etc/pf.conf
    pfctl -e
fi

# Paso 5: Configurar IP estática
echo "Configurando IP estática en la interfaz ${INTERFAZ}..."
sysrc ifconfig_${INTERFAZ}="inet ${IP_STATIC} netmask ${NETMASK}"
service netif restart

# Paso 6: Crear un archivo HTML de prueba
echo "Creando un archivo HTML de prueba en /usr/local/www/apache24/data..."
echo "<h1>¡Hola desde Apache en FreeBSD!</h1>" > /usr/local/www/apache24/data/index.html
chmod -R 755 /usr/local/www/apache24/data

# Paso 7: Verificar conectividad desde el cliente
echo "Para acceder al servidor desde la máquina cliente Windows:"
echo "1. Asegúrate de que la máquina cliente pueda hacer ping a ${IP_STATIC}."
echo "2. Abre un navegador en la máquina cliente e ingresa: http://${IP_STATIC}"

echo "Configuración completa. Apache está listo para recibir solicitudes."
