import 'package:flutter_test/flutter_test.dart';
import 'package:homepharma/providers/cart_provider.dart';

void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      cartProvider = CartProvider();
      // Wait for loading to complete
      await Future.delayed(Duration(milliseconds: 100));
    });

    test('addToCart adds item and updates counts', () async {
      final success = await cartProvider.addToCart(
        medicationId: 'm1',
        medicationName: 'Paracetamol',
        pharmacyId: 'p1',
        pharmacyName: 'Pharmacie 1',
        pharmacyAddress: 'Adresse 1',
        quantity: 2,
        price: 3.0,
        distance: 1.0,
        stock: 10,
      );

      expect(success, true);
      expect(cartProvider.itemCount, 2);
      expect(cartProvider.items.length, 1);
      expect(cartProvider.totalAmount, 6.0);
    });

    test('updateQuantity modifies quantity and total', () async {
      await cartProvider.addToCart(
        medicationId: 'm2',
        medicationName: 'Ibuprofène',
        pharmacyId: 'p1',
        pharmacyName: 'Pharmacie 1',
        pharmacyAddress: 'Adresse 1',
        quantity: 1,
        price: 5.0,
        distance: 2.0,
        stock: 5,
      );

      if (cartProvider.items.isNotEmpty) {
        final firstItemId = cartProvider.items.first.id;
        final ok = await cartProvider.updateQuantity(firstItemId, 3);

        expect(ok, true);
        expect(cartProvider.itemCount, 3);
        expect(cartProvider.totalAmount, 15.0);
      }
    });

    test('removeFromCart removes item', () async {
      await cartProvider.addToCart(
        medicationId: 'm3',
        medicationName: 'Amoxicilline',
        pharmacyId: 'p2',
        pharmacyName: 'Pharmacie 2',
        pharmacyAddress: 'Adresse 2',
        quantity: 1,
        price: 8.0,
        distance: 4.0,
        stock: 5,
      );

      if (cartProvider.items.isNotEmpty) {
        final id = cartProvider.items.first.id;
        final removed = await cartProvider.removeFromCart(id);

        expect(removed, true);
        expect(cartProvider.itemCount, 0);
        expect(cartProvider.items.isEmpty, true);
      }
    });
  });
}
