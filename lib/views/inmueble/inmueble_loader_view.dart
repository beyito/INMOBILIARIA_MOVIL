import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';
import 'package:movil_inmobiliaria/views/inmueble/detalle_inmueble_view.dart'; // Tu vista de detalle

class InmuebleLoaderView extends StatefulWidget {
  final int inmuebleId;

  const InmuebleLoaderView({super.key, required this.inmuebleId});

  @override
  State<InmuebleLoaderView> createState() => _InmuebleLoaderViewState();
}

class _InmuebleLoaderViewState extends State<InmuebleLoaderView> {
  final InmuebleService _inmuebleService = InmuebleService();
  
  // Variables de estado
  bool _isLoading = true;
  String? _errorMessage;
  InmuebleModel? _inmuebleCompleto;

  @override
  void initState() {
    super.initState();
    _cargarDetalleInmueble();
  }

  Future<void> _cargarDetalleInmueble() async {
    try {
      // Usamos el servicio que ya tienes configurado
      final inmueble = await _inmuebleService.obtenerInmueblePorId(widget.inmuebleId);
      
      if (mounted) {
        setState(() {
          _inmuebleCompleto = inmueble;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. ESTADO DE CARGA
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Cargando detalles del inmueble..."),
            ],
          ),
        ),
      );
    }

    // 2. ESTADO DE ERROR
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  "No se pudo cargar el inmueble",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _cargarDetalleInmueble();
                  },
                  child: const Text("Reintentar"),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 3. ESTADO DE ÉXITO (Aquí llamamos a TU vista)
    if (_inmuebleCompleto != null) {
      return DetalleInmuebleView(inmueble: _inmuebleCompleto!);
    }

    return const Scaffold(body: Center(child: Text("Inmueble no encontrado")));
  }
}