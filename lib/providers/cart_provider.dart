import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  List<CartItem> get items => _cartService.cartItems;
  int get itemCount => _cartService.itemCount;
  double get totalAmount => _cartService.totalAmount;
  bool get isEmpty => _cartService.isEmpty;
  bool get isNotEmpty => _cartService.isNotEmpty;

  CartProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      await _cartService.initialize();
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement du panier: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToCart({
    required String medicationId,
    required String medicationName,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    required int quantity,
    required double price,
    required double distance,
    required int stock,
  }) async {
    try {
      _clearError();
      
      final success = await _cartService.addToCart(
        medicationId: medicationId,
        medicationName: medicationName,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        pharmacyAddress: pharmacyAddress,
        quantity: quantity,
        price: price,
        distance: distance,
        stock: stock,
      );
      
      if (success) {
        notifyListeners();
        return true;
      } else {
        _setError('Stock insuffisant');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de l\'ajout au panier: $e');
      return false;
    }
  }

  Future<bool> removeFromCart(String itemId) async {
    try {
      _clearError();
      
      final success = await _cartService.removeFromCart(itemId);
      
      if (success) {
        notifyListeners();
        return true;
      } else {
        _setError('Impossible de supprimer l\'item');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      _clearError();
      
      final success = await _cartService.updateQuantity(itemId, newQuantity);
      
      if (success) {
        notifyListeners();
        return true;
      } else {
        if (newQuantity > 0) {
          _setError('Stock insuffisant');
        }
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  Future<void> clearCart() async {
    try {
      _clearError();
      await _cartService.clearCart();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression du panier: $e');
    }
  }

  Future<void> clearPharmacy(String pharmacyId) async {
    try {
      _clearError();
      await _cartService.clearPharmacy(pharmacyId);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    }
  }

  // Getters utilitaires
  Map<String, List<CartItem>> getItemsByPharmacy() {
    return _cartService.getItemsByPharmacy();
  }

  double getTotalByPharmacy(String pharmacyId) {
    return _cartService.getTotalByPharmacy(pharmacyId);
  }

  List<CartItem> getItemsByPharmacyId(String pharmacyId) {
    return _cartService.getItemsByPharmacyId(pharmacyId);
  }

  bool isInCart(String medicationId, String pharmacyId) {
    return _cartService.isInCart(medicationId, pharmacyId);
  }

  int getQuantityInCart(String medicationId, String pharmacyId) {
    return _cartService.getQuantityInCart(medicationId, pharmacyId);
  }

  CartItem? getItemById(String itemId) {
    return _cartService.getItemById(itemId);
  }

  List<CartItem> getUnavailableItems() {
    return _cartService.getUnavailableItems();
  }

  Map<String, dynamic> getCartStats() {
    return _cartService.getCartStats();
  }

  // Méthodes de validation
  bool hasUnavailableItems() {
    return getUnavailableItems().isNotEmpty;
  }

  List<String> getValidationErrors() {
    final errors = <String>[];
    
    if (isEmpty) {
      errors.add('Le panier est vide');
    }
    
    final unavailableItems = getUnavailableItems();
    if (unavailableItems.isNotEmpty) {
      errors.add('Certains items ne sont plus disponibles en quantité demandée');
    }
    
    return errors;
  }

  bool canProceedToCheckout() {
    return isNotEmpty && !hasUnavailableItems();
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Ne pas notifier ici pour éviter les rebuilds inutiles
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Méthodes pour les animations UI
  Future<void> addToCartWithAnimation({
    required String medicationId,
    required String medicationName,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    required int quantity,
    required double price,
    required double distance,
    required int stock,
  }) async {
    // Ajouter l'item
    final success = await addToCart(
      medicationId: medicationId,
      medicationName: medicationName,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      quantity: quantity,
      price: price,
      distance: distance,
      stock: stock,
    );

    if (success) {
      // Optionnel: Ajouter un délai pour l'animation
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}