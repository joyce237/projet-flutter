import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../screens/edit_profile_screen.dart';

class PharmacistProfilePage extends StatelessWidget {
  const PharmacistProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, authProvider, appProvider, _) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authProvider.isAuthenticated || authProvider.user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Pharmacien non connecté',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('État: ${authProvider.state}'),
                  if (authProvider.errorMessage != null)
                    Text(
                      'Erreur: ${authProvider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.reloadUserData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recharger'),
                  ),
                ],
              ),
            );
          }

          final user = authProvider.user!;

          return FutureBuilder<DocumentSnapshot?>(
            future: _getPharmacyData(user.pharmacyId),
            builder: (context, pharmacySnapshot) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, user, authProvider),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildProfileCard(context, user),
                          const SizedBox(height: 16),
                          if (pharmacySnapshot.hasData && pharmacySnapshot.data != null)
                            _buildPharmacyCard(context, pharmacySnapshot.data!),
                          const SizedBox(height: 16),
                          _buildSettingsCard(context, appProvider, authProvider),
                          const SizedBox(height: 16),
                          _buildPharmacistStatsCard(context, user),
                          const SizedBox(height: 16),
                          _buildActionsCard(context, authProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<DocumentSnapshot?> _getPharmacyData(String? pharmacyId) async {
    if (pharmacyId == null || pharmacyId.isEmpty) return null;
    
    try {
      return await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .get();
    } catch (e) {
      print('Erreur lors du chargement des données pharmacie: $e');
      return null;
    }
  }

  Widget _buildAppBar(
    BuildContext context,
    UserModel user,
    AuthProvider authProvider,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade400, Colors.teal.shade600],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileImage(user),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pharmacien',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileImage(UserModel user) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: user.profileImageUrl != null
            ? CachedNetworkImage(
                imageUrl: user.profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    _buildAvatarFallback(user),
              )
            : _buildAvatarFallback(user),
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: Colors.teal.shade600,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Nom', user.displayName),
            _buildInfoRow(Icons.email_outlined, 'Email', user.email),
            if (user.phoneNumber != null)
              _buildInfoRow(
                Icons.phone_outlined,
                'Téléphone',
                user.phoneNumber!,
              ),
            _buildInfoRow(
              Icons.business_outlined,
              'Rôle',
              'Pharmacien titulaire',
            ),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Membre depuis',
              _formatDate(user.createdAt),
            ),
            if (user.lastLoginAt != null)
              _buildInfoRow(
                Icons.access_time_outlined,
                'Dernière connexion',
                _formatDate(user.lastLoginAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, DocumentSnapshot pharmacyDoc) {
    final pharmacyData = pharmacyDoc.data() as Map<String, dynamic>?;
    
    if (pharmacyData == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.local_pharmacy, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Aucune pharmacie associée',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final String name = pharmacyData['name'] ?? 'Nom non disponible';
    final String address = pharmacyData['address'] ?? 'Adresse non disponible';
    final String openingHours = pharmacyData['openingHours'] ?? 'Horaires non communiqués';
    final bool onDuty = pharmacyData['onDuty'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_pharmacy, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Ma Pharmacie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.store_outlined, 'Nom', name),
            _buildInfoRow(Icons.location_on_outlined, 'Adresse', address),
            _buildInfoRow(Icons.access_time_outlined, 'Horaires', openingHours),
            _buildInfoRowWithChip(
              Icons.health_and_safety_outlined,
              'Statut de garde',
              onDuty ? 'En garde' : 'Pas en garde',
              onDuty ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithChip(IconData icon, String label, String value, Color chipColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: chipColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    AppProvider appProvider,
    AuthProvider authProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Préférences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.dark_mode_outlined,
              'Mode sombre',
              Switch(
                value: appProvider.isDarkMode,
                onChanged: (value) => appProvider.toggleTheme(),
                activeColor: Colors.teal,
              ),
            ),
            _buildSettingsTile(
              Icons.notifications_outlined,
              'Notifications',
              Switch(
                value: appProvider.notificationsEnabled,
                onChanged: appProvider.setNotificationsEnabled,
                activeColor: Colors.teal,
              ),
            ),
            _buildSettingsTile(
              Icons.location_on_outlined,
              'Géolocalisation',
              Switch(
                value: appProvider.locationEnabled,
                onChanged: appProvider.setLocationEnabled,
                activeColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          trailing,
        ],
      ),
    );
  }

  Widget _buildPharmacistStatsCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Pharmacie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Médicaments', '0', Icons.medication_outlined),
                ),
                Expanded(
                  child: _buildStatItem('Commandes', '0', Icons.shopping_cart_outlined),
                ),
                Expanded(
                  child: _buildStatItem('Clients', '0', Icons.people_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildActionsCard(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildActionTile(
            Icons.store_outlined,
            'Gérer ma pharmacie',
            () => _showComingSoon(context, 'Gestion de pharmacie'),
          ),
          _buildActionTile(
            Icons.inventory_2_outlined,
            'Gérer l\'inventaire',
            () => _showComingSoon(context, 'Gestion d\'inventaire'),
          ),
          _buildActionTile(
            Icons.analytics_outlined,
            'Rapports et statistiques',
            () => _showComingSoon(context, 'Rapports'),
          ),
          _buildActionTile(
            Icons.help_outline,
            'Aide et support',
            () => _showComingSoon(context, 'Aide et support'),
          ),
          _buildActionTile(
            Icons.privacy_tip_outlined,
            'Politique de confidentialité',
            () => _showComingSoon(context, 'Politique de confidentialité'),
          ),
          _buildActionTile(
            Icons.info_outline,
            'À propos',
            () => _showAboutDialog(context),
          ),
          _buildActionTile(
            Icons.logout,
            'Se déconnecter',
            () => _showLogoutDialog(context, authProvider),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.teal),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).round();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).round();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible !'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HomePharma',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.local_pharmacy,
        size: 48,
        color: Colors.teal,
      ),
      children: [
        const Text(
          'HomePharma vous aide à gérer votre pharmacie et à servir vos clients efficacement.',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await authProvider.signOut();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Déconnecté avec succès'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );
  }
}