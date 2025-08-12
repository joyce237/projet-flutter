import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart'; // Pour la déconnexion
import 'location_service.dart'; // Service de localisation
import 'search_service.dart'; // Service de recherche

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  Position? _userPosition;
  List<Map<String, dynamic>> _searchResults = [];

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
      return;
    }
    
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'obtenir votre position. Veuillez activer la localisation.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.findMedication(
        _searchController.text.trim(),
        _userPosition!,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _errorMessage = "Une erreur est survenue lors de la recherche.";
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

  // Widget pour construire la liste de résultats
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

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pharmacy = _searchResults[index];
        final bool isOnDuty = pharmacy['onDuty'] ?? false;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 3,
          child: ListTile(
            leading: Icon(
              Icons.local_pharmacy,
              color: isOnDuty ? Colors.green : Colors.teal,
            ),
            title: Text(
              pharmacy['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pharmacy['address']),
                const SizedBox(height: 4),
                Text(
                  'Distance: ${pharmacy['distance'].toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                isOnDuty ? 'DE GARDE' : 'Horaires normaux',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: isOnDuty ? Colors.green : Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePharma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () async {
              await _authService.signOut();
              // L'AuthWrapper s'occupera de la redirection
            },
          ),
          // Vous pourriez ajouter ici un bouton vers le profil utilisateur
          // IconButton(icon: Icon(Icons.person), onPressed: () {}),
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
              onSubmitted: (_) => _performSearch(), // Pour lancer la recherche avec le clavier
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