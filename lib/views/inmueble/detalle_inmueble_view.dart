// views/detalle_inmueble_view.dart
import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/contacto/chat_model.dart';
import 'package:movil_inmobiliaria/models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/services/contacto/contacto_service.dart';
import 'package:movil_inmobiliaria/views/contacto/chat_detalle_view.dart';

// IMPORTACIÓN DEL MAPA
import 'package:movil_inmobiliaria/views/mapainteractivo/mapa_widget.dart';

class DetalleInmuebleView extends StatefulWidget {
  final InmuebleModel inmueble;
  const DetalleInmuebleView({super.key, required this.inmueble});

  @override
  State<DetalleInmuebleView> createState() => _DetalleInmuebleViewState();
}

class _DetalleInmuebleViewState extends State<DetalleInmuebleView> {
  final ContactoService _contactoService = ContactoService();
  bool _contactando = false;

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _contactarAgente() async {
    if (_contactando) return;

    setState(() => _contactando = true);

    try {
      final agenteId = widget.inmueble.agente;

      if (agenteId == null) {
        _mostrarSnackBar('No se puede contactar al agente', isError: true);
        return;
      }

      final resultado = await _contactoService.crearChat(agenteId);

      if (resultado['success'] == true) {
        final data = resultado['data'];
        bool existente =
            data['message'] == 'CHAT YA EXISTENTE ENTRE CLIENTE Y AGENTE';

        _navegarAlChat(ChatModel.fromJson(data['values']), existente);
      } else {
        _mostrarSnackBar(
          resultado['error'] ?? 'Error al contactar agente',
          isError: true,
        );
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _contactando = false);
      }
    }
  }

  void _navegarAlChat(ChatModel chat, bool existente) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetalleView(chat: chat)),
    );

    if (!existente) {
        // Solo mostrar aviso si es nuevo, opcional
       _mostrarSnackBar('Chat creado exitosamente');
    }
  }

  // Helper para parsear coordenadas de forma segura
  // Asumiendo que en tu modelo pueden ser double, String o null
  double? _parseCoordenada(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Obtener coordenadas seguras
    // Asegúrate de que InmuebleModel tenga los campos latitud y longitud
    // Si no los tiene, agrégalos a tu modelo.
    final double? lat = _parseCoordenada(widget.inmueble.latitud);
    final double? lng = _parseCoordenada(widget.inmueble.longitud);
    final bool tieneUbicacion = lat != null && lng != null && lat != 0 && lng != 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inmueble.titulo),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white, // Para que el texto e icono sean blancos
      ),
      body: ListView(
        children: [
          // Carrusel de fotos
          if (widget.inmueble.fotos?.isNotEmpty ?? false)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: widget.inmueble.fotos?.length ?? 0,
                itemBuilder: (context, index) {
                  final foto = widget.inmueble.fotos?[index];
                  return ClipRRect(
                    // borderRadius: BorderRadius.circular(8), // Quitamos borde para que pegue al borde pantalla
                    child: Image.network(
                      foto?.url ?? '', 
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, trace) => Container(
                        color: Colors.grey[300], 
                        child: const Icon(Icons.broken_image)
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Información del inmueble
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.inmueble.titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.inmueble.descripcion,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Divider(height: 30),
                
                // Detalles en filas
                _infoRow(
                  Icons.location_on,
                  '${widget.inmueble.direccion}, ${widget.inmueble.ciudad}',
                ),
                _infoRow(Icons.map, 'Zona: ${widget.inmueble.zona}'),
                _infoRow(
                  Icons.attach_money,
                  'Precio: \$${widget.inmueble.precio}',
                ),
                _infoRow(
                  Icons.bed,
                  'Dormitorios: ${widget.inmueble.dormitorios}',
                ),
                _infoRow(Icons.bathtub, 'Baños: ${widget.inmueble.banos}'),
                _infoRow(
                  Icons.category,
                  'Tipo: ${widget.inmueble.tipoInmueble?.nombre ?? "N/A"}',
                ),
                _infoRow(
                  Icons.sell,
                  'Operación: ${widget.inmueble.tipoOperacion}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ----------- SECCIÓN DEL MAPA -----------
          if (tieneUbicacion) ...[
            MapaWidget(
              latitud: lat!,
              longitud: lng!,
              altura: 300, // Altura ajustable
            ),
            const SizedBox(height: 20),
          ],
          // ----------------------------------------

          // Botón de Contactar Agente
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon( // Usar ElevatedButton.icon es más bonito
                onPressed: _contactando ? null : _contactarAgente,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: _contactando 
                    ? const SizedBox.shrink() 
                    : const Icon(Icons.chat, color: Colors.white),
                label: _contactando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Contactar Agente',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30), // Espacio extra al final
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}