import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'search_result_model.dart';

class SearchResultScreen extends StatefulWidget {
  final List<PharmacySearchResult> pharmacies;
  final Position userPosition;
  final String medicationName;

  const SearchResultScreen({
    super.key,
    required this.pharmacies,
    required this.userPosition,
    required this.medicationName,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats pour "${widget.medicationName}"'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Liste'),
            Tab(icon: Icon(Icons.map), text: 'Carte'),
          ],
        ),
      ),
      body: widget.pharmacies.isEmpty
          ? _buildEmptyState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(),
                _buildMapView(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune pharmacie trouvée',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le médicament "${widget.medicationName}" n\'est pas disponible dans les pharmacies proches.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = widget.pharmacies[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: pharmacy.onDuty ? Colors.green : Colors.teal,
              child: Icon(
                Icons.local_pharmacy,
                color: Colors.white,
              ),
            ),
            title: Text(
              pharmacy.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  pharmacy.address,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      pharmacy.distanceText,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.inventory, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(pharmacy.stockText),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pharmacy.onDuty ? Colors.green : Colors.blueGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pharmacy.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showPharmacyDetails(pharmacy),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          widget.userPosition.latitude,
          widget.userPosition.longitude,
        ),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.homepharma.app',
        ),
        MarkerLayer(
          markers: [
            // Marqueur pour l'utilisateur
            Marker(
              point: LatLng(
                widget.userPosition.latitude,
                widget.userPosition.longitude,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Marqueurs pour les pharmacies
            ...widget.pharmacies.map((pharmacy) => Marker(
                  point: LatLng(pharmacy.latitude, pharmacy.longitude),
                  child: GestureDetector(
                    onTap: () => _showPharmacyDetails(pharmacy),
                    child: Container(
                      decoration: BoxDecoration(
                        color: pharmacy.onDuty ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }

  void _showPharmacyDetails(PharmacySearchResult pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: pharmacy.onDuty ? Colors.green : Colors.teal,
                  child: const Icon(Icons.local_pharmacy, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pharmacy.onDuty ? Colors.green : Colors.blueGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pharmacy.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.location_on, 'Adresse', pharmacy.address),
            _buildDetailRow(Icons.straighten, 'Distance', pharmacy.distanceText),
            _buildDetailRow(Icons.inventory, 'Stock disponible', pharmacy.stockText),
            if (pharmacy.phoneNumber != null)
              _buildDetailRow(Icons.phone, 'Téléphone', pharmacy.phoneNumber!),
            if (pharmacy.openingHours != null)
              _buildDetailRow(Icons.access_time, 'Horaires', pharmacy.openingHours!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implémenter la navigation vers la pharmacie
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigation non encore implémentée'),
                    ),
                  );
                },
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}