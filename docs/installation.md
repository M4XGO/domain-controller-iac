# Installation Simple - Projet École

> Guide d'installation rapide pour déployer un contrôleur de domaine Active Directory sur AWS

## 🎯 Prérequis

### 1. Compte AWS
- Créer un compte AWS (Free Tier)
- Avoir une carte bancaire (pas de débit pour Free Tier)

### 2. Outils nécessaires

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y curl unzip

# macOS (avec Homebrew)
brew install terraform awscli

# Windows (avec Chocolatey)
choco install terraform awscli
```

#### Terraform
```bash
# Linux/macOS
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Vérifier
terraform version
```

#### AWS CLI
```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Vérifier
aws --version
```

## 🔑 Configuration AWS

### 1. Créer un utilisateur IAM
1. Aller dans AWS Console → IAM
2. Créer un utilisateur avec accès programmatique
3. Attacher la politique `AdministratorAccess`
4. Noter l'Access Key ID et Secret Access Key

### 2. Configurer AWS CLI
```bash
aws configure
# AWS Access Key ID: [votre-access-key]
# AWS Secret Access Key: [votre-secret-key]  
# Default region name: us-east-1
# Default output format: json
```

### 3. Tester la connexion
```bash
aws sts get-caller-identity
```

## 🚀 Déploiement

### 1. Cloner le projet
```bash
git clone <votre-repo-url>
cd domain-controller-iac
```

### 2. Configurer les variables
```bash
# Éditer le fichier de configuration
nano .config/variables/terraform.tfvars

# Modifier obligatoirement :
admin_password     = "VotreMotDePasseComplexe123!"
safe_mode_password = "VotreSafeModePassword123!"
```

### 3. Initialiser et déployer
```bash
# Initialiser Terraform
make init

# Voir ce qui va être créé
make plan

# Déployer (prend ~5-10 minutes)
make deploy
```

### 4. Récupérer les informations de connexion
```bash
# Afficher les outputs avec l'IP publique
make status
```

## 🔗 Connexion RDP

### 1. Récupérer l'IP publique
L'IP publique est affichée dans les outputs de `make deploy` ou `make status`.

### 2. Se connecter en RDP

#### Windows
1. Ouvrir "Connexion Bureau à distance"
2. Entrer l'IP publique
3. Utilisateur : `SCHOOL\Administrator`
4. Mot de passe : celui défini dans `terraform.tfvars`

#### macOS
1. Installer Microsoft Remote Desktop
2. Ajouter une nouvelle connexion
3. PC Name : IP publique
4. User Account : `SCHOOL\Administrator`

#### Linux
```bash
# Installer rdesktop ou freerdp
sudo apt install freerdp2-x11

# Se connecter
xfreerdp /v:[IP-PUBLIQUE] /u:SCHOOL\\Administrator /p:[MOT-DE-PASSE]
```

## ✅ Vérification

Une fois connecté en RDP :

1. **Vérifier Active Directory** :
   ```powershell
   Get-ADDomain
   ```

2. **Vérifier DNS** :
   ```powershell
   nslookup school.local
   ```

3. **Créer un utilisateur test** :
   ```powershell
   New-ADUser -Name "Etudiant1" -UserPrincipalName "etudiant1@school.local" -AccountPassword (ConvertTo-SecureString "MotDePasse123!" -AsPlainText -Force) -Enabled $true
   ```

## 🧹 Nettoyage

```bash
# Détruire toute l'infrastructure
make destroy

# Nettoyer les fichiers temporaires
make clean
```

## ⚠️ Troubleshooting

### Erreur AWS
```bash
# Vérifier les credentials
aws sts get-caller-identity

# Vérifier les permissions
aws iam get-user
```

### Erreur Terraform
```bash
# Nettoyer et réinitialiser
make clean
make init
```

### Instance inaccessible
- Vérifier que le Security Group autorise RDP (port 3389)
- Attendre 5-10 minutes après le déploiement
- Vérifier les logs CloudWatch

### Mot de passe rejeté
- Le mot de passe doit respecter la politique Windows :
  - Au moins 8 caractères
  - Majuscules, minuscules, chiffres et caractères spéciaux

## 💡 Conseils

1. **Sauvegardez vos variables** : Le fichier `terraform.tfvars` contient vos mots de passe
2. **Surveillez les coûts** : Même en Free Tier, surveillez votre usage AWS
3. **Testez rapidement** : Détruisez l'infrastructure après vos tests pour éviter les frais
4. **Documentez vos tests** : Notez ce que vous apprenez sur Active Directory

---

**Temps total d'installation** : ~30 minutes  
**Temps de déploiement** : ~10 minutes  
**Coût** : 0€ avec AWS Free Tier 