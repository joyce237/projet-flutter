import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_models;
import '../models/cart_item.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  /// Créer une nouvelle commande
  Future<String?> createOrder({
    required String userId,
    required List<CartItem> items,
    required app_models.OrderType type,
    required app_models.PaymentMethod paymentMethod,
    required String phoneNumber,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      // Grouper les items par pharmacie
      final Map<String, List<CartItem>> pharmacyGroups = {};
      for (final item in items) {
        if (pharmacyGroups.containsKey(item.pharmacyId)) {
          pharmacyGroups[item.pharmacyId]!.add(item);
        } else {
          pharmacyGroups[item.pharmacyId] = [item];
        }
      }

      final List<String> orderIds = [];

      // Créer une commande pour chaque pharmacie
      for (final entry in pharmacyGroups.entries) {
        final pharmacyId = entry.key;
        final pharmacyItems = entry.value;
        
        final totalAmount = pharmacyItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        
        final order = app_models.Order(
          id: '', // Sera généré par Firestore
          userId: userId,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyItems.first.pharmacyName,
          pharmacyAddress: pharmacyItems.first.pharmacyAddress,
          type: type,
          status: app_models.OrderStatus.pending,
          items: pharmacyItems,
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress,
          phoneNumber: phoneNumber,
          notes: notes,
          createdAt: DateTime.now(),
        );

        // Sauvegarder dans Firestore
        final docRef = await _firestore.collection('orders').add(order.toMap());
        orderIds.add(docRef.id);
        
        // Optionnel: Mettre à jour le stock en pharmacie
        await _updatePharmacyStock(pharmacyId, pharmacyItems);
      }

      // Retourner le premier ID (ou combiner les IDs si nécessaire)
      return orderIds.isNotEmpty ? orderIds.first : null;
      
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      return null;
    }
  }

  /// Mettre à jour le stock en pharmacie (réserver les articles)
  Future<void> _updatePharmacyStock(String pharmacyId, List<CartItem> items) async {
    try {
      final batch = _firestore.batch();
      
      for (final item in items) {
        final inventoryQuery = await _firestore
            .collection('inventory')
            .where('pharmacyId', isEqualTo: pharmacyId)
            .where('medicationName', isEqualTo: item.medicationName)
            .limit(1)
            .get();
            
        if (inventoryQuery.docs.isNotEmpty) {
          final inventoryDoc = inventoryQuery.docs.first;
          final currentStock = inventoryDoc.data()['stock'] ?? 0;
          final newStock = (currentStock - item.quantity).clamp(0, currentStock);
          
          batch.update(inventoryDoc.reference, {'stock': newStock});
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Erreur lors de la mise à jour du stock: $e');
    }
  }

  /// Récupérer les commandes d'un utilisateur
  Future<List<app_models.Order>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => app_models.Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des commandes: $e');
      return [];
    }
  }

  /// Récupérer une commande par son ID
  Future<app_models.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (doc.exists && doc.data() != null) {
        return app_models.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la commande: $e');
      return null;
    }
  }

  /// Stream pour écouter les changements d'une commande
  Stream<app_models.Order?> orderStream(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return app_models.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Stream pour écouter toutes les commandes d'un utilisateur
  Stream<List<app_models.Order>> userOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mettre à jour le statut d'une commande (pour les pharmaciens)
  Future<bool> updateOrderStatus(String orderId, app_models.OrderStatus newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
      };

      // Ajouter des timestamps selon le statut
      switch (newStatus) {
        case app_models.OrderStatus.confirmed:
          updateData['confirmedAt'] = FieldValue.serverTimestamp();
          break;
        case app_models.OrderStatus.ready:
          updateData['readyAt'] = FieldValue.serverTimestamp();
          break;
        case app_models.OrderStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case app_models.OrderStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Annuler une commande
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_models.OrderStatus.cancelled.toString().split('.').last,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
      });
      
      // TODO: Restaurer le stock si nécessaire
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la commande: $e');
      return false;
    }
  }

  /// Récupérer les commandes pour un pharmacien
  Future<List<app_models.Order>> getPharmacyOrders(String pharmacyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('pharmacyId', isEqualTo: pharmacyId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => app_models.Order.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des commandes de la pharmacie: $e');
      return [];
    }
  }

  /// Stream des commandes pour un pharmacien
  Stream<List<app_models.Order>> pharmacyOrdersStream(String pharmacyId) {
    return _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Récupérer les statistiques de commandes pour un utilisateur
  Future<Map<String, dynamic>> getUserOrderStats(String userId) async {
    try {
      final orders = await getUserOrders(userId);
      
      final stats = <String, dynamic>{
        'totalOrders': orders.length,
        'totalSpent': orders.fold(0.0, (sum, order) => sum + order.totalAmount),
        'completedOrders': orders.where((o) => o.isCompleted).length,
        'pendingOrders': orders.where((o) => o.isPending || o.isConfirmed || o.isPreparing).length,
        'cancelledOrders': orders.where((o) => o.isCancelled).length,
      };
      
      // Calcul des moyennes
      if (orders.isNotEmpty) {
        stats['averageOrderValue'] = stats['totalSpent'] / orders.length;
      }
      
      return stats;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Rechercher des commandes
  Future<List<app_models.Order>> searchOrders({
    String? userId,
    String? pharmacyId,
    app_models.OrderStatus? status,
    app_models.OrderType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('orders');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (pharmacyId != null) {
        query = query.where('pharmacyId', isEqualTo: pharmacyId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => app_models.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche de commandes: $e');
      return [];
    }
  }
}