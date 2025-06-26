# Architecture - Domain Controller Infrastructure (AWS Free Tier Optimized)

## 🏗️ Vue d'ensemble

Cette infrastructure déploie automatiquement un **domaine contrôleur Active Directory sur AWS**, connecté à des machines locales VMware via un **VPN sécurisé**. L'ensemble est 100% automatisé avec **Terraform**, **Packer** et **Ansible**, et **optimisé pour maximiser l'usage du AWS Free Tier**.

## 💰 Optimisation AWS Free Tier

### 🎯 Objectif : Infrastructure complète pour ~0,50€/mois
- **Compute** : 2x t2.micro (700h/750h Free Tier)
- **Storage** : 25GB GP2 (30GB Free Tier)
- **Monitoring** : CloudWatch basique + SSM (Free Tier)
- **Réseau** : Pas de NAT Gateway (économie de ~32€/mois)
- **Seul coût** : Route53 zone privée (~0,50€/mois)

## 📊 Diagrammes d'architecture

### 🌐 Architecture réseau générale

Le diagramme ci-dessus montre l'architecture complète avec toutes les optimisations Free Tier appliquées.

### 🔄 Flux de déploiement

Le diagramme de déploiement illustre les 4 phases d'automatisation : Packer → Terraform → Ansible → Client Setup.

### 💡 Stratégie d'optimisation Free Tier

Le diagramme des optimisations montre comment nous restons dans les limites du Free Tier tout en conservant toutes les fonctionnalités.

## 🏛️ Composants de l'infrastructure

### 📡 Réseau AWS (Free Tier)
- **VPC** : 10.0.0.0/16 dans une seule AZ (économie multi-AZ)
- **Subnet public** : 10.0.1.0/24 (PfSense VPN)
- **Subnet privé** : 10.0.10.0/24 (Domain Controller)
- **Route53** : Zone DNS privée pour corp.local (~0,50€/mois)
- **Internet Gateway** : Accès internet gratuit
- **PAS de NAT Gateway** : Économie de ~32€/mois

### 🖥️ Serveurs (Free Tier)

#### Domain Controller (Windows Server 2022)
- **Instance** : **t2.micro** (Free Tier - 750h/mois)
- **CPU/RAM** : 1 vCPU, 1 GB RAM (suffisant pour lab/dev)
- **Stockage** : 
  - Volume unique : **25 GB GP2** (Free Tier - 30GB/mois)
  - Pas de volumes séparés (optimisation Free Tier)
- **Rôles** :
  - Active Directory Domain Services
  - DNS Server
  - ~~DHCP Server~~ (supprimé pour alléger)
- **Sécurité** : Chiffrement EBS, Security Groups restrictifs

#### PfSense VPN Router
- **Instance** : **t2.micro** (Free Tier - partage 750h/mois)
- **CPU/RAM** : 1 vCPU, 1 GB RAM
- **Stockage** : Volume root 25GB (dans limite Free Tier)
- **Fonctions** :
  - Routeur VPN OpenVPN
  - Firewall basique
  - Pas de monitoring avancé (économie)

### 🔐 Sécurité (Free Tier)

#### Security Groups
- **Domain Controller SG** :
  - Port 53 (DNS) : UDP/TCP depuis VPC
  - Port 88 (Kerberos) : UDP/TCP depuis VPC  
  - Port 135 (RPC) : TCP depuis VPC
  - Port 389/636 (LDAP/LDAPS) : TCP depuis VPC
  - Port 445 (SMB) : TCP depuis VPC
  - Port 464 (Kerberos Password) : UDP/TCP depuis VPC
  - Port 3268/3269 (Global Catalog) : TCP depuis VPC
  - Ports dynamiques RPC : 49152-65535 depuis VPC

- **PfSense VPN SG** :
  - Port 22 (SSH) : TCP depuis IP admin
  - Port 443 (Web UI) : TCP depuis IP admin
  - Port 1194 (OpenVPN) : UDP depuis 0.0.0.0/0

#### IAM Roles (Free Tier)
- **Domain Controller Role** :
  - SSM Management (Free Tier)
  - CloudWatch Logs basique (Free Tier)
  - EC2 Tags Read (Free)

### 📊 Monitoring (Free Tier)

#### CloudWatch (Optimisé)
- **Métriques système** : CPU, mémoire, disque (basique seulement)
- **Logs** : Event Viewer Windows, DNS (rétention 1 jour)
- **Alertes** : Désactivées pour économiser
- **Pas de métriques personnalisées** (limite Free Tier)

#### Backup
- **AWS Backup** : **Désactivé** (coûteux)
- **Stratégie** : Snapshots manuels occasionnels
- **Alternative** : Export de la configuration AD

