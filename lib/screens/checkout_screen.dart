import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  OrderType _selectedType = OrderType.reservation;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _phoneController.text = authProvider.user!.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<CartProvider, AuthProvider>(
        builder: (context, cartProvider, authProvider, _) {
          if (cartProvider.isEmpty) {
            return _buildEmptyState();
          }

          return SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderSummary(cartProvider),
                          const SizedBox(height: 20),
                          _buildOrderTypeSelection(),
                          const SizedBox(height: 20),
                          if (_selectedType == OrderType.delivery)
                            _buildDeliveryForm(),
                          if (_selectedType == OrderType.delivery)
                            const SizedBox(height: 20),
                          _buildContactForm(),
                          const SizedBox(height: 20),
                          _buildPaymentSelection(),
                          const SizedBox(height: 20),
                          _buildNotesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomSection(cartProvider, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Votre panier est vide'),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final pharmacyGroups = cartProvider.getItemsByPharmacy();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Récapitulatif de votre commande',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pharmacyGroups.entries.map((entry) {
              final pharmacyId = entry.key;
              final items = entry.value;
              final total = cartProvider.getTotalByPharmacy(pharmacyId);

              return _buildPharmacySummary(items, total);
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${cartProvider.itemCount} articles)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${cartProvider.totalAmount.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacySummary(List<CartItem> items, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_pharmacy, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  items.first.pharmacyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.medicationName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Mode de récupération',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderTypeOption(
              OrderType.reservation,
              'Réservation',
              'Récupération en pharmacie',
              Icons.store,
              Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildOrderTypeOption(
              OrderType.delivery,
              'Livraison',
              'Livraison à domicile (frais supplémentaires)',
              Icons.local_shipping,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(
    OrderType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type == OrderType.reservation) {
            _selectedPayment = PaymentMethod.cash;
          }
        });
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Adresse de livraison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Adresse complète *',
                hintText: 'Rue, ville, code postal...',
                prefixIcon: const Icon(Icons.home, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (_selectedType == OrderType.delivery &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Veuillez entrer une adresse de livraison';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Informations de contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone *',
                hintText: 'Pour vous contacter si nécessaire',
                prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Mode de paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedType == OrderType.reservation)
              _buildPaymentOption(
                PaymentMethod.cash,
                'Paiement sur place',
                'Payez directement à la pharmacie',
                Icons.store,
              ),
            if (_selectedType == OrderType.delivery) ...[
              _buildPaymentOption(
                PaymentMethod.card,
                'Carte bancaire',
                'Paiement sécurisé en ligne',
                Icons.credit_card,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                PaymentMethod.cash,
                'Paiement à la livraison',
                'Payez le livreur en espèces',
                Icons.local_shipping,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPayment == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayment = method;
        });
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.teal : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.teal : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Notes additionnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Commentaires (optionnel)',
                hintText: 'Instructions spéciales pour la pharmacie...',
                prefixIcon: const Icon(Icons.edit_note, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(CartProvider cartProvider, AuthProvider authProvider) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _placeOrder(cartProvider, authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle),
                          const SizedBox(width: 8),
                          Text(
                            _selectedType == OrderType.reservation
                                ? 'Confirmer la réservation'
                                : 'Confirmer la commande',
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

  Future<void> _placeOrder(CartProvider cartProvider, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (authProvider.user == null) {
      _showErrorDialog('Erreur d\'authentification', 'Vous devez être connecté pour passer une commande.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = OrderService();
      
      final orderId = await orderService.createOrder(
        userId: authProvider.user!.id,
        items: cartProvider.items,
        type: _selectedType,
        paymentMethod: _selectedPayment,
        phoneNumber: _phoneController.text.trim(),
        deliveryAddress: _selectedType == OrderType.delivery
            ? _addressController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (orderId != null) {
        // Vider le panier
        await cartProvider.clearCart();
        
        // Feedback haptique
        HapticFeedback.mediumImpact();
        
        // Naviguer vers l'écran de confirmation
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(orderId: orderId),
            ),
          );
        }
      } else {
        _showErrorDialog('Erreur', 'Impossible de créer la commande. Veuillez réessayer.');
      }
    } catch (e) {
      _showErrorDialog('Erreur', 'Une erreur est survenue: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Écran de confirmation temporaire
class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Commande confirmée !',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Numéro de commande',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '#${orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Vous recevrez une confirmation par notification.\nLa pharmacie vous contactera sous peu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Retour à l\'accueil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}