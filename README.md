# Domain Controller Infrastructure-as-Code

> **Projet d'école** - Déploiement automatique d'un contrôleur de domaine Active Directory sur AWS  
> **100% AWS Free Tier** - Coût : 0€/mois ⭐

## 🎯 Objectif

Créer automatiquement un contrôleur de domaine Windows Server 2022 sur AWS pour apprendre Active Directory dans un environnement scolaire.

## 📋 Architecture Simple

```
AWS VPC (10.0.0.0/16)
└── Public Subnet (10.0.1.0/24)
    └── Domain Controller (t2.micro)
        ├── Windows Server 2022
        ├── Active Directory Domain Services
        ├── DNS Server
        └── Domain: school.local
```

## 💰 Coûts

- **Instance EC2 t2.micro** : GRATUIT (750h/mois Free Tier)
- **Stockage 25GB GP2** : GRATUIT (30GB Free Tier)
- **VPC + Réseau** : GRATUIT
- **Total** : **0€/mois** 🎉

## 🚀 Utilisation Rapide

```bash
# 1. Cloner le projet
git clone <votre-repo>
cd domain-controller-iac

# 2. Configurer AWS CLI
aws configure

# 3. Modifier les mots de passe
nano .config/variables/terraform.tfvars

# 4. Déployer
make init
make plan
make deploy

# 5. Se connecter en RDP
# IP affichée dans les outputs
```

## 📦 Structure Simplifiée

```
/
├── .cloud/terraform/          # Configuration Terraform
├── .infra/modules/           # Module EC2 Windows
├── .config/variables/        # Variables
├── Makefile                  # Commandes automatisées
└── docs/                     # Documentation
```

## 🛠️ Prérequis

- [Terraform](https://terraform.io) >= 1.6
- [AWS CLI](https://aws.amazon.com/cli/) configuré
- Compte AWS avec Free Tier disponible

## ⚙️ Configuration

Éditer `.config/variables/terraform.tfvars` :

```hcl
# Domain Configuration
domain_name         = "school.local"
domain_netbios_name = "SCHOOL"
admin_password      = "VotreMotDePasse!"  # CHANGEZ CECI!
safe_mode_password  = "VotreSafeMode!"    # CHANGEZ CECI!
```

## 🔧 Commandes Disponibles

```bash
make help      # Afficher l'aide
make init      # Initialiser le projet
make plan      # Voir les changements
make deploy    # Déployer l'infrastructure
make status    # Statut de l'infrastructure
make destroy   # Détruire l'infrastructure
make clean     # Nettoyer les fichiers temporaires
```

## 🔗 Connexion

Une fois déployé :

1. **RDP** : Connectez-vous avec l'IP publique affichée
2. **Utilisateur** : `SCHOOL\Administrator`
3. **Mot de passe** : Celui défini dans `terraform.tfvars`
4. **Port** : 3389

## 📚 Apprentissage

Après déploiement, vous pouvez :

- Créer des utilisateurs et groupes AD
- Configurer des GPO
- Joindre des machines virtuelles au domaine
- Apprendre la gestion DNS
- Explorer les services Active Directory

## ⚠️ Sécurité (École uniquement)

> **ATTENTION** : Cette configuration ouvre RDP sur Internet (0.0.0.0/0)  
> Acceptable uniquement pour un projet d'école temporaire !

Pour la production :
- Restreindre l'accès RDP à votre IP
- Utiliser un VPN
- Implémenter l'authentification multi-facteur

## 🧹 Nettoyage

```bash
make destroy  # Supprime TOUTE l'infrastructure
```

## 📖 Documentation

- [Installation détaillée](docs/installation.md)
- [Architecture technique](docs/architecture.md)
- [Guide Free Tier](docs/free-tier-guide.md)

## 🆘 Support

En cas de problème :

1. Vérifier `make status`
2. Consulter les logs AWS CloudWatch
3. Valider la configuration avec `make validate`

---

**Projet éducatif** - Optimisé pour l'apprentissage et le AWS Free Tier 🎓 