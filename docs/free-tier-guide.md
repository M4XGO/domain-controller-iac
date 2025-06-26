# Guide AWS Free Tier - Domain Controller Infrastructure

## 🎯 Objectif : Infrastructure complète pour ~0,50€/mois

Ce guide détaille comment maximiser l'utilisation du **AWS Free Tier** pour déployer une infrastructure Domain Controller Active Directory complète tout en restant dans les limites gratuites.

## 📊 Limites du AWS Free Tier (12 mois)

### ✅ Ressources gratuites utilisées
| Service | Limite Free Tier | Notre utilisation | Status |
|---------|------------------|-------------------|--------|
| **EC2 t2.micro** | 750h/mois | ~700h/mois (2 instances) | ✅ |
| **EBS GP2/Magnetic** | 30GB/mois | 25GB total | ✅ |
| **CloudWatch** | 10 métriques custom | Métriques basiques | ✅ |
| **Route53 Queries** | 1M queries/mois | <10K queries | ✅ |
| **Data Transfer** | 15GB/mois | <5GB/mois | ✅ |
| **VPC** | Illimité | 1 VPC, IGW, SG | ✅ |

### 💰 Seuls coûts mensuels
- **Route53 hosted zone** : ~0,50€/mois
- **Total** : ~0,50€/mois

## 🏗️ Optimisations appliquées

### 1. 🖥️ Instances EC2 (t2.micro)

#### ✅ Optimisations
```hcl
# Au lieu de t3.medium (25€/mois)
instance_type = "t2.micro"  # 0€/mois (Free Tier)

# Au lieu de t3.small (15€/mois) 
vpn_instance_type = "t2.micro"  # 0€/mois (Free Tier)
```

#### ⚡ Performance t2.micro
- **CPU** : 1 vCPU (burstable)
- **RAM** : 1 GB
- **Réseau** : Low to Moderate
- **Stockage** : EBS uniquement

#### 📈 Utilisation des crédits CPU
- **Base performance** : 10% CPU constant
- **Burst credits** : Accumulation jusqu'à 30 crédits
- **Surveillance** : Monitoring des crédits via CloudWatch

### 2. 💾 Stockage optimisé

#### ✅ Configuration Free Tier
```hcl
# Volume unique au lieu de 3 volumes séparés
root_volume_size = 25    # ✅ Free Tier (30GB max)
data_volume_size = 0     # ✅ Désactivé
logs_volume_size = 0     # ✅ Désactivé
volume_type = "gp2"      # ✅ GP2 inclus (vs GP3 payant)
```

#### 📁 Organisation du stockage
```
C:\ (25GB GP2)
├── Windows System (15GB)
├── NTDS Database (5GB max)
├── SYSVOL (2GB)
├── Logs (2GB, rotation 1 jour)
└── Applications (1GB)
```

### 3. 🌐 Réseau sans coûts

#### ✅ Élimination des coûts réseau
```hcl
# NAT Gateway supprimé : économie 32€/mois
enable_nat_gateway = false

# Single AZ : pas de coûts multi-AZ
availability_zones = ["eu-west-1a"]

# Pas d'ALB : économie 16€/mois
enable_load_balancer = false
```

#### 🔄 Architecture réseau simplifiée
```
Internet Gateway (gratuit)
    ↓
Public Subnet (PfSense t2.micro)
    ↓ (route direct)
Private Subnet (DC t2.micro)
```

### 4. 📊 Monitoring allégé

#### ✅ CloudWatch Free Tier
```hcl
# Logs réduits pour économiser
log_retention_days = 1

# Monitoring basique seulement
enable_enhanced_monitoring = false

# Pas d'alertes SNS (coûteuses)
enable_sns_alerts = false
```

#### 📈 Métriques surveillées (gratuites)
- CPU Utilization
- Memory Utilization  
- Disk Space Utilization
- Network In/Out
- Status Check Failed

### 5. 🛡️ Sécurité maintenue

#### ✅ Mesures gratuites appliquées
```hcl
# Security Groups restrictifs (gratuit)
# Chiffrement EBS (gratuit)
# IAM roles et policies (gratuit)
# VPC Flow Logs désactivés (coûteux)
```

## ⚠️ Limitations acceptées

### 📉 Performance
- **Utilisateurs max** : 10-20 comptes AD
- **Authentifications simultanées** : 5-10
- **Temps de réponse** : Plus lent qu'en production
- **Pas de haute disponibilité**

### 💾 Stockage
- **Base AD limitée** : ~5GB max données
- **Pas de backup automatique**
- **Logs rotation agressive** (1 jour)

