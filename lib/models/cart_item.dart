class CartItem {
  final String id;
  final String medicationId;
  final String medicationName;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final int quantity;
  final double price;
  final double distance;
  final int stock;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.quantity,
    required this.price,
    required this.distance,
    required this.stock,
    required this.addedAt,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      pharmacyAddress: map['pharmacyAddress'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'quantity': quantity,
      'price': price,
      'distance': distance,
      'stock': stock,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  CartItem copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    int? quantity,
    double? price,
    double? distance,
    int? stock,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      stock: stock ?? this.stock,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => price * quantity;
  String get distanceText => '${distance.toStringAsFixed(1)} km';
  
  bool get isAvailable => quantity <= stock;
  bool get isOutOfStock => stock == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.medicationId == medicationId &&
        other.pharmacyId == pharmacyId;
  }

  @override
  int get hashCode => Object.hash(id, medicationId, pharmacyId);

  @override
  String toString() {
    return 'CartItem{id: $id, medicationName: $medicationName, quantity: $quantity, price: $price}';
  }
}