import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapaSeleccionView extends StatefulWidget {
  const MapaSeleccionView({super.key});

  @override
  State<MapaSeleccionView> createState() => _MapaSeleccionViewState();
}

class _MapaSeleccionViewState extends State<MapaSeleccionView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _posicionSeleccionada = LatLng(-17.7833, -63.1821); // Santa Cruz

  Future<void> _buscarDireccion(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _posicionSeleccionada = LatLng(loc.latitude, loc.longitude);
        });
        _mapController.move(_posicionSeleccionada, 15);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la dirección')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _posicionSeleccionada,
              initialZoom: 13,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _posicionSeleccionada = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _posicionSeleccionada,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar dirección...',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _buscarDireccion(_searchController.text),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Usar esta ubicación'),
        icon: const Icon(Icons.check),
        onPressed: () => Navigator.pop(context, _posicionSeleccionada),
      ),
    );
  }
}
