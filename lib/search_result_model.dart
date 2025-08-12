
class PharmacySearchResult {
  final String id;
  final String name;
  final String address;
  final bool onDuty;
  final double distance; // en km
  final int stock;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? openingHours;

  PharmacySearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.onDuty,
    required this.distance,
    required this.stock,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.openingHours,
  });

  factory PharmacySearchResult.fromMap(Map<String, dynamic> map) {
    return PharmacySearchResult(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      onDuty: map['onDuty'] ?? false,
      distance: (map['distance'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      phoneNumber: map['phoneNumber'],
      openingHours: map['openingHours'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'onDuty': onDuty,
      'distance': distance,
      'stock': stock,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'openingHours': openingHours,
    };
  }

  String get distanceText => '${distance.toStringAsFixed(1)} km';
  
  String get statusText => onDuty ? 'DE GARDE' : 'Horaires normaux';
  
  String get stockText => 'Stock: $stock';
}