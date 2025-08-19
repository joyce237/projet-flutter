import 'package:flutter_test/flutter_test.dart';
import 'package:homepharma/models/cart_item.dart';

void main() {
  group('CartItem Model', () {
    test('toMap / fromMap round trip works', () {
      final item = CartItem(
        id: 'cart_1',
        medicationId: 'med_1',
        medicationName: 'Paracetamol',
        pharmacyId: 'pharm_1',
        pharmacyName: 'Pharmacie Centrale',
        pharmacyAddress: '1 rue de Paris',
        quantity: 2,
        price: 3.5,
        distance: 1.2,
        stock: 10,
        addedAt: DateTime(2025, 1, 1, 12, 0, 0),
      );

      final map = item.toMap();
      final restored = CartItem.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.medicationName, item.medicationName);
      expect(restored.totalPrice, 7.0);
      expect(restored.distanceText, '1.2 km');
      expect(restored.isAvailable, true);
    });

    test('copyWith updates fields correctly', () {
      final original = CartItem(
        id: 'cart_2',
        medicationId: 'med_2',
        medicationName: 'Ibuprofène',
        pharmacyId: 'pharm_2',
        pharmacyName: 'Pharma Ouest',
        pharmacyAddress: '2 avenue Sud',
        quantity: 1,
        price: 5.0,
        distance: 3.0,
        stock: 5,
        addedAt: DateTime.now(),
      );

      final updated = original.copyWith(quantity: 3, price: 4.5);

      expect(updated.quantity, 3);
      expect(updated.price, 4.5);
      expect(updated.totalPrice, 13.5);
      expect(updated.medicationName, original.medicationName);
    });

    test('isAvailable reflects stock vs quantity', () {
      final item = CartItem(
        id: 'cart_3',
        medicationId: 'med_3',
        medicationName: 'Amoxicilline',
        pharmacyId: 'pharm_3',
        pharmacyName: 'Pharma Est',
        pharmacyAddress: '3 route Nord',
        quantity: 4,
        price: 2.0,
        distance: 0.5,
        stock: 3,
        addedAt: DateTime.now(),
      );

      expect(item.isAvailable, false);
      expect(item.isOutOfStock, false);

      final outOfStock = item.copyWith(quantity: 1, stock: 0);
      expect(outOfStock.isAvailable, false);
      expect(outOfStock.isOutOfStock, true);
    });
  });
}
