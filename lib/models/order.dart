import 'cart_item.dart';

enum OrderType { reservation, delivery }
enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }
enum PaymentMethod { cash, card, paypal, applePay }

class Order {
  final String id;
  final String userId;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final OrderType type;
  final OrderStatus status;
  final List<CartItem> items;
  final double totalAmount;
  final PaymentMethod? paymentMethod;
  final String? deliveryAddress;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Order({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.type,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.paymentMethod,
    this.deliveryAddress,
    this.phoneNumber,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.readyAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
      pharmacyAddress: map['pharmacyAddress'] ?? '',
      type: OrderType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => OrderType.reservation,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromMap(item))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      deliveryAddress: map['deliveryAddress'],
      phoneNumber: map['phoneNumber'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['confirmedAt'])
          : null,
      readyAt: map['readyAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readyAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['cancelledAt'])
          : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'confirmedAt': confirmedAt?.millisecondsSinceEpoch,
      'readyAt': readyAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
      'cancellationReason': cancellationReason,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    OrderType? type,
    OrderStatus? status,
    List<CartItem>? items,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? readyAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      type: type ?? this.type,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      readyAt: readyAt ?? this.readyAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Getters utiles
  bool get isReservation => type == OrderType.reservation;
  bool get isDelivery => type == OrderType.delivery;
  
  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isReady => status == OrderStatus.ready;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  
  bool get canBeCancelled => 
      status == OrderStatus.pending || 
      status == OrderStatus.confirmed;
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get typeText {
    switch (type) {
      case OrderType.reservation:
        return 'Réservation';
      case OrderType.delivery:
        return 'Livraison';
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.completed:
        return 'Terminée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String get paymentMethodText {
    if (paymentMethod == null) return 'Non spécifiée';
    switch (paymentMethod!) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order{id: $id, type: $typeText, status: $statusText, totalAmount: $totalAmount}';
  }
}