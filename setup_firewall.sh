#!/bin/bash

# Função para verificar se um pacote está instalado
is_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# Atualiza o sistema e instala pacotes necessários se não estiverem instalados
if ! is_installed "rsyslog"; then
    sudo apt update
    sudo apt install -y rsyslog
fi

if ! is_installed "iptables-persistent"; then
    sudo apt update
    sudo apt install -y iptables-persistent
fi

if ! is_installed "fail2ban"; then
    sudo apt update
    sudo apt install -y fail2ban
fi

# Habilita o serviço rsyslog
sudo systemctl enable rsyslog
sudo systemctl start rsyslog

# Configurações do Firewall (iptables)

# Limpa todas as regras anteriores
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# Define políticas padrão
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Permite tráfego local (loopback)
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Permite conexões já estabelecidas e relacionadas
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permite acesso SSH (porta 22)
sudo iptables -A INPUT -p tcp --dport 22 -m comment --comment "Allow SSH" -j ACCEPT

# Permite HTTP (porta 80) e HTTPS (porta 443) para Apache2 e Nginx
sudo iptables -A INPUT -p tcp --dport 80 -m comment --comment "Allow HTTP" -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -m comment --comment "Allow HTTPS" -j ACCEPT

# Registra pacotes de entrada e saída para syslog
sudo iptables -A INPUT -j LOG --log-prefix "iptables-input: " --log-level 4
sudo iptables -A OUTPUT -j LOG --log-prefix "iptables-output: " --log-level 4

# Salva as regras do iptables
sudo netfilter-persistent save

# Configuração do RSYSLOG para coletar e organizar logs
sudo bash -c 'cat << EOF > /etc/rsyslog.d/iptables.conf
:msg,contains,"iptables-input: " /var/log/iptables_input.log
:msg,contains,"iptables-output: " /var/log/iptables_output.log
& stop
EOF'

sudo bash -c 'cat << EOF > /etc/rsyslog.d/sshd.conf
:programname,startswith,"sshd" /var/log/sshd.log
& stop
EOF'

sudo bash -c 'cat << EOF > /etc/rsyslog.d/apache2.conf
:programname,startswith,"apache2" /var/log/apache2.log
& stop
EOF'

sudo bash -c 'cat << EOF > /etc/rsyslog.d/nginx.conf
:programname,startswith,"nginx" /var/log/nginx.log
& stop
EOF'

# Reinicia o serviço rsyslog para aplicar as configurações
sudo systemctl restart rsyslog

# Verifica se Apache2 ou Nginx está instalado
APACHE_INSTALLED=false
NGINX_INSTALLED=false

if is_installed "apache2"; then
    APACHE_INSTALLED=true
fi

if is_installed "nginx"; then
    NGINX_INSTALLED=true
fi

# Configuração do Fail2Ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configura proteção para SSH, Apache2 e Nginx no Fail2Ban
sudo bash -c 'cat << EOF > /etc/fail2ban/jail.d/custom.conf
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF'

# Configuração específica para Apache2 se instalado
if [ "$APACHE_INSTALLED" = true ]; then
    sudo bash -c 'cat << EOF >> /etc/fail2ban/jail.d/custom.conf

[apache-auth]
enabled = true
port = http,https
logpath = %(apache_error_log)s
EOF'
fi

# Configuração específica para Nginx se instalado
if [ "$NGINX_INSTALLED" = true ]; then
    sudo bash -c 'cat << EOF >> /etc/fail2ban/jail.d/custom.conf

[nginx-http-auth]
enabled = true
port = http,https
logpath = %(nginx_error_log)s
EOF'
fi

# Reinicia o Fail2Ban para aplicar as configurações
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Mostra status das regras do firewall e do Fail2Ban
sudo iptables -L -v -n
sudo fail2ban-client status