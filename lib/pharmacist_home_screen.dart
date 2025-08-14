import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pharmacist/inventory_management_page.dart';
import 'pharmacist/pharmacy_info_page.dart';
import 'pharmacist/pharmacist_profile_page.dart';

class PharmacistHomeScreen extends StatefulWidget {
  final String pharmacyId;
  const PharmacistHomeScreen({super.key, required this.pharmacyId});

  @override
  State<PharmacistHomeScreen> createState() => _PharmacistHomeScreenState();
}

class _PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
  int _selectedIndex = 0;
  
  // On utilise un "Future" pour gérer les états de chargement/erreur proprement
  late final Future<Map<String, dynamic>> _pharmacistDataFuture;

  @override
  void initState() {
    super.initState();
    // On lance la fonction de récupération des données ici
    _pharmacistDataFuture = _fetchPharmacistData();
  }

  // Cette fonction retourne maintenant un "Future" avec les données nécessaires
  Future<Map<String, dynamic>> _fetchPharmacistData() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    User? currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception("Utilisateur non connecté.");
    }

    final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) {
      throw Exception("Profil utilisateur introuvable dans la base de données.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    
    // ICI : La vérification cruciale
    final String? pharmacyId = userData['pharmacyId'];
    if (pharmacyId == null || pharmacyId.isEmpty) {
      throw Exception("Ce compte pharmacien n'est associé à aucune pharmacie.");
    }

    final pharmacyDoc = await firestore.collection('pharmacies').doc(pharmacyId).get();
    final String pharmacyName = pharmacyDoc.exists
        ? (pharmacyDoc.data() as Map<String, dynamic>)['name'] ?? 'Nom de pharmacie inconnu'
        : 'Pharmacie introuvable';
    
    // On retourne une map avec toutes les données dont on a besoin
    return {
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On utilise un FutureBuilder pour construire l'UI en fonction de l'état du Future
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pharmacistDataFuture,
        builder: (context, snapshot) {
          // Cas 1 : En attente des données
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Cas 2 : Le Future a terminé avec une erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Erreur de chargement : \n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // Cas 3 : Le Future a terminé avec succès
          if (snapshot.hasData) {
            final String pharmacyId = snapshot.data!['pharmacyId'];
            final String pharmacyName = snapshot.data!['pharmacyName'];

            final List<Widget> widgetOptions = [
              InventoryManagementPage(pharmacyId: pharmacyId),
              PharmacyInfoPage(pharmacyId: pharmacyId),
              const PharmacistProfilePage(),
            ];

            // On construit l'UI principale seulement si tout est OK
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  pharmacyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Color(0xFF4DB6AC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              body: Center(
                child: widgetOptions.elementAt(_selectedIndex),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2),
                      activeIcon: Icon(Icons.inventory_2, size: 28),
                      label: 'Stock',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_pharmacy),
                      activeIcon: Icon(Icons.local_pharmacy, size: 28),
                      label: 'Ma Pharmacie',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      activeIcon: Icon(Icons.person, size: 28),
                      label: 'Profil',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.teal,
                  unselectedItemColor: Colors.grey[400],
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  onTap: _onItemTapped,
                ),
              ),
            );
          }
          
          // Cas par défaut (ne devrait pas arriver)
          return const Center(child: Text("Une erreur inattendue est survenue."));
        },
      ),
    );
  }
}