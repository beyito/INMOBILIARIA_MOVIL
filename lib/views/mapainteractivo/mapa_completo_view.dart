import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:movil_inmobiliaria/models/inmueble/inmueble_mapa_model.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';

class MapaCompletoView extends StatefulWidget {
  const MapaCompletoView({super.key});

  @override
  State<MapaCompletoView> createState() => _MapaCompletoViewState();
}

class _MapaCompletoViewState extends State<MapaCompletoView> {
  final InmuebleService _inmuebleService = InmuebleService();
  final MapController _mapController = MapController();
  
  List<InmuebleMapaModel> _inmuebles = [];
  bool _isLoading = true;
  
  // Estado del Mapa
  bool _isSatellite = false; // Para cambiar entre Satélite y Normal
  LatLng? _miUbicacion;
  List<LatLng> _puntosRuta = [];
  Map<String, String>? _infoRuta;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    await _cargarInmuebles();
    // Intentamos obtener ubicación, pero si falla no bloqueamos la app
    try {
      await _obtenerUbicacionActual();
    } catch (e) {
      print("Aviso: GPS no disponible al inicio");
    }
  }

  Future<void> _cargarInmuebles() async {
    try {
      final datos = await _inmuebleService.getPinesMapa();
      if(mounted) {
        setState(() {
          _inmuebles = datos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // 📍 LOGICA GPS MEJORADA Y ROBUSTA
  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si el servicio está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El GPS está desactivado')));
      return;
    }

    // 2. Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de ubicación denegado')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso denegado permanentemente. Habilítalo en ajustes.')));
      return;
    }

    // 3. Obtener posición (Con settings para evitar timeouts)
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10)
      );
      
      if(mounted) {
        setState(() {
          _miUbicacion = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_miUbicacion!, 15);
      }
    } catch (e) {
      print("Error obteniendo posición: $e");
    }
  }

  // 🗺️ RUTAS
  Future<void> _trazarRuta(LatLng destino) async {
    if (_miUbicacion == null) {
      await _obtenerUbicacionActual();
      if (_miUbicacion == null) return;
    }

    final start = "${_miUbicacion!.longitude},${_miUbicacion!.latitude}";
    final end = "${destino.longitude},${destino.latitude}";
    
    // API OSRM (Gratuita)
    final url = Uri.parse("https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        
        setState(() {
          _puntosRuta = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          _infoRuta = {
            "tiempo": "${(data['routes'][0]['duration'] / 60).round()} min",
            "distancia": "${(data['routes'][0]['distance'] / 1000).toStringAsFixed(1)} km"
          };
        });
      }
    } catch (e) {
      print("Error ruta: $e");
    }
  }

  // 🎨 MODAL DE DETALLE (Corregido enlace)
  void _mostrarDetalleInmueble(InmuebleMapaModel inmueble) {
    _trazarRuta(LatLng(inmueble.latitud, inmueble.longitud));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Foto y Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: inmueble.imagen != null 
                    ? Image.network(inmueble.imagen!, height: 150, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.home, size: 50)),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Chip(
                    label: Text(inmueble.tipoOperacion.toUpperCase()),
                    backgroundColor: _getColorPorTipo(inmueble.tipoOperacion),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
            
            // Info y Botones
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inmueble.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("${inmueble.precio} BOB", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar modal
                            // ✅ CORRECCIÓN: Navegación directa al detalle
                            context.push('/inmueble/${inmueble.id}'); 
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text("Ver Detalles"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _lanzarWazeOGoogle(inmueble.latitud, inmueble.longitud),
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: const Text("Ir Ahora", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => setState(() { _puntosRuta = []; _infoRuta = null; }));
  }

  Future<void> _lanzarWazeOGoogle(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (!await launchUrl(uri)) {
      await launchUrl(Uri.parse("http://maps.google.com/maps?daddr=$lat,$lng"));
    }
  }

  Color _getColorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'venta': return Colors.red;
      case 'alquiler': return Colors.blue;
      case 'anticretico': return Colors.green;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌍 CAPAS DE MAPA PROFESIONALES
    // 1. Satelital (Esri World Imagery - Gratuito y excelente calidad)
    const urlSatelite = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    // 2. Informativo (CartoDB Voyager - Limpio y moderno)
    const urlNormal = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-17.7833, -63.1821),
              initialZoom: 13.0,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              // Capa Base (Switchable)
              TileLayer(
                urlTemplate: _isSatellite ? urlSatelite : urlNormal,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.tuapp.inmobiliaria',
              ),
              
              // Capa de Ruta
              if (_puntosRuta.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _puntosRuta, strokeWidth: 6.0, color: Colors.blueAccent, borderColor: Colors.white, borderStrokeWidth: 3.0),
                  ],
                ),

              // Capa de Marcadores (Propiedades)
              MarkerLayer(
                markers: _inmuebles.map((inm) {
                  return Marker(
                    point: LatLng(inm.latitud, inm.longitud),
                    width: 50, height: 50,
                    child: GestureDetector(
                      onTap: () => _mostrarDetalleInmueble(inm),
                      child: _buildPinPersonalizado(_getColorPorTipo(inm.tipoOperacion)),
                    ),
                  );
                }).toList(),
              ),

              // Capa de Usuario
              if (_miUbicacion != null)
                MarkerLayer(
                  markers: [
                    Marker(point: _miUbicacion!, width: 60, height: 60, child: _buildUserPin()),
                  ],
                )
            ],
          ),

          // --- UI FLOTANTE ---

          // 1. Botón Atrás
          Positioned(top: 50, left: 16, child: _buildCircleBtn(Icons.arrow_back, () => context.pop())),

          // 2. Selector de Capas (Satelital / Normal)
          Positioned(
            top: 50, right: 16,
            child: _buildCircleBtn(
              _isSatellite ? Icons.map : Icons.satellite_alt, 
              () => setState(() => _isSatellite = !_isSatellite),
              color: _isSatellite ? Colors.blueAccent : Colors.white,
              iconColor: _isSatellite ? Colors.white : Colors.black
            ),
          ),

          // 3. LEYENDA INFORMATIVA (Abajo Izquierda)
          Positioned(
            bottom: 40, left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeyendaItem("Venta", Colors.red),
                  const SizedBox(height: 4),
                  _buildLeyendaItem("Alquiler", Colors.blue),
                  const SizedBox(height: 4),
                  _buildLeyendaItem("Anticrético", Colors.green),
                ],
              ),
            ),
          ),

          // 4. Botón GPS (Abajo Derecha)
          Positioned(
            bottom: 40, right: 16,
            child: FloatingActionButton(
              heroTag: 'btn_gps_mapa_grande',
              onPressed: _obtenerUbicacionActual,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
            ),
          ),

          // 5. Panel Info Ruta (Top Center)
          if (_infoRuta != null)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                  child: Text("${_infoRuta!['distancia']} • ${_infoRuta!['tiempo']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white, Color iconColor = Colors.black}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _buildLeyendaItem(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPinPersonalizado(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.location_on, color: Colors.white, size: 50), // Borde
        Icon(Icons.location_on, color: color, size: 42), // Color interno
      ],
    );
  }

  Widget _buildUserPin() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle)),
        Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
      ],
    );
  }
}