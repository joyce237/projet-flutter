# Tests HomePharma - Documentation

Ce dossier contient les tests unitaires pour l'application HomePharma. Les tests vérifient le bon fonctionnement des modèles de données de l'application.

## 📁 Structure des Tests

```
test/
├── models/
│   ├── cart_item_test.dart      # Tests du modèle CartItem
│   └── user_model_test.dart     # Tests du modèle UserModel
└── README.md                    # Cette documentation
```

## 🧪 Tests des Modèles

### 1. Tests du Modèle UserModel (`user_model_test.dart`)

Le modèle `UserModel` représente un utilisateur de l'application (client ou pharmacien). Les tests vérifient :

#### **Test 1 : Création d'utilisateur depuis une Map**
- **Objectif** : Vérifier que l'on peut créer un objet `UserModel` à partir de données JSON/Map
- **Ce qui est testé** :
  - Conversion correcte des données depuis une Map
  - Attribution correcte de l'ID utilisateur
  - Propriétés `isUser` et `isPharmacist` selon le rôle
  - Gestion des dates (création, dernière connexion)

#### **Test 2 : Conversion d'utilisateur vers une Map**
- **Objectif** : Vérifier que l'on peut sauvegarder un `UserModel` en format JSON/Map
- **Ce qui est testé** :
  - Sérialisation correcte de tous les champs
  - Inclusion des champs optionnels (pharmacyId pour les pharmaciens)
  - Format des dates dans la Map de sortie

#### **Test 3 : Génération des initiales**
- **Objectif** : Vérifier la logique de création des initiales pour l'avatar utilisateur
- **Scénarios testés** :
  - Nom simple → "John" devient "J"
  - Nom complet → "John Doe" devient "JD"
  - Nom vide → Utilise la première lettre de l'email

#### **Test 4 : Identification du rôle pharmacien**
- **Objectif** : Vérifier la logique de distinction entre utilisateurs et pharmaciens
- **Ce qui est testé** :
  - Propriété `isPharmacist` = true pour rôle "pharmacist"
  - Propriété `isUser` = false pour les pharmaciens
  - Présence du `pharmacyId` pour les pharmaciens

#### **Test 5 : Copie avec nouvelles valeurs**
- **Objectif** : Vérifier la méthode `copyWith` pour mettre à jour un utilisateur
- **Ce qui est testé** :
  - Conservation des valeurs non modifiées
  - Mise à jour sélective des champs
  - Intégrité de l'objet après modification

#### **Test 6 : Nom d'affichage**
- **Objectif** : Vérifier la logique du nom affiché dans l'interface
- **Scénarios testés** :
  - Avec nom : affiche le nom complet
  - Sans nom : affiche l'adresse email

### 2. Tests du Modèle CartItem (`cart_item_test.dart`)

Le modèle `CartItem` représente un médicament dans le panier d'achat. Les tests vérifient :

#### **Test 1 : Sérialisation/Désérialisation complète**
- **Objectif** : Vérifier que l'on peut sauvegarder et restaurer un `CartItem`
- **Ce qui est testé** :
  - Conversion Map → CartItem → Map sans perte de données
  - Calcul automatique du prix total (quantité × prix unitaire)
  - Formatage de la distance ("1.2 km")
  - Vérification de disponibilité (stock vs quantité)

#### **Test 2 : Modification avec copyWith**
- **Objectif** : Vérifier la mise à jour sélective des propriétés
- **Ce qui est testé** :
  - Modification de la quantité et du prix
  - Recalcul automatique du prix total
  - Conservation des autres propriétés inchangées

#### **Test 3 : Logique de disponibilité**
- **Objectif** : Vérifier les règles de disponibilité des médicaments
- **Scénarios testés** :
  - **Stock insuffisant** : quantité (4) > stock (3) → `isAvailable` = false
  - **Rupture de stock** : stock = 0 → `isOutOfStock` = true
  - **Disponible** : quantité ≤ stock → `isAvailable` = true

## 🚀 Exécution des Tests

### Commandes de base
```bash
# Exécuter tous les tests
flutter test

# Exécuter uniquement les tests de modèles
flutter test test/models/

# Exécuter un fichier de test spécifique
flutter test test/models/user_model_test.dart
```

### Résultats attendus
Tous les tests doivent passer avec succès :
- ✅ **6 tests** pour UserModel
- ✅ **3 tests** pour CartItem
- ✅ **Total : 9 tests**

## 📊 Couverture des Tests

### UserModel - Fonctionnalités testées
- ✅ Sérialisation/Désérialisation JSON
- ✅ Gestion des rôles (user/pharmacist)
- ✅ Génération d'initiales
- ✅ Nom d'affichage
- ✅ Copie immutable avec modifications

### CartItem - Fonctionnalités testées
- ✅ Sérialisation/Désérialisation JSON
- ✅ Calculs automatiques (prix total)
- ✅ Formatage des données (distance)
- ✅ Logique métier (disponibilité, stock)
- ✅ Modifications immutables

## 🔧 Maintenance des Tests

### Quand ajouter de nouveaux tests
- Lors de l'ajout de nouvelles propriétés aux modèles
- Lors de modifications de la logique métier
- En cas de bugs découverts en production

### Bonnes pratiques
- Chaque test doit être indépendant
- Utiliser des données de test réalistes
- Tester les cas limites (valeurs nulles, vides)
- Maintenir une couverture de test élevée

## 📝 Notes Techniques

### Frameworks utilisés
- **flutter_test** : Framework de test Flutter/Dart
- **Arrange-Act-Assert** : Pattern utilisé dans les tests

### Types de tests
- **Tests unitaires** : Testent une fonction/méthode isolée
- **Tests de modèles** : Vérifient la logique des classes de données

Ces tests garantissent la fiabilité des modèles de données de HomePharma et facilitent la maintenance du code.
