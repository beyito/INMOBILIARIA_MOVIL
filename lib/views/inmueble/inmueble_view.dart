import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <--- 1. IMPORTANTE: Agregar esto
import '../../services/inmueble/inmueble_service.dart';
import '../../models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/views/inmueble/detalle_inmueble_view.dart';

class InmuebleView extends StatefulWidget {
  const InmuebleView({super.key});

  @override
  State<InmuebleView> createState() => _InmuebleViewState();
}

class _InmuebleViewState extends State<InmuebleView> {
  late Future<List<InmuebleModel>> futureInmuebles;

  @override
  void initState() {
    super.initState();
    futureInmuebles = InmuebleService().listarDisponibles();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Envolvemos todo en un Scaffold para poder usar el botón flotante
    return Scaffold(
      backgroundColor: Colors.white, // O el color de fondo que prefieras
      
      // 3. Aquí agregamos el botón que lleva al mapa
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/mapa-explorar'); // Navega a la ruta que creamos en router.dart
        },
        label: const Text(
          "Ver Mapa",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.map, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Lo pone abajo al centro

      // 4. El cuerpo sigue siendo tu FutureBuilder original
      body: FutureBuilder<List<InmuebleModel>>(
        future: futureInmuebles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final inmuebles = snapshot.data!;
          if (inmuebles.isEmpty) {
            return const Center(child: Text('No hay inmuebles disponibles'));
          }

          return ListView.builder(
            // Agregamos un padding al final para que el botón flotante no tape el último ítem
            padding: const EdgeInsets.only(bottom: 80), 
            itemCount: inmuebles.length,
            itemBuilder: (context, index) {
              final inmueble = inmuebles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Navegar a detalle completo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalleInmuebleView(inmueble: inmueble),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen principal
                      if (inmueble.fotos?.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            inmueble.fotos?.first.url ?? '',
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            // Agregamos manejo de error de imagen por si acaso
                            errorBuilder: (ctx, err, _) => Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.home, size: 60),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inmueble.titulo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              inmueble.direccion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Precio: ${inmueble.precio}', // Podrías agregar el símbolo de moneda si falta
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}