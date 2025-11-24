import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapaWidget extends StatelessWidget {
  final double latitud;
  final double longitud;
  final double altura;

  const MapaWidget({
    super.key,
    required this.latitud,
    required this.longitud,
    this.altura = 300.0,
  });

  Future<void> _abrirMapaNativo() async {
    // Intenta abrir Google Maps / Waze / Apple Maps
    final Uri googleMapsUrl = Uri.parse(
        'google.navigation:q=$latitud,$longitud&mode=d');
    
    // Fallback para navegador web
    final Uri webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al abrir mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Ubicación",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: altura,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitud, longitud),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all, // Permite zoom y mover con dedos
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tuempresa.inmobiliaria',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitud, longitud),
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Botón flotante "Cómo llegar"
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.extended(
                    heroTag: 'btn_como_llegar_detalle', // Importante si hay otros FABs
                    onPressed: _abrirMapaNativo,
                    label: const Text('Cómo llegar'),
                    icon: const Icon(Icons.directions),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}