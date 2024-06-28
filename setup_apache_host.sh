#!/bin/bash

# Verifica se o Apache2 está instalado
is_installed() {
    dpkg -l | grep -q "^ii  $1"
}

if ! is_installed "apache2"; then
    echo "Apache2 não está instalado. Instalando..."
    sudo apt update
    sudo apt install -y apache2
else
    echo "Apache2 já está instalado."
fi

# Define o diretório do documento raiz e cria-o, se não existir
DOC_ROOT="/var/www/test_site"
if [ ! -d "$DOC_ROOT" ]; then
    sudo mkdir -p "$DOC_ROOT"
    sudo chown -R $USER:$USER "$DOC_ROOT"
    echo "<html><body><h1>Site de Teste</h1></body></html>" > "$DOC_ROOT/index.html"
fi

# Cria um novo arquivo de configuração para o host virtual
VHOST_CONF="/etc/apache2/sites-available/test_site.conf"
sudo bash -c 'cat << EOF > '"$VHOST_CONF"'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot '"$DOC_ROOT"'
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory '"$DOC_ROOT"'>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF'

# Desabilita o site padrão e habilita o novo site de teste
sudo a2dissite 000-default.conf
sudo a2ensite test_site.conf

# Reinicia o Apache2 para aplicar as mudanças
sudo systemctl restart apache2

echo "Host virtual de teste configurado com sucesso. Você pode acessar o site localmente em http://localhost"