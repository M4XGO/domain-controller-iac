#!/bin/bash
# Zabbix Complete Installation and Fix Script
# Réinstallation complète de Zabbix pour résoudre les problèmes

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de log avec couleur
log_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

echo "============================================="
echo "🚀 RÉINSTALLATION COMPLÈTE DE ZABBIX"
echo "============================================="

# Vérifier si on est root
if [[ $EUID -ne 0 ]]; then
   log_error "Ce script doit être exécuté en tant que root (sudo)"
   exit 1
fi

# Configuration des mots de passe
MYSQL_ROOT_PASSWORD="ZabbixAdmin2024!"
PROJECT_NAME="Domain-Controller-LAB"

log_message "Configuration: mot de passe MySQL = $MYSQL_ROOT_PASSWORD"

# Phase 1: Nettoyage complet
echo ""
log_message "=== PHASE 1: NETTOYAGE COMPLET ==="

# Arrêter les services s'ils existent
systemctl stop zabbix-server 2>/dev/null || true
systemctl stop zabbix-agent 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true

# Supprimer les packages existants
log_message "Suppression des packages existants..."
apt-get remove --purge -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent 2>/dev/null || true
apt-get remove --purge -y mysql-server mysql-client 2>/dev/null || true
apt-get remove --purge -y apache2 2>/dev/null || true
apt-get autoremove -y

# Nettoyer les fichiers de configuration
rm -rf /etc/zabbix/ 2>/dev/null || true
rm -rf /var/lib/mysql/ 2>/dev/null || true
rm -rf /etc/mysql/ 2>/dev/null || true

log_success "Nettoyage terminé"

# Phase 2: Mise à jour du système
echo ""
log_message "=== PHASE 2: MISE À JOUR SYSTÈME ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

log_success "Système mis à jour"

# Phase 3: Installation des dépendances
echo ""
log_message "=== PHASE 3: INSTALLATION DES DÉPENDANCES ==="

apt-get install -y wget curl apt-transport-https ca-certificates software-properties-common
apt-get install -y net-tools htop

log_success "Dépendances installées"

# Phase 4: Installation MySQL
echo ""
log_message "=== PHASE 4: INSTALLATION MYSQL ==="

# Préconfigurer MySQL
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

apt-get install -y mysql-server

# Démarrer MySQL
systemctl start mysql
systemctl enable mysql

# Sécuriser MySQL
log_message "Configuration de MySQL..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || \
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"

mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

log_success "MySQL installé et configuré"

# Phase 5: Installation Zabbix
echo ""
log_message "=== PHASE 5: INSTALLATION ZABBIX ==="

# Télécharger et installer le repo Zabbix
cd /tmp
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
apt-get update -y

# Installer Zabbix
apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

log_success "Packages Zabbix installés"

# Phase 6: Configuration base de données
echo ""
log_message "=== PHASE 6: CONFIGURATION BASE DE DONNÉES ==="

# Créer la base Zabbix
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Importer le schéma
log_message "Import du schéma de base (cela peut prendre du temps)..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p$MYSQL_ROOT_PASSWORD zabbix

mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SET GLOBAL log_bin_trust_function_creators = 0;"

log_success "Base de données configurée"

# Phase 7: Configuration Zabbix
echo ""
log_message "=== PHASE 7: CONFIGURATION ZABBIX ==="

# Configurer Zabbix server
sed -i "s/# DBPassword=/DBPassword=$MYSQL_ROOT_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Configurer PHP pour Zabbix
sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Paris/' /etc/zabbix/apache.conf

log_success "Configuration Zabbix terminée"

# Phase 8: Installation Apache
echo ""
log_message "=== PHASE 8: INSTALLATION ET CONFIGURATION APACHE ==="

apt-get install -y apache2

# Configurer Apache pour Zabbix
a2enmod rewrite
a2ensite 000-default

# Créer un lien symbolique pour Zabbix
ln -sf /usr/share/zabbix /var/www/html/zabbix

# Ajuster les permissions
chown -R www-data:www-data /usr/share/zabbix/
chmod -R 755 /usr/share/zabbix/

log_success "Apache installé et configuré"

# Phase 9: Démarrage des services
echo ""
log_message "=== PHASE 9: DÉMARRAGE DES SERVICES ==="

systemctl restart mysql
systemctl restart apache2
systemctl restart zabbix-server
systemctl restart zabbix-agent

