import 'package:flutter/material.dart';
import 'search_service.dart';
import 'search_result_model.dart';
import 'package:geolocator/geolocator.dart';

class TestSearchScreen extends StatefulWidget {
  const TestSearchScreen({super.key});

  @override
  State<TestSearchScreen> createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends State<TestSearchScreen> {
  final SearchService _searchService = SearchService();
  bool _isLoading = false;
  String? _result;

  Future<void> _testSearch() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // Position de test (Douala, Cameroun)
      Position testPosition = Position(
        latitude: 4.048,
        longitude: 9.767,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      // Test de connexion
      bool isConnected = await _searchService.testFirestoreConnection();
      setState(() {
        _result = 'Connexion Firestore: ${isConnected ? 'OK' : 'Échec'}\n\n';
      });

      if (isConnected) {
        // Test de recherche
        List<PharmacySearchResult> results = await _searchService
            .findMedication('Paracétamol', testPosition);

        setState(() {
          _result = _result! + 'Résultats trouvés: ${results.length}\n';
          for (var pharmacy in results) {
            _result =
                _result! + '- ${pharmacy.name} (${pharmacy.distanceText})\n';
          }
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test de recherche')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testSearch,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Tester la recherche'),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _result!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
