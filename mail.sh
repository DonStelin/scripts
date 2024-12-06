
#!/bin/bash


check_error() {
    if [ $? -ne 0 ]; then
        echo "Ocurrió un error. Saliendo del script..."
        exit 1
    fi
}

echo "Instalando Postfix..."
sudo apt install -y postfix
check_error

echo "Configurando Postfix..."
sudo bash -c 'cat > /etc/postfix/main.cf' <<EOL
myhostname = correo.unah.edu.hn
myorigin = /etc/mailname
mydestination = \$myhostname, unah.edu.hn
mynetworks = 192.168.1.0/24
home_mailbox = Maildir/
EOL
echo "correo.unah.edu.hn" | sudo tee /etc/mailname
sudo service postfix restart
check_error

echo "Instalando Dovecot..."
sudo apt install -y dovecot-imapd dovecot-pop3d
check_error

echo "Configurando Dovecot..."
sudo sed -i 's/^disable_plaintext_auth =.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
check_error

sudo sed -i 's/^#mail_location =.*/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i 's/^mail_location =.*/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
check_error

sudo sed -i 's/^ssl =.*/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf
check_error

sudo systemctl restart dovecot
sudo systemctl enable dovecot
check_error

echo "Creando cuentas de correo..."
usuarios=("arch" "fedora")
for usuario in "${usuarios[@]}"; do
    sudo adduser --disabled-password --gecos "" $usuario
    check_error
    echo "$usuario:$usuario" | sudo chpasswd
done

# Pruebas
echo "Realizando pruebas de conectividad..."
ping -c 4 correo.unah.edu.hn
echo "Configuración completada exitosamente."
