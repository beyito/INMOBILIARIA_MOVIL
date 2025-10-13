// views/detalle_inmueble_view.dart
// views/detalle_inmueble_view.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/contacto/chat_model.dart';
import 'package:movil_inmobiliaria/models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/services/contacto/contacto_service.dart';
import 'package:movil_inmobiliaria/views/contacto/chat_detalle_view.dart';

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
      // Obtener el ID del agente del inmueble
      final agenteId = widget.inmueble.agente;

      if (agenteId == null) {
        _mostrarSnackBar('No se puede contactar al agente', isError: true);
        return;
      }

      // Crear el chat
      final resultado = await _contactoService.crearChat(agenteId);

      if (resultado['success'] == true) {
        final data = resultado['data'];
        bool existente = false;
        if (data['message'] == 'CHAT YA EXISTENTE ENTRE CLIENTE Y AGENTE') {
          existente = true;
        } else {
          existente = false;
        }

        // Opcional: Navegar al chat
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
    // Aquí puedes navegar a la pantalla de chat
    // Por ejemplo:
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetalleView(chat: chat)),
    );

    // Mientras tanto, mostrar un diálogo informativo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Creado'),
        content: !existente
            ? const Text(
                'El chat se ha creado exitosamente. Puedes empezar a conversar con el agente.',
              )
            : const Text(
                'Ya tienes un chat con este agente. Puedes continuar la conversación.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inmueble.titulo),
        backgroundColor: Colors.blueAccent,
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
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(foto?.url ?? '', fit: BoxFit.cover),
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
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
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

                const SizedBox(height: 20),

                // Botón de Contactar Agente
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _contactando ? null : _contactarAgente,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _contactando
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para mostrar íconos y texto
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
