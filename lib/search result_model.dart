import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Dans votre Widget d'affichage
Widget build(BuildContext context) {
  // Supposons que 'pharmacies' est votre liste de résultats
  // et 'userLocation' est la position de l'utilisateur
  return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(userLocation.latitude, userLocation.longitude),
      initialZoom: 13.0,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.homepharma.app',
      ),
      MarkerLayer(
        markers: [
          // Marqueur pour l'utilisateur
          Marker(
            point: LatLng(userLocation.latitude, userLocation.longitude),
            child: Icon(Icons.my_location, color: Colors.blue),
          ),
          // Marqueurs pour les pharmacies
          ...pharmacies.map((pharma) => Marker(
            point: LatLng(pharma['location'].latitude, pharma['location'].longitude),
            child: Icon(Icons.local_pharmacy, color: Colors.red),
          )),
        ],
      ),
    ],
  );
}