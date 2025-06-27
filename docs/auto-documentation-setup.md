# Configuration du Workflow de Documentation Automatique

Ce guide explique comment configurer et utiliser le workflow GitHub Actions qui génère automatiquement de la documentation à partir du code source en utilisant un LLM et la publie sur Confluence.

## 📋 Prérequis

1. **Accès à un LLM** : 
   - Compte Anthropic (Claude) OU compte OpenAI (GPT)
   - Clé API correspondante

2. **Accès à Confluence** (optionnel) :
   - Instance Confluence Cloud ou Server
   - Compte utilisateur avec permissions d'écriture
   - Token API Confluence

## 🔧 Configuration des Secrets GitHub

Dans les paramètres de votre repository GitHub, ajoutez les secrets suivants :

### Secrets LLM (au moins un requis)
```
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
```

### Secrets Confluence (optionnels)
```
CONFLUENCE_BASE_URL=https://your-company.atlassian.net
CONFLUENCE_USERNAME=your.email@company.com
CONFLUENCE_API_TOKEN=your_confluence_api_token
CONFLUENCE_SPACE_KEY=YOUR_SPACE_KEY
```

## 🚀 Déclenchement du Workflow

Le workflow se déclenche automatiquement dans les cas suivants :

1. **Push sur les branches principales** (`main`, `develop`) avec des changements de code
2. **Pull Request** vers `main` avec des changements de code
3. **Déclenchement manuel** via l'interface GitHub Actions

### Types de fichiers surveillés :
- Python (`.py`)
- JavaScript/TypeScript (`.js`, `.ts`)
- Go (`.go`)
- Java (`.java`)
- Terraform (`.tf`)
- YAML (`.yaml`, `.yml`)
- Markdown dans `/docs`

## 📚 Fonctionnement du Workflow

### 1. Analyse du Code
- Scan automatique du repository
- Extraction des fichiers pertinents
- Filtrage des dossiers système (`.git`, `node_modules`, etc.)

### 2. Génération avec LLM
Le LLM analyse le code et génère une documentation structurée incluant :

- **Vue d'ensemble de l'architecture**
- **Analyse des composants**
- **Documentation des APIs**
- **Configuration et déploiement**
- **Guide de développement**
- **Exemples d'utilisation**

### 3. Publication
- Sauvegarde locale en tant qu'artifact GitHub
- Publication automatique sur Confluence (si configuré)
- Commentaire de prévisualisation sur les Pull Requests

## 🔄 Gestion des Versions

### Sur les Pull Requests
- Génération d'un aperçu de la documentation
- Commentaire automatique avec le contenu généré
- Aucune publication sur Confluence

### Sur les Merges
- Génération complète de la documentation
- Publication automatique sur Confluence
- Mise à jour de la page existante ou création d'une nouvelle

## 📖 Format de la Documentation Générée

La documentation est générée en format Markdown avec les sections suivantes :

```markdown
# Documentation du Projet

## Vue d'ensemble de l'Architecture
## Composants Principaux
## APIs et Endpoints
## Configuration
## Dépendances
## Guide d'Utilisation
## Guide de Développement
```

## 🛠️ Personnalisation

### Modification du Prompt LLM
Éditez la section `prompt` dans le script Python du workflow pour personnaliser l'analyse :

```python
prompt = f"""
Analyze this codebase and generate comprehensive documentation. Focus on:
# Ajoutez vos propres sections ici
"""
```

### Filtres de Fichiers
Modifiez la variable `extensions` dans le script pour inclure d'autres types de fichiers :

```python
extensions = {'.py', '.js', '.ts', '.go', '.java', '.tf', '.yaml', '.yml', '.md'}
```

### Configuration Confluence
Le workflow supporte la conversion automatique Markdown vers le format Confluence Storage Format.

## 🔍 Diagnostic et Dépannage

### Vérification des Logs
1. Allez dans l'onglet "Actions" de votre repository
2. Sélectionnez l'exécution du workflow
3. Consultez les logs de chaque étape

### Erreurs Communes

**"No LLM API key configured"**
- Vérifiez que `ANTHROPIC_API_KEY` ou `OPENAI_API_KEY` est configuré

**"Confluence configuration missing"**
- Vérifiez que tous les secrets Confluence sont configurés
- Le workflow continuera sans publication Confluence

**"Failed to publish to Confluence"**
- Vérifiez les permissions utilisateur
- Vérifiez que l'espace Confluence existe
- Vérifiez la validité du token API

## 📊 Monitoring

### Artifacts GitHub
- Chaque exécution sauvegarde la documentation générée
- Accessible pendant 30 jours
- Téléchargeable depuis l'interface Actions

### Rapports
Le workflow génère un résumé automatique dans l'onglet Summary de chaque exécution.

## 🔄 Mise à Jour du Workflow

Pour mettre à jour le workflow :

1. Modifiez le fichier `.github/workflows/doc.yaml`
2. Committez les changements
3. Le workflow sera automatiquement mis à jour

## 🎯 Bonnes Pratiques

1. **Documentation du Code** : Ajoutez des commentaires pertinents dans votre code pour améliorer l'analyse LLM
2. **Structure du Repository** : Organisez votre code de manière logique
3. **Fichiers README** : Maintenez des README à jour dans les sous-dossiers
4. **Configuration** : Documentez les variables d'environnement et la configuration

## 🔒 Sécurité

- Les clés API sont stockées comme secrets GitHub (chiffrés)
- Aucune donnée sensible n'est exposée dans les logs
- Les artifacts de documentation ne contiennent pas de secrets

## 🆘 Support

Pour tout problème :
1. Consultez les logs du workflow
2. Vérifiez la configuration des secrets
3. Testez avec un déclenchement manuel
4. Consultez la documentation des APIs utilisées

---

*Ce workflow utilise les dernières versions des actions GitHub et des clients LLM pour garantir la sécurité et les performances.* 