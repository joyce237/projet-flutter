import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyInfoPage extends StatefulWidget {
  final String pharmacyId;
  const PharmacyInfoPage({super.key, required this.pharmacyId});

  @override
  State<PharmacyInfoPage> createState() => _PharmacyInfoPageState();
}

class _PharmacyInfoPageState extends State<PharmacyInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NOUVEAUTÉ : La fonction qui affiche le formulaire de modification
  void _showEditInfoDialog(Map<String, dynamic> currentData) {
    // On utilise des contrôleurs pour gérer le texte des champs
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final addressController = TextEditingController(text: currentData['address'] ?? '');
    final hoursController = TextEditingController(text: currentData['openingHours'] ?? '');
    
    // Une variable pour gérer l'état du switch "De Garde"
    bool isOnDuty = currentData['onDuty'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permet de gérer l'état à l'intérieur de la boîte de dialogue (pour le switch)
        // sans reconstruire toute la page.
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("Modifier les Informations"),
              // Permet le défilement si le contenu est trop grand (ex: clavier visible)
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nom de la pharmacie"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Adresse"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(labelText: "Horaires d'ouverture"),
                    ),
                    const SizedBox(height: 16),
                    // Un switch avec un libellé, parfait pour une option oui/non
                    SwitchListTile(
                      title: const Text("Pharmacie de garde"),
                      value: isOnDuty,
                      onChanged: (newValue) {
                        // On met à jour l'état à l'intérieur de la boîte de dialogue
                        dialogSetState(() {
                          isOnDuty = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Mettre à jour les données dans Firestore
                    try {
                      await _firestore.collection('pharmacies').doc(widget.pharmacyId).update({
                        'name': nameController.text,
                        'address': addressController.text,
                        'openingHours': hoursController.text,
                        'onDuty': isOnDuty,
                      });

                      Navigator.of(context).pop(); // Fermer la boîte de dialogue
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informations mises à jour avec succès !')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
                      );
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('pharmacies').doc(widget.pharmacyId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Impossible de trouver les informations de la pharmacie."));
        }

        final pharmacyData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = pharmacyData['name'] ?? 'Nom non disponible';
        final String address = pharmacyData['address'] ?? 'Adresse non disponible';
        final String openingHours = pharmacyData['openingHours'] ?? 'Horaires non communiqués';
        final bool onDuty = pharmacyData['onDuty'] ?? false;

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ... Le reste du code d'affichage reste exactement le même ...
              Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Card(elevation: 2, child: ListTile(leading: const Icon(Icons.location_on, color: Colors.blue), title: const Text('Adresse', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(address))),
              const SizedBox(height: 12),
              Card(elevation: 2, child: ListTile(leading: const Icon(Icons.access_time_filled, color: Colors.orange), title: const Text('Horaires d\'ouverture', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(openingHours))),
              const SizedBox(height: 12),
              Card(elevation: 2, child: ListTile(leading: Icon(Icons.health_and_safety, color: onDuty ? Colors.green : Colors.grey), title: const Text('De Garde', style: TextStyle(fontWeight: FontWeight.bold)), trailing: Chip(label: Text(onDuty ? 'Oui' : 'Non', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: onDuty ? Colors.green : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 12.0)))),
              const SizedBox(height: 24),
              
              // MODIFICATION : Le bouton appelle maintenant notre nouvelle fonction
              ElevatedButton.icon(
                onPressed: () {
                  // On passe les données actuelles pour pré-remplir le formulaire
                  _showEditInfoDialog(pharmacyData);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier les Informations'),
              )
            ],
          ),
        );
      },
    );
  }
}