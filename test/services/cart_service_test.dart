import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepharma/services/cart_service.dart';

void main() {
  group('CartService', () {
    late CartService service;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      service = CartService();
      await service.clearCart();
    });

    test('addToCart then updateQuantity and clearPharmacy workflow', () async {
      // Add two items same pharmacy
      final ok1 = await service.addToCart(
        medicationId: 'm1',
        medicationName: 'Paracetamol',
        pharmacyId: 'ph1',
        pharmacyName: 'Pharma 1',
        pharmacyAddress: 'Adresse 1',
        quantity: 1,
        price: 2.5,
        distance: 1.0,
        stock: 5,
      );
      final ok2 = await service.addToCart(
        medicationId: 'm2',
        medicationName: 'Ibuprofène',
        pharmacyId: 'ph1',
        pharmacyName: 'Pharma 1',
        pharmacyAddress: 'Adresse 1',
        quantity: 2,
        price: 4.0,
        distance: 1.2,
        stock: 10,
      );

      expect(ok1, true);
      expect(ok2, true);
      expect(service.cartItems.length, 2);

      // Update quantity of first item
      final firstId = service.cartItems.first.id;
      final updated = await service.updateQuantity(firstId, 3);
      expect(updated, true);
      final updatedItem = service.cartItems.firstWhere((e) => e.id == firstId);
      expect(updatedItem.quantity, 3);

      // Grouped by pharmacy
      final byPharmacy = service.getItemsByPharmacy();
      expect(byPharmacy.keys.length, 1);
      expect(byPharmacy['ph1']!.length, 2);

      // Stats
      final stats = service.getCartStats();
      expect(stats['pharmaciesCount'], 1);
      expect(stats['uniqueMedications'], 2);

      // Clear pharmacy
      await service.clearPharmacy('ph1');
      expect(service.cartItems.isEmpty, true);
    });

    test('removeFromCart and clearCart', () async {
      await service.addToCart(
        medicationId: 'm3',
        medicationName: 'Amoxicilline',
        pharmacyId: 'ph2',
        pharmacyName: 'Pharma 2',
        pharmacyAddress: 'Adresse 2',
        quantity: 2,
        price: 3.0,
        distance: 2.0,
        stock: 5,
      );

      expect(service.cartItems.length, 1);
      final id = service.cartItems.first.id;

      final removed = await service.removeFromCart(id);
      expect(removed, true);
      expect(service.cartItems.isEmpty, true);

      // Add again then clear all
      await service.addToCart(
        medicationId: 'm4',
        medicationName: 'Vitamine C',
        pharmacyId: 'ph3',
        pharmacyName: 'Pharma 3',
        pharmacyAddress: 'Adresse 3',
        quantity: 1,
        price: 6.0,
        distance: 3.0,
        stock: 10,
      );
      expect(service.cartItems.length, 1);
      await service.clearCart();
      expect(service.cartItems.isEmpty, true);
    });

    test('isInCart and getQuantityInCart logic', () async {
      await service.addToCart(
        medicationId: 'm5',
        medicationName: 'Doliprane',
        pharmacyId: 'ph4',
        pharmacyName: 'Pharma 4',
        pharmacyAddress: 'Adresse 4',
        quantity: 2,
        price: 2.0,
        distance: 0.8,
        stock: 10,
      );

      expect(service.isInCart('m5', 'ph4'), true);
      expect(service.getQuantityInCart('m5', 'ph4'), 2);
      expect(service.isInCart('mX', 'ph4'), false);
    });
  });
}
