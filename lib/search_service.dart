import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'search_result_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fonction de test pour vérifier la connexion à Firestore
  Future<bool> testFirestoreConnection() async {
    try {
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Erreur de connexion Firestore: $e');
      return false;
    }
  }

  Future<List<PharmacySearchResult>> findMedication(
    String medicationName,
    Position userPosition,
  ) async {
    try {
      List<PharmacySearchResult> pharmaciesWithMedication = [];

      // Option 1: Recherche simplifiée sans index composite (pour éviter l'erreur)
      // Chercher d'abord par nom de médicament uniquement
      QuerySnapshot inventorySnapshot = await _firestore
          .collection('inventory')
          .where('medicationName', isEqualTo: medicationName)
          .get();

      if (inventorySnapshot.docs.isEmpty) {
        return []; // Aucun médicament trouvé
      }

      // 2. Filtrer côté client pour le stock > 0 (évite l'index composite)
      var docsWithStock = inventorySnapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return (data['stock'] ?? 0) > 0;
      }).toList();

      if (docsWithStock.isEmpty) {
        return []; // Aucun stock disponible
      }

      // 3. Boucler sur les résultats pour obtenir les détails de la pharmacie
      for (var doc in docsWithStock) {
        try {
          var inventoryData = doc.data() as Map<String, dynamic>;
          String pharmacyId = inventoryData['pharmacyId'];
          DocumentSnapshot pharmacyDoc = await _firestore
              .collection('pharmacies')
              .doc(pharmacyId)
              .get();

          if (pharmacyDoc.exists) {
            var pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;

            // Vérifier que la location existe
            if (pharmacyData['location'] == null) {
              print(
                'Pharmacie ${pharmacyData['name']} n\'a pas de coordonnées',
              );
              continue;
            }

            GeoPoint pharmacyLocation = pharmacyData['location'];

            // 3. Calculer la distance
            double distanceInMeters = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              pharmacyLocation.latitude,
              pharmacyLocation.longitude,
            );

            pharmaciesWithMedication.add(
              PharmacySearchResult(
                id: pharmacyId,
                name: pharmacyData['name'] ?? '',
                address: pharmacyData['address'] ?? '',
                onDuty: pharmacyData['onDuty'] ?? false,
                distance: distanceInMeters / 1000, // en km
                stock: inventoryData['stock'] ?? 0,
                latitude: pharmacyLocation.latitude,
                longitude: pharmacyLocation.longitude,
                phoneNumber: pharmacyData['phoneNumber'],
                openingHours: pharmacyData['openingHours'],
              ),
            );
          }
        } catch (e) {
          print('Erreur lors du traitement de la pharmacie: $e');
          // Continuer avec la prochaine pharmacie
          continue;
        }
      }

      // 4. Trier par distance
      pharmaciesWithMedication.sort((a, b) => a.distance.compareTo(b.distance));

      return pharmaciesWithMedication;
    } catch (e) {
      print('Erreur dans findMedication: $e');
      throw Exception(
        'Impossible de rechercher le médicament: ${e.toString()}',
      );
    }
  }
}
