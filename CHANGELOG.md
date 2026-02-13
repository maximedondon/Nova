# Nova - Changements apportés

## Résumé des modifications

Cette mise à jour transforme complètement le système de stockage et de gestion des projets dans Nova, en le rendant plus robuste, flexible et intuitif.

## 🎯 Problèmes résolus

### 1. **Persistance centralisée** ✅
- **Avant** : Les projets étaient stockés dans des fichiers `project.json` individuels dans chaque dossier
- **Maintenant** : Tous les projets sont sauvegardés dans un fichier JSON unique dans `~/Library/Application Support/Nova/projects.json`
- **Avantage** : Les projets restent accessibles même si le dossier de projets est déconnecté ou déplacé

### 2. **Structure de dossiers optionnelle** ✅
- **Avant** : L'arborescence de dossiers était créée automatiquement pour chaque projet
- **Maintenant** : Lors de la création d'un projet, vous choisissez si vous voulez créer la structure ou non
- **Avantage** : Parfait pour les projets de suivi simple sans avoir besoin de toute l'arborescence

### 3. **Import/Export de projets** ✅
- Exportez tous vos projets dans un fichier JSON pour sauvegarde ou transfert
- Importez des projets depuis un fichier JSON (fusion avec les projets existants)
- Accès via Préférences > Général > Gestion des données

### 4. **Découverte de projets existants** ✅
- Scannez votre dossier de projets pour découvrir et importer automatiquement des projets existants
- Détecte les dossiers avec la bonne structure (00 IN, 01 ASSETS, 05 AEP, 07 SORTIES)
- Parfait pour importer des projets créés manuellement ou provenant d'une autre source
- Accès via Préférences > Général > Gestion des données > Scanner

### 5. **Interface utilisateur améliorée** ✅
- **Menus contextuels natifs** : Click droit > Renommer sur les projets (liste et détail)
- **Bouton de création d'arborescence** : Déplacé dans le header à côté du bouton dossier
- **Interface épurée** : Suppression des boutons Edit/Save, remplacés par des actions contextuelles
- **Bouton dossier intelligent** : Masqué automatiquement si pas d'arborescence créée

### 6. **Statuts personnalisables** ✅ **NOUVEAU**
- **Créez vos propres statuts** : Ajoutez, renommez, supprimez des statuts selon vos besoins
- **Couleurs personnalisées** : Choisissez la couleur de chaque statut
- **Réorganisation** : Glissez-déposez pour réordonner les statuts
- **Statuts système** : 5 statuts par défaut non supprimables (Pas commencé, En cours, Stand By, Finitions, Terminé)
- **Accès rapide** : Bouton ⚙️ dans la section "Suivi de projet"

### 7. **Raccourcis clavier** ✅ **NOUVEAU**
- **Enter** : Sauvegarder lors du renommage d'un projet
- **Esc** : Annuler le renommage
- **Plus besoin de cliquer** sur les boutons ✓ et ✕

## 📝 Changements techniques détaillés

### Nouveau modèle de données (Project.swift)
```swift
- rootFolder: URL? (supprimé)
+ rootFolderPath: String? (nouveau)
+ createdAt: Date (nouveau)
+ updatedAt: Date (nouveau)
+ hasFolderStructure: Bool (nouveau)
+ statusID: UUID (remplace status: ProjectStatus)
+ rootFolder: URL? (computed property)
```

### Nouveau système de statuts (Project.swift)
```swift
struct ProjectStatus {
    - enum (supprimé)
    + struct personnalisable
    + id: UUID
    + name: String
    + colorHex: String (stockage hex pour sérialisation)
    + order: Int (ordre d'affichage)
    + isSystem: Bool (protège les statuts système)
}
```

### Extension Color (Project.swift)
```swift
+ init?(hex: String) (conversion hex -> Color)
+ toHex() -> String? (conversion Color -> hex)
```

### Nouveau système de persistance (PersistenceManager.swift)
- Gère la sauvegarde/chargement automatique des projets
- Stockage dans `~/Library/Application Support/Nova/`
- Format JSON avec encodage ISO8601 pour les dates
- Méthodes d'import/export pour fichiers externes

### ProjectStore mis à jour
- `addProject(createFolderStructure: Bool)` : Option pour créer ou non la structure
- `saveProjects()` : Sauvegarde automatique après chaque modification
- `loadProjects()` : Chargement au démarrage
- `syncWithProjectsFolder()` : Synchronisation optionnelle avec le dossier
- `exportProjects(to:)` : Export vers fichier JSON
- `importProjects(from:merge:)` : Import depuis fichier JSON
- `createFolderStructure(for:)` : Créer la structure pour un projet existant
- `discoverAndImportExistingProjects()` : Scanner et importer des dossiers existants
- `hasValidProjectStructure(at:)` : Vérifier si un dossier a la structure attendue
- `loadStatuses()` : **NOUVEAU** Charger les statuts depuis UserDefaults
- `saveStatuses()` : **NOUVEAU** Sauvegarder les statuts
- `addStatus(name:colorHex:)` : **NOUVEAU** Créer un statut personnalisé
- `removeStatus(_:)` : **NOUVEAU** Supprimer un statut (sauf système)
- `renameStatus(_:to:)` : **NOUVEAU** Renommer un statut
- `changeStatusColor(_:to:)` : **NOUVEAU** Changer la couleur d'un statut
- `moveStatuses(from:to:)` : **NOUVEAU** Réorganiser les statuts
- `status(with:)` : **NOUVEAU** Récupérer un statut par ID