### 🔍 Monitoring
- **Métriques basiques** seulement
- **Pas d'alertes automatiques**
- **Surveillance manuelle** requise

## 🚀 Migration post-Free Tier

### Après 12 mois (fin Free Tier)

#### 💰 Coûts à prévoir
```
t2.micro instances : ~15€/mois (2 instances)
EBS 30GB : ~3€/mois
Route53 : ~0.50€/mois
Total : ~18.50€/mois
```

#### 📈 Options d'upgrade
```hcl
# Upgrade performance
instance_type = "t3.small"      # +10€/mois
data_volume_size = 50           # +5€/mois
enable_nat_gateway = true       # +32€/mois
log_retention_days = 30         # +2€/mois
```

## 🔧 Scripts d'optimisation

### Surveillance des limites Free Tier

```bash
#!/bin/bash
# check-free-tier-usage.sh
echo "=== AWS Free Tier Usage Check ==="

# Check EC2 hours
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -d '1 month ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum

# Check EBS usage
aws ec2 describe-volumes --query 'Volumes[*].[Size,State]' --output table

# Check data transfer
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkOut \
  --start-time $(date -d '1 month ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum
```

### Nettoyage automatique des logs

```powershell
# cleanup-logs.ps1 (à exécuter sur le DC)
$LogPath = "C:\Windows\Logs"
$MaxAge = 1 # jour

Get-ChildItem $LogPath -Recurse -File | 
Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$MaxAge)} |
Remove-Item -Force

# Nettoyer les logs Event Viewer
wevtutil cl Application
wevtutil cl System
```

## 📊 Tableau de bord des coûts

### Surveillance mensuelle recommandée

| Service | Budget max | Alerte à | Action |
|---------|------------|----------|--------|
| EC2 | 0€ | 0.10€ | Vérifier instances |
| EBS | 0€ | 0.50€ | Réduire volumes |
| CloudWatch | 0€ | 1€ | Réduire logs |
| Data Transfer | 0€ | 1€ | Limiter trafic |
| **Total** | **1€** | **2€** | **Audit complet** |

### Alertes AWS Budgets
```json
{
  "BudgetName": "DomainController-FreeTier",
  "BudgetLimit": {
    "Amount": "1.00",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

## ✅ Checklist Free Tier

### Avant déploiement
- [ ] Compte AWS < 12 mois
- [ ] Variables Free Tier configurées
- [ ] Région avec Free Tier disponible
- [ ] Pas d'autres instances t2.micro actives

### Pendant le déploiement
- [ ] Instances t2.micro créées
- [ ] Volume unique 25GB max
- [ ] Pas de NAT Gateway
- [ ] Monitoring basique seulement

### Après déploiement
- [ ] Coût total < 1€/mois
- [ ] Performance acceptable pour lab
- [ ] Surveillance manuelle active
- [ ] Scripts de cleanup programmés

### Surveillance continue
- [ ] Vérification mensuelle des coûts
- [ ] Monitoring crédits CPU
- [ ] Rotation logs active
- [ ] Backup manuel si nécessaire

## 🎓 Cas d'usage recommandés

### ✅ Idéal pour
- **Formation** Active Directory
- **Lab personnel** DevOps
- **POC** et démonstrations
- **Développement** applications AD
- **Apprentissage** AWS

### ❌ À éviter
- **Production** entreprise
- **Plus de 10 utilisateurs**
- **Données critiques**
- **Performance élevée**
- **Haute disponibilité**

## 📞 Support et troubleshooting

### Dépassement Free Tier
```bash
# Vérifier l'utilisation actuelle
aws ce get-dimension-values \
  --dimension Key=SERVICE \
  --time-period Start=2024-01-01,End=2024-01-31

# Arrêter les instances pour économiser
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
```

### Performance dégradée
```powershell
# Vérifier crédits CPU (sur DC Windows)
Get-Counter "\Processor(_Total)\% Processor Time"

# Optimiser services Windows
Set-Service -Name "Spooler" -StartupType Disabled
Set-Service -Name "Fax" -StartupType Disabled
```

### Aide en cas de coûts inattendus
1. **Billing Dashboard** : Console AWS → Billing
2. **Cost Explorer** : Analyse détaillée
3. **Support AWS** : Plan basique gratuit
4. **Community** : Forums AWS, Stack Overflow

*Ce guide vous permet de profiter pleinement du AWS Free Tier pour votre apprentissage Active Directory tout en maintenant un contrôle strict des coûts.* 