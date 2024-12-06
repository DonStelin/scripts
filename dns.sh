
#!/bin/bash

check_error() {
    if [ $? -ne 0 ]; then
        echo "Ocurrió un error. Saliendo del script..."
        exit 1
    fi
}


echo "Instalando el servicio BIND9..."
sudo apt install -y bind9
check_error

echo "Instalando resolvconf..."
sudo apt install -y resolvconf
check_error

echo "Configurando archivo nsswitch.conf..."
sudo sed -i 's/hosts: .*/hosts: dns files/' /etc/nsswitch.conf
check_error

echo "Configurando archivo named.conf.local..."
sudo bash -c 'cat > /etc/bind/named.conf.local' <<EOL
zone "unah.edu.hn" {
    type master;
    file "/etc/bind/db.unah.edu.hn";
};
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.1.168.192";
};
EOL
check_error

echo "Creando archivos de zona..."
sudo cp /etc/bind/db.local /etc/bind/db.unah.edu.hn
sudo sed -i 's/localhost/unah.edu.hn/g' /etc/bind/db.unah.edu.hn
sudo sed -i '/AAAA/d' /etc/bind/db.unah.edu.hn

sudo cp /etc/bind/db.127 /etc/bind/db.1.168.192
sudo sed -i 's/localhost/unah.edu.hn/g' /etc/bind/db.1.168.192
sudo sed -i 's/1.0.0/1.168.192/g' /etc/bind/db.1.168.192

echo "Verificando configuración de named.conf.local..."
sudo named-checkconf
check_error

echo "Verificando configuración de zona directa..."
sudo named-checkzone unah.edu.hn /etc/bind/db.unah.edu.hn
check_error

echo "Verificando configuración de zona inversa..."
sudo named-checkzone 1.168.192.in-addr.arpa /etc/bind/db.1.168.192
check_error

echo "Reiniciando servicio BIND9..."
sudo /etc/init.d/bind9 restart
check_error

echo "Verificando conectividad..."
ping -c 4 192.168.1.10
host servidor
nslookup servidor.unah.edu.hn
dig servidor.unah.edu.hn

echo "Configuración completada exitosamente."
