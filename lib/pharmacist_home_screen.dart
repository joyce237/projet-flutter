import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacistHomeScreen extends StatefulWidget {
  final String pharmacyId;
  const PharmacistHomeScreen({super.key, required this.pharmacyId});

  @override
  State<PharmacistHomeScreen> createState() => _PharmacistHomeScreenState();
}

class _PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _pharmacyId;
  String _pharmacyName = "Ma Pharmacie"; // Nom par défaut
  List<DocumentSnapshot> _inventory = [];

  @override
  void initState() {
    super.initState();
    _fetchPharmacistAndInventoryData();
  }

  // Étape 1: Récupérer les informations du pharmacien (surtout son pharmacyId)
  Future<void> _fetchPharmacistAndInventoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Gérer le cas où l'utilisateur n'est pas connecté
        return;
      }

      // Récupérer les données de l'utilisateur depuis la collection 'users'
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      _pharmacyId = userData['pharmacyId'];

      if (_pharmacyId != null) {
        // Récupérer les détails de la pharmacie (comme le nom)
        DocumentSnapshot pharmacyDoc = await _firestore.collection('pharmacies').doc(_pharmacyId).get();
        if (pharmacyDoc.exists) {
          final pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
          setState(() {
             _pharmacyName = pharmacyData['name'] ?? "Ma Pharmacie";
          });
        }
        
        // Étape 2: Utiliser le pharmacyId pour récupérer l'inventaire
        _fetchInventory();
      } else {
         setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Erreur de récupération des données: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Récupère la liste des médicaments pour la pharmacie connectée
  Future<void> _fetchInventory() async {
     if (_pharmacyId == null) return;
     
     QuerySnapshot inventorySnapshot = await _firestore
        .collection('inventory')
        .where('pharmacyId', isEqualTo: _pharmacyId)
        .get();

      setState(() {
        _inventory = inventorySnapshot.docs;
        _isLoading = false;
      });
  }

  // Affiche une boîte de dialogue pour modifier le stock
  void _showEditStockDialog(DocumentSnapshot inventoryDoc) {
    final TextEditingController stockController = TextEditingController();
    final data = inventoryDoc.data() as Map<String, dynamic>;
    stockController.text = data['stock'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier le stock de ${data['medicationName']}"),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nouvelle quantité"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                int? newStock = int.tryParse(stockController.text);
                if (newStock != null) {
                  // Mettre à jour le document dans Firestore
                  await _firestore
                      .collection('inventory')
                      .doc(inventoryDoc.id)
                      .update({'stock': newStock});
                  
                  Navigator.pop(context);
                  _fetchInventory(); // Rafraîchir la liste
                }
              },
              child: const Text("Mettre à jour"),
            ),
          ],
        );
      },
    );
  }

  // Affiche une boîte de dialogue pour ajouter un nouveau médicament
  void _showAddMedicationDialog() {
     final TextEditingController nameController = TextEditingController();
     final TextEditingController stockController = TextEditingController();

     showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Ajouter un médicament au stock"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nom du médicament"),
                ),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantité en stock"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final String name = nameController.text;
                  final int? stock = int.tryParse(stockController.text);

                  if (name.isNotEmpty && stock != null && _pharmacyId != null) {
                     // Ajouter un nouveau document dans la collection 'inventory'
                     await _firestore.collection('inventory').add({
                        'medicationName': name,
                        'stock': stock,
                        'pharmacyId': _pharmacyId,
                     });
                     Navigator.pop(context);
                     _fetchInventory(); // Rafraîchir la liste
                  }
                },
                child: const Text("Ajouter"),
              )
            ],
          );
        },
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pharmacyName),
        centerTitle: true,
        // Ici, vous pourriez ajouter un bouton pour la gestion de profil
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Naviguer vers l'écran de gestion de profil du pharmacien
              // Navigator.push(context, MaterialPageRoute(builder: (_) => PharmacistProfileScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final doc = _inventory[index];
                final data = doc.data() as Map<String, dynamic>;
                final String medicationName = data['medicationName'] ?? 'Nom inconnu';
                final int stock = data['stock'] ?? 0;

                return ListTile(
                  title: Text(medicationName),
                  subtitle: Text("Quantité en stock : $stock"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditStockDialog(doc),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        tooltip: 'Ajouter un médicament',
        child: const Icon(Icons.add),
      ),
    );
  }
}