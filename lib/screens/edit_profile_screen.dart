import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
    }

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null) {
      final hasNameChanged = _nameController.text.trim() != user.name;
      final hasPhoneChanged = _phoneController.text.trim() != (user.phoneNumber ?? '');
      
      setState(() {
        _hasChanges = hasNameChanged || hasPhoneChanged;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profil mis à jour avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(authProvider.errorMessage ?? 'Erreur lors de la mise à jour'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifications non sauvegardées'),
          content: const Text(
            'Vous avez des modifications non sauvegardées. '
            'Voulez-vous les abandonner ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuer l\'édition'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Abandonner'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Modifier le profil'),
          elevation: 0,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges && !_isLoading)
              TextButton(
                onPressed: _saveChanges,
                child: const Text(
                  'Sauvegarder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            
            if (user == null) {
              return const Center(
                child: Text('Erreur : utilisateur introuvable'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar section
                    _buildAvatarSection(user),
                    
                    const SizedBox(height: 32),
                    
                    // Form fields
                    _buildFormCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Save button (mobile)
                    if (_hasChanges)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
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
                              : const Text(
                                  'Sauvegarder les modifications',
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade200, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: user.profileImageUrl != null
                ? Image.network(
                    user.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user),
                  )
                : _buildAvatarFallback(user),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            // TODO: Implémenter la sélection d'image
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sélection d\'image - Bientôt disponible !'),
                backgroundColor: Colors.teal,
              ),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Modifier la photo'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    return Container(
      color: Colors.teal.shade50,
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: Colors.teal.shade600,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Name field
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre nom complet';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Phone field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: 'Optionnel',
                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Validation basique du numéro de téléphone
                  final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{8,}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Veuillez entrer un numéro de téléphone valide';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}