systemctl enable mysql
systemctl enable apache2
systemctl enable zabbix-server
systemctl enable zabbix-agent

# Attendre le démarrage
sleep 10

log_success "Services démarrés"

# Phase 10: Configuration firewall
echo ""
log_message "=== PHASE 10: CONFIGURATION FIREWALL ==="

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp
echo "y" | ufw enable

log_success "Firewall configuré"

# Phase 11: Tests et vérifications
echo ""
log_message "=== PHASE 11: TESTS ET VÉRIFICATIONS ==="

# Vérifier les services
echo "Services actifs:"
echo "  MySQL: $(systemctl is-active mysql)"
echo "  Apache2: $(systemctl is-active apache2)"
echo "  Zabbix Server: $(systemctl is-active zabbix-server)"
echo "  Zabbix Agent: $(systemctl is-active zabbix-agent)"

# Vérifier les ports
echo ""
echo "Ports ouverts:"
ss -tlnp | grep -E ":80|:3306|:10051" | while read line; do
    echo "  $line"
done

# Test de connectivité
echo ""
echo "Test de connectivité:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/zabbix/ || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    log_success "Zabbix Web Interface accessible localement"
else
    log_warning "Code HTTP: $HTTP_STATUS"
fi

# Obtenir l'IP publique
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "============================================="
echo "🎉 INSTALLATION TERMINÉE !"
echo "============================================="
echo ""
echo "📊 Accès à Zabbix:"
echo "   🌐 URL Publique:  http://$PUBLIC_IP/zabbix"
echo "   🏠 URL Privée:    http://$PRIVATE_IP/zabbix"
echo "   🖥️  URL Locale:    http://localhost/zabbix"
echo ""
echo "🔑 Connexion par défaut:"
echo "   👤 Nom d'utilisateur: Admin"
echo "   🔒 Mot de passe:      zabbix"
echo ""
echo "⚠️  IMPORTANT:"
echo "   🔐 Changez immédiatement le mot de passe par défaut !"
echo "   🛡️  Configurez SSL pour la production"
echo ""
echo "🔧 Scripts utiles créés:"

# Créer un script de diagnostic
cat > /usr/local/bin/zabbix-status.sh << 'STATUSEOF'
#!/bin/bash
echo "=== STATUT ZABBIX ==="
echo "Date: $(date)"
echo ""
echo "Services:"
systemctl status mysql --no-pager -l | head -3
systemctl status apache2 --no-pager -l | head -3  
systemctl status zabbix-server --no-pager -l | head -3
systemctl status zabbix-agent --no-pager -l | head -3
echo ""
echo "Ports ouverts:"
ss -tlnp | grep -E ":80|:3306|:10051"
echo ""
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "🌐 URL: http://$PUBLIC_IP/zabbix"
STATUSEOF

chmod +x /usr/local/bin/zabbix-status.sh

echo "   📋 /usr/local/bin/zabbix-status.sh (vérifier le statut)"

# Créer un alias
echo "alias zabbix-status='/usr/local/bin/zabbix-status.sh'" >> /home/ubuntu/.bashrc

# Créer le fichier d'information
cat > /home/ubuntu/zabbix-info.txt << INFOEOF
=== $PROJECT_NAME - Zabbix Server Information ===

Installation completed: $(date)

🌐 Web Interface:
   - HTTP:  http://$PUBLIC_IP/zabbix
   - Local: http://localhost/zabbix

🔑 Default Login:
   - Username: Admin
   - Password: zabbix (CHANGE THIS!)

📊 Server Details:
   - Zabbix Server: $(zabbix_server -V | head -n1 2>/dev/null || echo "Version info unavailable")
   - MySQL Database: zabbix
   - Config: /etc/zabbix/zabbix_server.conf

🔧 Useful Commands:
   - Status Check: zabbix-status
   - Service Status: systemctl status zabbix-server
   - Logs: tail -f /var/log/zabbix/zabbix_server.log

📝 Next Steps:
   1. Change default admin password
   2. Configure monitoring hosts  
   3. Set up email notifications
   4. Install Zabbix agents on clients

INFOEOF

chown ubuntu:ubuntu /home/ubuntu/zabbix-info.txt

echo ""
log_success "Installation complète terminée avec succès !"
echo ""
echo "▶️  Exécutez 'zabbix-status' pour vérifier le statut"
echo "📖 Consultez ~/zabbix-info.txt pour plus d'informations" 