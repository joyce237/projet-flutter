import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.onSearchRequested});

  final VoidCallback? onSearchRequested;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Panier'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (cartProvider.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCart();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Messages d'erreur
                if (cartProvider.errorMessage != null)
                  _buildErrorBanner(cartProvider),

                // Liste des items
                Expanded(
                  child: _buildCartList(cartProvider),
                ),

                // Résumé et checkout
                _buildBottomSection(cartProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajoutez des médicaments pour commencer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onSearchRequested != null) {
                widget.onSearchRequested!();
              } else {
                // Fallback: tenter de pop si route poussée séparément
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.search),
            label: const Text('Rechercher des médicaments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(CartProvider cartProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cartProvider.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: cartProvider.clearError,
            color: Colors.red.shade700,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(CartProvider cartProvider) {
    final pharmacyGroups = cartProvider.getItemsByPharmacy();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pharmacyGroups.length,
      itemBuilder: (context, index) {
        final pharmacyId = pharmacyGroups.keys.elementAt(index);
        final items = pharmacyGroups[pharmacyId]!;
        final pharmacyTotal = cartProvider.getTotalByPharmacy(pharmacyId);

        return _buildPharmacyCard(pharmacyId, items, pharmacyTotal, cartProvider);
      },
    );
  }

  Widget _buildPharmacyCard(String pharmacyId, List<CartItem> items,
      double pharmacyTotal, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la pharmacie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_pharmacy, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items.first.pharmacyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items.first.pharmacyAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items.first.distanceText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pharmacyTotal.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showClearPharmacyDialog(
                        context,
                        cartProvider,
                        pharmacyId,
                        items.first.pharmacyName,
                      ),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Vider', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items de la pharmacie
          ...items.map((item) => _buildCartItem(item, cartProvider)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          // Info médicament
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} € l\'unité',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (!item.isAvailable)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Stock insuffisant (${item.stock} disponible)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Contrôles quantité
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onPressed: item.quantity > 1
                        ? () => cartProvider.updateQuantity(item.id, item.quantity - 1)
                        : null,
                  ),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onPressed: item.quantity < item.stock
                        ? () => cartProvider.updateQuantity(item.id, item.quantity + 1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.totalPrice.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          
          // Bouton supprimer
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showRemoveItemDialog(context, cartProvider, item),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed != null ? Colors.teal.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: onPressed != null ? Colors.teal : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Résumé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cartProvider.itemCount} article${cartProvider.itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cartProvider.totalAmount.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            
            // Messages de validation
            if (cartProvider.hasUnavailableItems())
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certains articles ne sont plus disponibles en quantité demandée',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Bouton Checkout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: cartProvider.canProceedToCheckout()
                    ? () => _navigateToCheckout(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_checkout),
                    const SizedBox(width: 8),
                    Text(
                      cartProvider.canProceedToCheckout()
                          ? 'Procéder à la commande'
                          : 'Corriger les erreurs',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vider le panier'),
          content: const Text('Êtes-vous sûr de vouloir vider complètement votre panier ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.clearCart();
                HapticFeedback.mediumImpact();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Vider'),
            ),
          ],
        );
      },
    );
  }

  void _showClearPharmacyDialog(
    BuildContext context,
    CartProvider cartProvider,
    String pharmacyId,
    String pharmacyName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vider la pharmacie'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer tous les articles de $pharmacyName ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.clearPharmacy(pharmacyId);
                HapticFeedback.mediumImpact();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Vider'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    CartProvider cartProvider,
    CartItem item,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'article'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${item.medicationName} de votre panier ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.removeFromCart(item.id);
                HapticFeedback.mediumImpact();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}