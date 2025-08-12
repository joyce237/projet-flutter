import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'location_service.dart'; // Service de localisation
import 'search_service.dart'; // Service de recherche
import 'search_result_model.dart';
import 'search_result_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();

  bool _isLoading = false;
  String? _errorMessage;
  Position? _userPosition;
  List<PharmacySearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Étape 1: Obtenir la position de l'utilisateur au démarrage de l'écran
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Étape 2: Lancer la recherche lorsque l'utilisateur appuie sur le bouton
  Future<void> _performSearch() async {
    // Cacher le clavier
    FocusScope.of(context).unfocus();

    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom d\'un médicament'),
        ),
      );
      return;
    }

    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'obtenir votre position. Veuillez activer la localisation.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = []; // Réinitialiser les résultats précédents
    });

    try {
      // Test de la connexion Firestore
      bool isConnected = await _searchService.testFirestoreConnection();
      if (!isConnected) {
        throw Exception('Impossible de se connecter à la base de données');
      }

      final results = await _searchService.findMedication(
        _searchController.text.trim(),
        _userPosition!,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          if (results.isEmpty) {
            _errorMessage =
                "Aucune pharmacie ne dispose de ce médicament en stock.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de recherche: ${e.toString()}";
        });
      }
      // Debug: Afficher l'erreur dans la console
      print('Erreur lors de la recherche: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget pour construire la liste de résultats ou naviguer vers l'écran de résultats
  Widget _buildResultsList() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          "Entrez le nom d'un médicament pour lancer la recherche.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Si on a des résultats, on affiche un résumé et un bouton pour voir le détail
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_searchResults.length} pharmacie(s) trouvée(s)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La plus proche se trouve à ${_searchResults.first.distanceText}',
                style: TextStyle(color: Colors.teal.shade600),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultScreen(
                        pharmacies: _searchResults,
                        userPosition: _userPosition!,
                        medicationName: _searchController.text.trim(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Voir les résultats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Aperçu rapide des 3 premiers résultats
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length > 3 ? 3 : _searchResults.length,
            itemBuilder: (context, index) {
              final pharmacy = _searchResults[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.local_pharmacy,
                    color: pharmacy.onDuty ? Colors.green : Colors.teal,
                  ),
                  title: Text(
                    pharmacy.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.address),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ${pharmacy.distanceText}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pharmacy.onDuty ? Colors.green : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pharmacy.statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultScreen(
                          pharmacies: _searchResults,
                          userPosition: _userPosition!,
                          medicationName: _searchController.text.trim(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePharma'),
        actions: [
          // Bouton panier avec badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: "Panier",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Profil",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () async {
              // Afficher une confirmation
              bool shouldLogout =
                  await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Déconnecter'),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              if (shouldLogout) {
                try {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.signOut();

                  if (mounted) {
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Chercher un médicament...',
                hintText: 'Ex: Paracétamol',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) =>
                  _performSearch(), // Pour lancer la recherche avec le clavier
            ),
            const SizedBox(height: 20),

            // Corps de la page : indicateur de chargement ou liste de résultats
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }
}
