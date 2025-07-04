#!/bin/bash
# Zabbix Server Installation Script for Ubuntu 22.04
# School Project - Free Tier Optimized

# Log function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/zabbix-install.log
}

log_message "Starting Zabbix Server installation..."

# Update system
log_message "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
log_message "Installing required packages..."
apt-get install -y wget curl apt-transport-https ca-certificates software-properties-common

# Install MySQL Server
log_message "Installing MySQL Server..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y mysql-server

# Secure MySQL installation
log_message "Configuring MySQL..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mysql_root_password}';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Install Zabbix repository
log_message "Installing Zabbix repository..."
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
apt-get update -y

# Install Zabbix server, frontend, and agent
log_message "Installing Zabbix Server, Frontend, and Agent..."
apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Create Zabbix database
log_message "Creating Zabbix database..."
mysql -uroot -p${mysql_root_password} -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -p${mysql_root_password} -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${mysql_root_password}';"
mysql -uroot -p${mysql_root_password} -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -uroot -p${mysql_root_password} -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -uroot -p${mysql_root_password} -e "FLUSH PRIVILEGES;"

# Import Zabbix database schema
log_message "Importing Zabbix database schema..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p${mysql_root_password} zabbix

# Disable log_bin_trust_function_creators
mysql -uroot -p${mysql_root_password} -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Configure Zabbix server
log_message "Configuring Zabbix server..."
sed -i "s/# DBPassword=/DBPassword=${mysql_root_password}/" /etc/zabbix/zabbix_server.conf

# Configure PHP for Zabbix frontend
log_message "Configuring PHP for Zabbix..."
sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Paris/' /etc/zabbix/apache.conf

# Restart and enable services
log_message "Starting Zabbix services..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

# Wait for services to start
sleep 10

# Configure firewall (UFW)
log_message "Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp
ufw --force enable

# Create a simple health check script
log_message "Creating health check script..."
cat > /usr/local/bin/zabbix-health.sh << 'EOF'
#!/bin/bash
echo "=== Zabbix Health Check ==="
echo "Date: $(date)"
echo "Zabbix Server Status: $(systemctl is-active zabbix-server)"
echo "Zabbix Agent Status: $(systemctl is-active zabbix-agent)"
echo "Apache Status: $(systemctl is-active apache2)"
echo "MySQL Status: $(systemctl is-active mysql)"
echo
echo "Listening Ports:"
netstat -tlnp | grep -E ":80|:10050|:10051|:3306"
echo
echo "Process Status:"
ps aux | grep -E "zabbix_server|zabbix_agentd" | grep -v grep
EOF

chmod +x /usr/local/bin/zabbix-health.sh

# Set up automatic updates for Zabbix
log_message "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
echo 'Unattended-Upgrade::Allowed-Origins {
    "Ubuntu:jammy-security";
    "Zabbix Official Repository";
};' > /etc/apt/apt.conf.d/51zabbix-updates

# Install additional monitoring tools
log_message "Installing additional monitoring tools..."
apt-get install -y htop iotop nethogs nmap

# Create informational file
log_message "Creating information file..."
cat > /home/ubuntu/zabbix-info.txt << EOF
=== ${project_name} - Zabbix Server Information ===

Installation completed: $(date)

🌐 Web Interface:
   - HTTP:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/zabbix
   - HTTPS: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/zabbix

🔑 Default Login:
   - Username: Admin
   - Password: zabbix (CHANGE THIS!)

📊 Server Details:
   - Zabbix Server: $(zabbix_server -V | head -n1)
   - MySQL Database: zabbix
   - Config: /etc/zabbix/zabbix_server.conf

🔧 Useful Commands:
   - Health Check: /usr/local/bin/zabbix-health.sh
   - Service Status: systemctl status zabbix-server
   - Logs: tail -f /var/log/zabbix/zabbix_server.log

⚠️  Security Notes:
   - Change default Zabbix admin password
   - Configure SSL certificate for HTTPS
   - Restrict access to specific IP ranges

📝 Next Steps:
   1. Access web interface and change admin password
   2. Configure monitoring hosts
   3. Set up email notifications
   4. Install Zabbix agents on clients

EOF

chown ubuntu:ubuntu /home/ubuntu/zabbix-info.txt

log_message "Zabbix Server installation completed successfully!"
log_message "Web interface will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/zabbix"
log_message "Default login: Admin / zabbix (PLEASE CHANGE!)"

# Run health check
/usr/local/bin/zabbix-health.sh >> /var/log/zabbix-install.log

log_message "Installation script finished. Check /var/log/zabbix-install.log for details." 