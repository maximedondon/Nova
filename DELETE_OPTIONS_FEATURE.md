# 🗑️ Suppression Intelligente de Projets

## ✨ Fonctionnalité Implémentée

Vous pouvez maintenant choisir entre deux modes de suppression lorsque vous supprimez un projet dans Nova.

## 🎯 Nouveau Dialog de Suppression

Lorsque vous supprimez un projet (click droit > Supprimer), un dialog de confirmation s'affiche avec **3 options** :

### Option 1️⃣ : Supprimer de l'app uniquement
- **Action** : Retire le projet de la liste Nova
- **Dossier** : ✅ Conservé sur le disque
- **Fichiers** : ✅ Tous les fichiers restent intacts
- **Cas d'usage** : Nettoyer la liste sans perdre vos fichiers

### Option 2️⃣ : Supprimer de l'app et du disque
- **Action** : Retire le projet de Nova ET supprime le dossier
- **Dossier** : ❌ Supprimé définitivement
- **Fichiers** : ❌ Tous les fichiers sont supprimés
- **Cas d'usage** : Projet terminé dont vous n'avez plus besoin

### Option 3️⃣ : Annuler
- Ferme le dialog sans rien faire

## 🔧 Implémentation Technique

### ContentView.swift
```swift
.confirmationDialog("Supprimer le projet", ...) {
    Button("Supprimer de l'app uniquement", role: .destructive) {
        store.deleteProject(withId: id, deleteFolderOnDisk: false)
    }
    
    Button("Supprimer de l'app et du disque", role: .destructive) {
        store.deleteProject(withId: id, deleteFolderOnDisk: true)
    }
    
    Button("Annuler", role: .cancel) { }
}
```

### ProjectStore.swift
```swift
func removeProject(_ project: Project, deleteFolderOnDisk: Bool = true) {
    if deleteFolderOnDisk, let folder = project.rootFolder {
        // Supprimer le dossier physique
        try FileManager.default.removeItem(at: folder)
    }
    // Retirer de la liste en mémoire
    // ...
}
```

## 💡 Cas d'Usage

### Scénario 1 : Projet terminé et archivé
Vous avez terminé un projet et l'avez déjà livré au client. Vous voulez garder une archive locale mais nettoyer Nova.
- ✅ **Utilisez** : "Supprimer de l'app uniquement"
- 📁 Les fichiers restent sur votre disque pour archive

### Scénario 2 : Test ou projet annulé
Vous avez créé un projet de test ou un projet client annulé dont vous n'avez plus besoin.
- ✅ **Utilisez** : "Supprimer de l'app et du disque"
- 🗑️ Tout est supprimé pour libérer de l'espace

### Scénario 3 : Réimporter plus tard
Vous voulez temporairement retirer un projet de Nova mais pourriez le réimporter plus tard.
- ✅ **Utilisez** : "Supprimer de l'app uniquement"
- 🔄 Utilisez "Scanner" dans les Préférences pour le réimporter

## 🎨 Interface Utilisateur

Le dialog utilise `.confirmationDialog` pour un style natif macOS :

```
┌─────────────────────────────────────────┐
│        Supprimer le projet              │
├─────────────────────────────────────────┤
│  Voulez-vous supprimer uniquement le   │
│  projet de Nova ou également supprimer │
│  tous les fichiers du disque ?         │
├─────────────────────────────────────────┤
│  🔴 Supprimer de l'app uniquement       │
│  🔴 Supprimer de l'app et du disque     │
│  ⚪ Annuler                              │
└─────────────────────────────────────────┘
```

## 🔐 Sécurité

- ✅ Confirmation obligatoire avant suppression
- ✅ Messages clairs sur les conséquences
- ✅ Bouton "Annuler" toujours disponible
- ✅ Rôle `.destructive` pour les actions dangereuses
- ✅ Logs dans la console pour traçabilité

## 📊 Logs Console

Lors de la suppression, des logs sont générés :

**Suppression app uniquement** :
```
ℹ️ Projet supprimé de l'app uniquement (dossier conservé sur le disque)
```

**Suppression complète** :
```
✅ Dossier supprimé du disque: /Users/max/Projets/MonProjet
```

**Erreur** :
```
❌ Erreur suppression dossier projet: [details]
```

## ⚡ Avantages

1. **Flexibilité** : Choisissez selon vos besoins
2. **Sécurité** : Évite les suppressions accidentelles de fichiers
3. **Clarté** : Messages explicites sur les conséquences
4. **Natif** : Interface macOS standard
5. **Réversible** : L'option "app uniquement" permet de réimporter

## 🔄 Workflow Typique

### Nettoyer la liste sans perdre les fichiers
1. Click droit sur le projet > Supprimer
2. Choisir "Supprimer de l'app uniquement"
3. Le projet disparaît de Nova
4. Les fichiers restent dans `/Projets/MonProjet/`
5. Plus tard : Préférences > Scanner pour le réimporter

### Suppression définitive
1. Click droit sur le projet > Supprimer
2. Choisir "Supprimer de l'app et du disque"
3. ⚠️ Tout est supprimé définitivement
4. Impossible de récupérer (sauf Time Machine)

## 📝 Notes Importantes

- La suppression "du disque" est **définitive** et irréversible
- Assurez-vous d'avoir des backups avant de supprimer des fichiers
- La suppression "app uniquement" ne touche pas au dossier
- Vous pouvez réimporter des projets supprimés "app uniquement" via Scanner

---

**Build Status** : ✅ BUILD SUCCEEDED

**Fonctionnalité implémentée avec succès !** 🎉
