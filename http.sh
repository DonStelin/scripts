
#!/bin/bash

echo "Instalando Apache2..."
sudo apt-get install -y apache2

echo "Verificando el estado del servicio Apache2..."
sudo service apache2 status
sudo ufw enable
sudo ufw allow in "Apache Full"

echo "Estado final del firewall (UFW):"

sudo ufw status

echo "Configuración de Apache2 y ajustes del firewall completados."
