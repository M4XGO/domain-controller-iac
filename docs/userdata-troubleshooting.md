# Guide de dépannage des scripts UserData

## ❓ Problème : Les scripts ne s'exécutent pas automatiquement

### 🔍 **Diagnostic**

#### **1. Vérifier les logs UserData AWS**
```powershell
# Sur les machines Windows
Get-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserdataExecution.log"

# Ou vérifier tous les logs
Get-ChildItem "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\" | Sort-Object LastWriteTime
```

#### **2. Vérifier si les scripts sont présents**
```powershell
# Domain Controller
Test-Path "C:\dcsetup.log"
Test-Path "C:\Windows\Temp\dc-userdata-manual.ps1"

# Client Windows  
Test-Path "C:\client-setup.log"
Test-Path "C:\Windows\Temp\client-userdata-manual.ps1"
```

#### **3. Vérifier l'Execution Policy**
```powershell
Get-ExecutionPolicy
# Devrait être "Unrestricted" ou "RemoteSigned"
```

---

## 🛠️ **Solutions**

### **Option 1 : Exécuter manuellement les scripts sauvegardés**

#### **Domain Controller**
```powershell
# Ouvrir PowerShell en tant qu'Administrateur
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

# Exécuter le script de configuration
C:\Windows\Temp\dc-userdata-manual.ps1

# Ou exécuter le script de diagnostic
C:\Windows\Temp\startup-manual.ps1
```

#### **Client Windows**
```powershell
# Ouvrir PowerShell en tant qu'Administrateur  
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

# Exécuter le script de configuration
C:\Windows\Temp\client-userdata-manual.ps1

# Ou exécuter le script de diagnostic
C:\Windows\Temp\startup-manual.ps1
```

### **Option 2 : Configuration manuelle étape par étape**

#### **Domain Controller**
```powershell
# 1. Définir le mot de passe Administrateur
net user Administrator "VotreMotDePasse"
net user Administrator /active:yes

# 2. Installer AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools

# 3. Configurer le domaine
Import-Module ADDSDeployment
$securePassword = ConvertTo-SecureString "SafeModePassword" -AsPlainText -Force

Install-ADDSForest `
    -DomainName "school.local" `
    -DomainNetbiosName "SCHOOL" `
    -SafeModeAdministratorPassword $securePassword `
    -InstallDns:$true `
    -Force:$true
```

#### **Client Windows**
```powershell
# 1. Configurer DNS vers le Domain Controller
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.0.1.10"

# 2. Joindre le domaine
$credential = Get-Credential # Entrer SCHOOL\Administrator
Add-Computer -DomainName "school.local" -Credential $credential

# 3. Redémarrer
Restart-Computer
```

---

## 📋 **Checklist de vérification**

### **Domain Controller**
- [ ] ✅ Active Directory installé (`Get-WindowsFeature -Name AD-Domain-Services`)
- [ ] ✅ DNS Server installé (`Get-WindowsFeature -Name DNS`)
- [ ] ✅ Domaine `school.local` créé (`Get-ADDomain`)
- [ ] ✅ DNS forwarders configurés (`Get-DnsServerForwarder`)
- [ ] ✅ Zone reverse créée (`Get-DnsServerZone`)

### **Client Windows**
- [ ] ✅ DNS pointant vers 10.0.1.10 (`Get-DnsClientServerAddress`)
- [ ] ✅ Joint au domaine (`Get-ComputerInfo | Select CsDomain`)
- [ ] ✅ Services clients activés (`Get-Service Workstation`)
- [ ] ✅ Agent Zabbix installé (`Get-Service "Zabbix Agent"`)

### **Zabbix Server (Ubuntu)**
- [ ] ✅ Service Zabbix actif (`sudo systemctl status zabbix-server`)
- [ ] ✅ MySQL actif (`sudo systemctl status mysql`)
- [ ] ✅ Apache actif (`sudo systemctl status apache2`)
- [ ] ✅ Interface web accessible (http://IP-PUBLIC/zabbix)

---

## 🔧 **Commandes de diagnostic utiles**

```powershell
# Vérifier la configuration réseau
Get-NetIPConfiguration
Test-NetConnection -ComputerName "school.local" -Port 53

# Vérifier Active Directory
Get-ADDomain
Get-ADUser Administrator
Get-ADComputer -Filter *

# Vérifier DNS
nslookup school.local
nslookup 10.0.1.10

# Vérifier les services
Get-Service | Where-Object {$_.Name -match "DNS|Netlogon|ADWS"}

# Logs Windows
Get-EventLog -LogName System -Newest 20
Get-EventLog -LogName Application -Source "DC-Setup" -Newest 10
```

---

## 🆘 **En cas d'échec complet**

### **Option : Recréer l'instance**
```bash
# Détruire et recréer avec les corrections
terraform destroy -target=module.domain_controller
terraform apply -target=module.domain_controller
```

### **Option : Utiliser les scripts de démarrage manuel**
Les scripts `startup-manual.ps1` sont conçus pour diagnostiquer et corriger les problèmes automatiquement.

---

## 📞 **Support supplémentaire**

1. **Logs détaillés** : Tous les scripts sauvegardent des logs détaillés
2. **Scripts manuels** : Chaque module a un script de démarrage manuel
3. **AWS CloudWatch** : Les logs peuvent aussi être dans CloudWatch
4. **Event Viewer** : Utiliser l'Observateur d'événements Windows

Les scripts sont maintenant configurés pour :
- ✅ S'exécuter automatiquement avec les balises `<powershell>`
- ✅ Configurer l'Execution Policy automatiquement  
- ✅ Sauvegarder des copies manuelles
- ✅ Logger de manière détaillée
- ✅ Fournir des scripts de diagnostic 