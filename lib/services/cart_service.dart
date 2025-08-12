import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartService {
  static const String _cartKey = 'cart_items';
  static const String _cartCountKey = 'cart_count';
  
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _cartItems = [];
  int _nextId = 1;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;

  /// Initialiser le panier depuis le stockage local
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      final cartCount = prefs.getInt(_cartCountKey) ?? 1;
      
      _nextId = cartCount;
      
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> cartData = json.decode(cartJson);
        _cartItems = cartData
            .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Erreur lors du chargement du panier: $e');
      _cartItems = [];
    }
  }

  /// Sauvegarder le panier dans le stockage local
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_cartItems.map((item) => item.toMap()).toList());
      await prefs.setString(_cartKey, cartJson);
      await prefs.setInt(_cartCountKey, _nextId);
    } catch (e) {
      print('Erreur lors de la sauvegarde du panier: $e');
    }
  }

  /// Ajouter un médicament au panier
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
      // Vérifier si le médicament de cette pharmacie existe déjà
      final existingIndex = _cartItems.indexWhere((item) =>
          item.medicationId == medicationId && item.pharmacyId == pharmacyId);

      if (existingIndex != -1) {
        // Mettre à jour la quantité
        final existingItem = _cartItems[existingIndex];
        final newQuantity = existingItem.quantity + quantity;
        
        // Vérifier le stock disponible
        if (newQuantity > stock) {
          return false; // Stock insuffisant
        }
        
        _cartItems[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // Ajouter un nouveau item
        if (quantity > stock) {
          return false; // Stock insuffisant
        }
        
        final newItem = CartItem(
          id: 'cart_${_nextId++}',
          medicationId: medicationId,
          medicationName: medicationName,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
          pharmacyAddress: pharmacyAddress,
          quantity: quantity,
          price: price,
          distance: distance,
          stock: stock,
          addedAt: DateTime.now(),
        );
        
        _cartItems.add(newItem);
      }
      
      await _saveCart();
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout au panier: $e');
      return false;
    }
  }

  /// Supprimer un item du panier
  Future<bool> removeFromCart(String itemId) async {
    try {
      final initialLength = _cartItems.length;
      _cartItems.removeWhere((item) => item.id == itemId);
      
      if (_cartItems.length != initialLength) {
        await _saveCart();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du panier: $e');
      return false;
    }
  }

  /// Mettre à jour la quantité d'un item
  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        return await removeFromCart(itemId);
      }
      
      final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final item = _cartItems[itemIndex];
        
        // Vérifier le stock disponible
        if (newQuantity > item.stock) {
          return false; // Stock insuffisant
        }
        
        _cartItems[itemIndex] = item.copyWith(quantity: newQuantity);
        await _saveCart();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour de la quantité: $e');
      return false;
    }
  }

  /// Obtenir les items groupés par pharmacie
  Map<String, List<CartItem>> getItemsByPharmacy() {
    final Map<String, List<CartItem>> grouped = {};
    
    for (final item in _cartItems) {
      if (grouped.containsKey(item.pharmacyId)) {
        grouped[item.pharmacyId]!.add(item);
      } else {
        grouped[item.pharmacyId] = [item];
      }
    }
    
    return grouped;
  }

  /// Obtenir le total par pharmacie
  double getTotalByPharmacy(String pharmacyId) {
    return _cartItems
        .where((item) => item.pharmacyId == pharmacyId)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Obtenir les items d'une pharmacie spécifique
  List<CartItem> getItemsByPharmacyId(String pharmacyId) {
    return _cartItems.where((item) => item.pharmacyId == pharmacyId).toList();
  }

  /// Vérifier si un médicament est dans le panier
  bool isInCart(String medicationId, String pharmacyId) {
    return _cartItems.any((item) =>
        item.medicationId == medicationId && item.pharmacyId == pharmacyId);
  }

  /// Obtenir la quantité d'un médicament dans le panier
  int getQuantityInCart(String medicationId, String pharmacyId) {
    final item = _cartItems.firstWhere(
      (item) => item.medicationId == medicationId && item.pharmacyId == pharmacyId,
      orElse: () => CartItem(
        id: '',
        medicationId: '',
        medicationName: '',
        pharmacyId: '',
        pharmacyName: '',
        pharmacyAddress: '',
        quantity: 0,
        price: 0.0,
        distance: 0.0,
        stock: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  /// Vider une pharmacie du panier
  Future<void> clearPharmacy(String pharmacyId) async {
    try {
      _cartItems.removeWhere((item) => item.pharmacyId == pharmacyId);
      await _saveCart();
    } catch (e) {
      print('Erreur lors de la suppression des items de la pharmacie: $e');
    }
  }

  /// Vider complètement le panier
  Future<void> clearCart() async {
    try {
      _cartItems.clear();
      await _saveCart();
    } catch (e) {
      print('Erreur lors de la suppression du panier: $e');
    }
  }

  /// Obtenir un item par son ID
  CartItem? getItemById(String itemId) {
    try {
      return _cartItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Valider la disponibilité des items du panier
  List<CartItem> getUnavailableItems() {
    return _cartItems.where((item) => !item.isAvailable).toList();
  }

  /// Obtenir les statistiques du panier
  Map<String, dynamic> getCartStats() {
    final stats = <String, dynamic>{};
    final pharmacyGroups = getItemsByPharmacy();
    
    stats['totalItems'] = itemCount;
    stats['totalAmount'] = totalAmount;
    stats['pharmaciesCount'] = pharmacyGroups.length;
    stats['uniqueMedications'] = _cartItems.length;
    
    // Pharmacie la moins chère
    if (pharmacyGroups.isNotEmpty) {
      double minTotal = double.infinity;
      String? cheapestPharmacy;
      
      pharmacyGroups.forEach((pharmacyId, items) {
        final total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
        if (total < minTotal) {
          minTotal = total;
          cheapestPharmacy = items.first.pharmacyName;
        }
      });
      
      stats['cheapestPharmacy'] = cheapestPharmacy;
      stats['cheapestTotal'] = minTotal;
    }
    
    return stats;
  }
}