## 🌐 Flux réseau

### Connexion VPN
1. **Client local** se connecte au PfSense via OpenVPN
2. **Tunnel chiffré** établi (AES-256, RSA-2048)
3. **Routage direct** vers le subnet privé (pas de NAT Gateway)
4. **Résolution DNS** via le Domain Controller
5. **Authentification** Active Directory

### Communication interne
1. **PfSense** route le trafic VPN vers le DC
2. **Domain Controller** répond aux requêtes DNS/LDAP
3. **Route53** gère la résolution interne
4. **CloudWatch** collecte les métriques basiques gratuites

## 🔄 Flux de déploiement (Séquence)

Le diagramme de séquence ci-dessus montre l'orchestration complète du déploiement automatisé.

## 📈 Limites et scalabilité

### ⚠️ Limitations Free Tier
- **Performance** : t2.micro limité (1 vCPU, 1GB RAM)
- **Stockage** : 25GB max (limite Free Tier)
- **Monitoring** : Basique seulement
- **Pas de haute disponibilité** : Single AZ
- **Utilisateurs** : Max 10-20 comptes (limitation performance)

### 🚀 Évolution possible
- **Upgrade instances** : t3.small/medium (sortie Free Tier)
- **Ajout de stockage** : Volumes supplémentaires (coût)
- **Multi-AZ** : Réplication Domain Controller (coût)
- **Monitoring avancé** : CloudWatch détaillé (coût)

## 💰 Comparaison des coûts

| Configuration | Instance DC | Instance VPN | Stockage | NAT Gateway | Total/mois |
|---------------|-------------|--------------|----------|-------------|------------|
| **Standard** | t3.medium (~25€) | t3.small (~15€) | 100GB (~10€) | NAT (~32€) | **~82€** |
| **Free Tier** | t2.micro (0€) | t2.micro (0€) | 25GB (0€) | Aucun (0€) | **~0.50€** |
| **Économie** | | | | | **98% moins cher** |

### 📊 Répartition des coûts Free Tier
- **Route53 zone privée** : 0,50€/mois
- **Tout le reste** : 0€/mois (Free Tier)
- **Après 12 mois** : ~15-20€/mois (instances t2.micro payantes)

## ⚡ Performance attendue

### 🎯 Environnement de lab/développement
- **Utilisateurs simultanés** : 5-10 maximum
- **Authentifications/min** : 50-100
- **Temps de réponse DNS** : <50ms
- **Établissement VPN** : 10-30 secondes
- **Promotion DC** : 20-30 minutes (Ansible)

### 📈 Métriques de surveillance
- **CPU Domain Controller** : <80% (alerte manuelle)
- **Mémoire disponible** : >200MB
- **Stockage libre** : >20%
- **Latence VPN** : <100ms

## 🔧 Optimisations appliquées

### ✅ Économies réalisées
- **NAT Gateway supprimé** : -32€/mois
- **Volumes multiples → volume unique** : Utilisation optimale Free Tier
- **Monitoring allégé** : Pas de métriques personnalisées
- **Backup désactivé** : Économie AWS Backup
- **Single AZ** : Pas de coûts multi-AZ
- **Instances t2.micro** : 750h Free Tier utilisées

### ⚙️ Configuration adaptée
- **AD Database** : Sur volume root (pas de volume dédié)
- **Logs** : Rétention 1 jour minimum
- **DNS uniquement** : DHCP désactivé pour alléger
- **VPN simple** : OpenVPN basique sans redondance

## 🎓 Cas d'usage idéaux

### ✅ Parfait pour :
- **Apprentissage** Active Directory et DevOps
- **Lab personnel** et expérimentation
- **Développement** d'applications avec AD
- **POC** et démonstrations
- **Formation** aux technologies Microsoft

### ❌ Non recommandé pour :
- **Production** d'entreprise
- **Plus de 20 utilisateurs**
- **Applications critiques**
- **Stockage de données importantes**
- **Haute disponibilité requise**

## 🔒 Sécurité

### ✅ Mesures de sécurité maintenues
- **Chiffrement EBS** : Données chiffrées
- **Security Groups** : Accès restrictif
- **VPN chiffré** : AES-256
- **Passwords complexes** : Politique AD
- **Audit basique** : Event Viewer

### ⚠️ Compromis sécurité/coût
- **Pas de WAF** (coûteux)
- **Monitoring basique** seulement
- **Pas de backup automatique**
- **Single AZ** (pas de redondance)

*Cette architecture est optimisée pour l'apprentissage et le développement dans le cadre du AWS Free Tier. Pour la production, consultez la version standard avec des instances plus puissantes et de la redondance.* 