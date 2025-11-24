import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';
import 'package:movil_inmobiliaria/views/inmueble/detalle_inmueble_view.dart';

class InmuebleLoaderPage extends StatefulWidget {
  final int inmuebleId;
  const InmuebleLoaderPage({super.key, required this.inmuebleId});

  @override
  State<InmuebleLoaderPage> createState() => _InmuebleLoaderPageState();
}

class _InmuebleLoaderPageState extends State<InmuebleLoaderPage> {
  late Future<InmuebleModel> _futureInmueble;
  final InmuebleService _service = InmuebleService();

  @override
  void initState() {
    super.initState();
    _futureInmueble = _service.obtenerInmueblePorId(widget.inmuebleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<InmuebleModel>(
        future: _futureInmueble,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  const Text("Error al cargar inmueble"),
                  Text(snapshot.error.toString(), style: const TextStyle(fontSize: 12)),
                  ElevatedButton(
                    onPressed: () => setState(() {
                       _futureInmueble = _service.obtenerInmueblePorId(widget.inmuebleId);
                    }), 
                    child: const Text("Reintentar")
                  )
                ],
              ),
            );
          } else if (snapshot.hasData) {
            // ✅ AQUÍ ESTÁ LA MAGIA: Ya tenemos el objeto completo
            return DetalleInmuebleView(inmueble: snapshot.data!);
          } else {
            return const Center(child: Text("No se encontró el inmueble"));
          }
        },
      ),
    );
  }
}