#!/bin/sh

# Nombre del archivo: configurar_dns.sh
# Este script configura un servidor DNS con BIND en FreeBSD para resolver nombres locales.

# Variables
DOMAIN="unah.edu.hn"
IP_SERVER="192.168.1.1"  # IP del servidor FreeBSD
REVERSE_ZONE="1.168.192"
BIND_DIR="/usr/local/etc/namedb"

# Paso 1: Instalar BIND
echo "Instalando BIND..."
pkg install -y bind911

# Paso 2: Habilitar BIND en rc.conf
echo "Habilitando BIND en /etc/rc.conf..."
sysrc named_enable="YES"

# Paso 3: Configurar named.conf
echo "Configurando named.conf..."
cat > ${BIND_DIR}/named.conf <<EOL
options {
    directory "${BIND_DIR}";
    allow-query { any; };
    recursion yes;
};

zone "${DOMAIN}" {
    type master;
    file "${BIND_DIR}/master/db.${DOMAIN}";
};

zone "${REVERSE_ZONE}.in-addr.arpa" {
    type master;
    file "${BIND_DIR}/master/db.${REVERSE_ZONE}";
};
EOL

# Paso 4: Configurar la zona de búsqueda directa
echo "Creando archivo de zona directa para ${DOMAIN}..."
mkdir -p ${BIND_DIR}/master
cat > ${BIND_DIR}/master/db.${DOMAIN} <<EOL
\$TTL 604800
@   IN  SOA ns.${DOMAIN}. admin.${DOMAIN}. (
        1 ; Serial
        604800 ; Refresh
        86400 ; Retry
        2419200 ; Expire
        604800 ) ; Negative Cache TTL
;
@       IN  NS      ns.${DOMAIN}.
ns      IN  A       ${IP_SERVER}
@       IN  A       ${IP_SERVER}
www     IN  A       ${IP_SERVER}
EOL

# Paso 5: Configurar la zona de búsqueda inversa
echo "Creando archivo de zona inversa para ${REVERSE_ZONE}..."
cat > ${BIND_DIR}/master/db.${REVERSE_ZONE} <<EOL
\$TTL 604800
@   IN  SOA ns.${DOMAIN}. admin.${DOMAIN}. (
        1 ; Serial
        604800 ; Refresh
        86400 ; Retry
        2419200 ; Expire
        604800 ) ; Negative Cache TTL
;
@       IN  NS      ns.${DOMAIN}.
1       IN  PTR     www.${DOMAIN}.
EOL

# Paso 6: Verificar la configuración
echo "Verificando la configuración de BIND..."
named-checkconf
named-checkzone ${DOMAIN} ${BIND_DIR}/master/db.${DOMAIN}
named-checkzone ${REVERSE_ZONE}.in-addr.arpa ${BIND_DIR}/master/db.${REVERSE_ZONE}

# Paso 7: Iniciar el servicio BIND
echo "Iniciando el servicio BIND..."
service named restart

# Paso 8: Configurar el cliente DNS en FreeBSD
echo "Configurando el servidor DNS en resolv.conf..."
cat > /etc/resolv.conf <<EOL
nameserver ${IP_SERVER}
search ${DOMAIN}
EOL

# Mensaje final
echo "Configuración completada. Ahora puedes acceder a la página de Apache usando:"
echo "http://www.${DOMAIN} desde cualquier cliente que utilice este servidor como DNS."
