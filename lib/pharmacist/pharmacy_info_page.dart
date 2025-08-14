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
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final addressController = TextEditingController(text: currentData['address'] ?? '');
    final hoursController = TextEditingController(text: currentData['openingHours'] ?? '');
    bool isOnDuty = currentData['onDuty'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Modifier les Informations",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Nom de la pharmacie",
                        prefixIcon: const Icon(Icons.local_pharmacy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: "Adresse",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hoursController,
                      decoration: InputDecoration(
                        labelText: "Horaires d'ouverture",
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          "Pharmacie de garde",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isOnDuty 
                            ? "Votre pharmacie assure le service de garde"
                            : "Votre pharmacie n'assure pas le service de garde",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: isOnDuty,
                        activeColor: Colors.teal,
                        onChanged: (newValue) {
                          dialogSetState(() {
                            isOnDuty = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Annuler",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Le nom de la pharmacie ne peut pas être vide'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      await _firestore.collection('pharmacies').doc(widget.pharmacyId).update({
                        'name': nameController.text.trim(),
                        'address': addressController.text.trim(),
                        'openingHours': hoursController.text.trim(),
                        'onDuty': isOnDuty,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Informations mises à jour avec succès !'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la mise à jour: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.teal,
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Chargement des informations...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text("Impossible de trouver les informations de la pharmacie."),
          );
        }

        final pharmacyData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = pharmacyData['name'] ?? 'Nom non disponible';
        final String address = pharmacyData['address'] ?? 'Adresse non disponible';
        final String openingHours = pharmacyData['openingHours'] ?? 'Horaires non communiqués';
        final bool onDuty = pharmacyData['onDuty'] ?? false;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // En-tête avec le nom de la pharmacie
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Color(0xFF4DB6AC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: onDuty ? Colors.green : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              onDuty ? Icons.local_hospital : Icons.schedule,
                              color: onDuty ? Colors.white : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              onDuty ? 'Pharmacie de garde' : 'Pharmacie standard',
                              style: TextStyle(
                                color: onDuty ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Informations détaillées
                _buildInfoCard(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  title: 'Adresse',
                  content: address,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE5E5), Color(0xFFFFCCCC)],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  title: 'Horaires d\'ouverture',
                  content: openingHours,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  icon: Icons.health_and_safety,
                  iconColor: onDuty ? Colors.green : Colors.grey,
                  title: 'Service de garde',
                  content: onDuty 
                    ? 'Cette pharmacie assure le service de garde' 
                    : 'Cette pharmacie n\'assure pas le service de garde',
                  gradient: LinearGradient(
                    colors: onDuty 
                      ? [const Color(0xFFE8F5E8), const Color(0xFFC8E6C9)]
                      : [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: onDuty ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      onDuty ? 'Actif' : 'Inactif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bouton de modification amélioré
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Color(0xFF4DB6AC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEditInfoDialog(pharmacyData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Modifier les Informations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required LinearGradient gradient,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}