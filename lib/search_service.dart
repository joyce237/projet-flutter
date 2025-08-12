import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> findMedication(String medicationName, Position userPosition) async {
    List<Map<String, dynamic>> pharmaciesWithMedication = [];

    // 1. Rechercher dans l'inventaire
    QuerySnapshot inventorySnapshot = await _firestore
        .collection('inventory')
        .where('medicationName', isEqualTo: medicationName)
        .where('stock', isGreaterThan: 0)
        .get();

    if (inventorySnapshot.docs.isEmpty) {
      return []; // Aucun stock trouvé
    }

    // 2. Boucler sur les résultats pour obtenir les détails de la pharmacie
    for (var doc in inventorySnapshot.docs) {
      String pharmacyId = doc['pharmacyId'];
      DocumentSnapshot pharmacyDoc =
          await _firestore.collection('pharmacies').doc(pharmacyId).get();

      if (pharmacyDoc.exists) {
        var pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
        GeoPoint pharmacyLocation = pharmacyData['location'];

        // 3. Calculer la distance
        double distanceInMeters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          pharmacyLocation.latitude,
          pharmacyLocation.longitude,
        );

        pharmaciesWithMedication.add({
          'name': pharmacyData['name'],
          'address': pharmacyData['address'],
          'onDuty': pharmacyData['onDuty'],
          'distance': distanceInMeters / 1000, // en km
          'stock': doc['stock'], // stock disponible
        });
      }
    }

    // 4. Trier par distance
    pharmaciesWithMedication.sort((a, b) => a['distance'].compareTo(b['distance']));

    return pharmaciesWithMedication;
  }
}