Este script faz o seguinte:

1. Atualiza o sistema e instala os pacotes necessários (iptables-persistent, rsyslog, fail2ban).
2. Habilita e inicia o serviço rsyslog.
3. Configura o iptables para:
 - Limpar regras anteriores.
 - Definir políticas padrão.
 - Permitir tráfego local.
 - Permitir conexões estabelecidas.
 - Permitir acesso SSH e HTTP/HTTPS.
 - Logar tráfego de entrada e saída.
4. Salva as regras do iptables.
5. Configura o Fail2Ban para proteger SSH, Apache2 e Nginx.
6. Reinicia o Fail2Ban para aplicar as configurações.
7. Mostra o status das regras do iptables e do Fail2Ban.

Para executar este script, salve-o em um arquivo, por exemplo setup_firewall.sh, dê permissão de execução (chmod +x setup_firewall.sh) e execute-o com privilégios de superusuário (sudo ./setup_firewall.sh).