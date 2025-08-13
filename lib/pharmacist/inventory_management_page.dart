import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryManagementPage extends StatefulWidget {
  final String pharmacyId;

  const InventoryManagementPage({super.key, required this.pharmacyId});

  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ... les fonctions _showEditStockDialog et _showAddMedicationDialog restent identiques ...
  void _showEditStockDialog(DocumentSnapshot inventoryDoc) {
    final TextEditingController stockController = TextEditingController();
    final data = inventoryDoc.data() as Map<String, dynamic>;
    stockController.text = data['stock'].toString();

    showDialog(
      context: context,
      builder: (context) {
        // ...existing dialog code...
        return AlertDialog(
          title: const Text('Modifier le stock'),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nouveau stock'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // ...code pour modifier le stock...
                Navigator.of(context).pop();
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMedicationDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // ...existing dialog code...
        return AlertDialog(
          title: const Text('Ajouter un médicament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du médicament'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock initial'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // ...code pour ajouter le médicament...
                Navigator.of(context).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }
  
  // NOUVEAUTÉ : La fonction pour afficher la confirmation de suppression
  void _showDeleteConfirmationDialog(DocumentSnapshot inventoryDoc) {
    final data = inventoryDoc.data() as Map<String, dynamic>;
    final String medicationName = data['medicationName'] ?? 'ce médicament';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Text("Êtes-vous sûr de vouloir supprimer '$medicationName' de votre stock ? Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Ferme simplement la boîte de dialogue
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // L'action de suppression dans Firestore
                  await inventoryDoc.reference.delete();
                  
                  // Ferme la boîte de dialogue après la suppression
                  Navigator.of(context).pop();

                  // Affiche un message de succès (optionnel mais recommandé)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$medicationName' a été supprimé.")),
                  );

                } catch (e) {
                  // Gérer une éventuelle erreur de suppression
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la suppression: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Style pour indiquer une action destructive
              ),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('inventory')
            .where('pharmacyId', isEqualTo: widget.pharmacyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun médicament dans votre stock."));
          }

          final inventory = snapshot.data!.docs;

          return ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final doc = inventory[index];
              final data = doc.data() as Map<String, dynamic>;
              final String medicationName = data['medicationName'] ?? 'Nom inconnu';
              final int stock = data['stock'] ?? 0;

              return ListTile(
                title: Text(medicationName),
                subtitle: Text("Quantité en stock : $stock"),
                // MODIFIÉ : On utilise un Row pour avoir plusieurs icônes
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Pour que la Row prenne le moins de place possible
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Modifier le stock',
                      onPressed: () => _showEditStockDialog(doc),
                    ),
                    // NOUVEAUTÉ : Le bouton de suppression
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer le médicament',
                      onPressed: () => _showDeleteConfirmationDialog(doc),
                    ),
                  ],
                ),
              );
            },
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