#!/bin/sh

# Nombre del archivo: configurar_dns_apache.sh
# Este script configura un servidor DNS con BIND en FreeBSD para resolver el dominio servidor.unah.edu.hn
# y ajusta Apache para responder al dominio.

# Variables
DOMAIN="unah.edu.hn"
HOSTNAME="servidor"
IP_SERVER="192.168.1.1"  # Dirección IP del servidor FreeBSD
REVERSE_ZONE="1.168.192"
BIND_DIR="/usr/local/etc/namedb"

# Paso 1: Habilitar e iniciar BIND
echo "Habilitando BIND..."
sysrc named_enable="YES"

# Paso 2: Configurar named.conf
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

# Paso 3: Crear archivo de zona directa
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
${HOSTNAME} IN  A   ${IP_SERVER}
EOL

# Paso 4: Crear archivo de zona inversa
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
1       IN  PTR     ${HOSTNAME}.${DOMAIN}.
EOL

# Paso 5: Verificar configuración de BIND
echo "Verificando configuración de BIND..."
named-checkconf
named-checkzone ${DOMAIN} ${BIND_DIR}/master/db.${DOMAIN}
named-checkzone ${REVERSE_ZONE}.in-addr.arpa ${BIND_DIR}/master/db.${REVERSE_ZONE}

# Paso 6: Iniciar BIND
echo "Iniciando el servicio BIND..."
service named restart

# Paso 7: Configurar Apache para el dominio
echo "Configurando Apache para ${HOSTNAME}.${DOMAIN}..."
cat >> /usr/local/etc/apache24/httpd.conf <<EOL

<VirtualHost *:80>
    ServerName ${HOSTNAME}.${DOMAIN}
    DocumentRoot "/usr/local/www/apache24/data"
    <Directory "/usr/local/www/apache24/data">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

# Reiniciar Apache
echo "Reiniciando Apache..."
service apache24 restart

# Paso 8: Configurar resolv.conf
echo "Configurando resolv.conf para usar el servidor DNS local..."
cat > /etc/resolv.conf <<EOL
nameserver ${IP_SERVER}
search ${DOMAIN}
EOL

# Paso 9: Prueba final
echo "Configuración completada. Verifica desde un cliente que utilice ${IP_SERVER} como servidor DNS."
echo "Puedes probar con: http://${HOSTNAME}.${DOMAIN}."