### Interface utilisateur

#### Création de projet
- Dialog de confirmation avec 3 options :
  - "Créer la structure" : Crée l'arborescence complète
  - "Sans structure de dossiers" : Projet simple sans dossiers
  - "Annuler"

#### ProjectDetailView
- Bouton "Créer la structure de dossiers" si elle n'existe pas encore (dans le header)
- Sauvegarde automatique des notes (toutes les 0.8s)
- Sauvegarde via le store centralisé
- Bouton ⚙️ pour gérer les statuts
- **Raccourcis clavier** : Enter pour sauvegarder, Esc pour annuler
- **Menu contextuel** : Click droit sur le titre pour renommer

#### StatusManagerView **NOUVEAU**
- Interface modale pour gérer les statuts
- Liste réorganisable par glisser-déposer
- Édition inline des noms de statuts
- ColorPicker pour changer les couleurs
- Indicateur "Système" pour les statuts non supprimables
- Menu contextuel : Renommer / Supprimer
- Bouton "Nouveau statut" avec couleur aléatoire

#### PreferencesView
- Nouvelle section "Gestion des données"
  - Bouton "Scanner" : Découvrir des projets existants
  - Bouton "Exporter" : Sauvegarde tous les projets
  - Bouton "Importer" : Importe des projets (fusion)
- Section "À propos"
  - Bouton "Ouvrir" : Accès au dossier de données de l'app

## 🔄 Migration automatique

Les projets existants seront automatiquement chargés au prochain démarrage. Si vous aviez des projets dans des dossiers :
1. Ils seront chargés dans le nouveau système
2. Les chemins vers les dossiers seront conservés
3. Aucune donnée ne sera perdue

## 💡 Utilisation

### Créer un nouveau projet
1. Cliquez sur `+` ou `⌘N`
2. Choisissez si vous voulez créer la structure de dossiers
3. Le projet est créé et sauvegardé automatiquement

### Renommer un projet
**Méthode 1 - Dans la liste** :
1. Click droit sur le projet dans la liste
2. Sélectionnez "Renommer"
3. Modifiez le titre et validez avec Entrée

**Méthode 2 - Dans la vue détaillée** :
1. Click droit sur le titre du projet
2. Sélectionnez "Renommer"
3. Modifiez le titre et validez avec le bouton ✓

### Créer la structure pour un projet existant
1. Sélectionnez le projet
2. Cliquez sur l'icône 📁+ dans le header (à droite du titre)
3. La structure complète sera créée dans le dossier de projets

### Découvrir des projets existants
1. Ouvrez les Préférences (`⌘,`)
2. Section "Gestion des données"
3. Cliquez sur "Scanner"
4. Les projets trouvés seront automatiquement importés

### Exporter vos projets
1. Ouvrez les Préférences (`⌘,`)
2. Section "Gestion des données"
3. Cliquez sur "Exporter"
4. Choisissez l'emplacement de sauvegarde

### Importer des projets
1. Ouvrez les Préférences (`⌘,`)
2. Section "Gestion des données"
3. Cliquez sur "Importer"
4. Sélectionnez le fichier JSON à importer
5. Les projets seront fusionnés avec vos projets existants

### Gérer les statuts personnalisés
1. Ouvrez un projet
2. Dans la section "Suivi de projet", cliquez sur l'icône ⚙️
3. **Créer** : Cliquez sur "+ Nouveau statut"
4. **Renommer** : Double-cliquez sur un statut ou click droit > Renommer
5. **Changer la couleur** : Cliquez sur le cercle de couleur
6. **Réorganiser** : Glissez-déposez les statuts
7. **Supprimer** : Click droit > Supprimer (sauf statuts système)

### Utiliser les raccourcis clavier
Lors du renommage d'un projet :
- **Enter** : Sauvegarder les modifications
- **Esc** : Annuler et revenir au nom précédent

## 🗂️ Structure de dossiers (quand créée)

```
Projet/
├── 00 IN/
├── 01 ASSETS/
├── 02 AI/
├── 03 3D/
├── 04 AUDIO/
├── 05 AEP/
├── 06 CAVALRY/
├── 07 SORTIES/
└── 08 LIVRABLE/
```

## ⚙️ Améliorations du code

- Suppression des méthodes obsolètes (`fromFolder`, `loadFullFromDisk`, `saveToFolder`)
- Sauvegarde automatique après chaque modification
- Meilleure séparation des responsabilités
- Gestion d'erreurs améliorée
- Code plus maintenable et testable

## 🔐 Sécurité

- Les accès aux dossiers utilisent toujours les security-scoped bookmarks
- Les données sont sauvegardées dans le dossier Application Support de l'utilisateur
- Format JSON lisible et portable

## 📅 Métadonnées

Chaque projet stocke maintenant :
- Date de création (`createdAt`)
- Date de dernière modification (`updatedAt`)
- Indicateur de structure de dossiers (`hasFolderStructure`)

---

**Développé par Maxime Dondon**
**Version : 1.0**
