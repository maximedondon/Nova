
![Logo](https://i.ibb.co/jPXN57hK/256x256.png)


# Nova - Gestionnaire de Projets pour Motion Design

**Nova** est une application macOS native pour gérer vos projets de motion design, animation et production vidéo. Conçue pour s'intégrer parfaitement dans votre workflow After Effects, Nova vous permet de suivre l'état de vos projets, organiser vos fichiers et accéder rapidement à vos ressources.

![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-FA7343?style=flat&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0D96F6?style=flat&logo=swift&logoColor=white)

## ✨ Fonctionnalités

### 🎨 Gestion de Projets
- **Création flexible** : Choisissez de créer ou non l'arborescence de dossiers
- **Catégorisation** : Organisez vos projets par catégories personnalisables
- **Tags** : 2D, 3D, Freelance pour filtrer rapidement
- **Statuts** : Suivi de l'avancement (Pas commencé, En cours, Stand By, Finitions, Terminé)
- **Notes intégrées** : Zone de notes avec sauvegarde automatique

### 📁 Structure de Dossiers
Arborescence standardisée créée automatiquement (optionnel) :
```
Projet/
├── 00 IN/          # Fichiers sources
├── 01 ASSETS/      # Ressources visuelles
├── 02 AI/          # Fichiers Illustrator
├── 03 3D/          # Fichiers 3D
├── 04 AUDIO/       # Sons et musiques
├── 05 AEP/         # Projets After Effects
├── 06 CAVALRY/     # Projets Cavalry
├── 07 SORTIES/     # Rendus finaux
└── 08 LIVRABLE/    # Fichiers à livrer
```

### 🔄 Import/Export
- **Découverte automatique** : Scannez votre dossier pour importer des projets existants
- **Export JSON** : Sauvegardez tous vos projets pour backup ou transfert
- **Import JSON** : Fusionnez des projets depuis un fichier externe
- **Persistance centralisée** : Vos projets restent accessibles même si le dossier est déconnecté

### 🚀 Accès Rapide
- Ouvrir le dernier fichier .aep automatiquement
- Accès direct aux dossiers Assets et Sorties
- Ouverture du dossier projet dans le Finder
- Intégration After Effects

### 🎯 Interface Intuitive
- **Three-pane layout** : Catégories, Liste de projets, Détails
- **Menus contextuels** : Click droit pour renommer, supprimer
- **Recherche** : Filtrage instantané des projets
- **Drag & Drop** : Réorganisez vos projets par catégories

## 📦 Installation

### Prérequis
- macOS 14.0 ou supérieur
- Xcode 16.4+ (pour la compilation)

### Compilation
```bash
git clone https://github.com/votre-username/Nova.git
cd Nova
xcodebuild -project Nova.xcodeproj -scheme Nova -configuration Release build
```

L'application compilée sera dans :
```
~/Library/Developer/Xcode/DerivedData/Nova-*/Build/Products/Release/Nova.app
```

## 🚀 Démarrage rapide

1. **Premier lancement** : Sélectionnez votre dossier de projets
2. **Créer un projet** : `⌘N` ou cliquez sur `+`
3. **Organiser** : Créez des catégories et assignez vos projets
4. **Travailler** : Accédez rapidement à vos fichiers AEP et ressources

## 💡 Cas d'usage

### Importer des projets existants
Si vous avez déjà des dossiers de projets avec la bonne structure :
1. Préférences > Général > Gestion des données
2. Cliquez sur "Scanner"
3. Nova détectera et importera automatiquement vos projets

### Créer un projet simple (sans dossiers)
Pour un projet de suivi uniquement :
1. `⌘N` pour nouveau projet
2. Sélectionnez "Sans structure de dossiers"
3. Utilisez les notes et statuts pour le suivi

### Créer un projet complet
Pour un projet avec fichiers organisés :
1. `⌘N` pour nouveau projet
2. Sélectionnez "Créer la structure"
3. L'arborescence complète est créée automatiquement

### Sauvegarder vos projets
Pour backup ou migration :
1. Préférences > Général > Gestion des données
2. Cliquez sur "Exporter"
3. Votre fichier JSON contient tous vos projets

## 🛠️ Architecture Technique

### Technologies
- **Swift 6.0** : Langage moderne et sûr
- **SwiftUI** : Interface déclarative native
- **Codable** : Sérialisation JSON
- **Security-scoped bookmarks** : Accès sécurisé aux fichiers
- **Application Support** : Stockage persistant des données

### Structure du projet
```
Nova/
├── Models/              # Modèles de données
│   ├── Project.swift   # Modèle de projet
│   └── AppSettings.swift
├── Store/              # Gestion d'état
│   ├── ProjectStore.swift
│   └── PersistenceManager.swift
├── Views/              # Interface utilisateur
│   ├── ContentView.swift
│   ├── ProjectDetailView.swift
│   ├── PreferencesView.swift
│   └── OnboardingView.swift
├── Components/         # Composants réutilisables
├── Utils/             # Utilitaires
│   └── FileSystemHelper.swift
└── Settings/          # Configuration
    └── SettingsManager.swift
```

### Stockage des données
- **Projets** : `~/Library/Application Support/Nova/projects.json`
- **Catégories** : UserDefaults
- **Dossier de projets** : Security-scoped bookmark

## 🔐 Sécurité et Permissions

Nova utilise les **security-scoped bookmarks** de macOS pour accéder aux fichiers :
- Permission demandée uniquement au premier lancement
- Accès sécurisé aux dossiers de projets
- Aucune donnée n'est envoyée en externe
- Toutes les données restent sur votre Mac

## 📝 Changelog

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique détaillé des modifications.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Reporter des bugs
- Proposer de nouvelles fonctionnalités
- Soumettre des pull requests

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 👤 Auteur

**Maxime Dondon**
- Email: [votre-email]
- LinkedIn: [votre-linkedin]

## 🙏 Remerciements

Merci à tous les motion designers et animateurs qui ont inspiré ce projet !

---

**Nova** - Gérez vos projets de motion design avec élégance 🚀


What if managing motion design projects were simpler ?



## Features

- Automatic project folders creation
- Open the latest after effects file by date
- Status managing 
- Tags


## Roadmap

- Crossplatform
- 3D files support
- Onboarding


## Feedback

If you have any feedback, please reach out to us at feedback@maximedondon.fr


## Authors

- [@maximedondon](https://www.github.com/maximedondon)

