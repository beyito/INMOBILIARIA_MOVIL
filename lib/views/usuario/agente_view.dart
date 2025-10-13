// views/agente/agente_view.dart
import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/contacto/chat_model.dart';
import 'package:movil_inmobiliaria/services/usuario/agente_service.dart';
import 'package:movil_inmobiliaria/models/usuario/usuario_model.dart';
import 'package:movil_inmobiliaria/services/contacto/contacto_service.dart';
import 'package:movil_inmobiliaria/views/contacto/chat_detalle_view.dart';

class AgenteView extends StatefulWidget {
  const AgenteView({super.key});

  @override
  State<AgenteView> createState() => _AgenteViewState();
}

class _AgenteViewState extends State<AgenteView> {
  final AgenteService _agenteService = AgenteService();
  List<UsuarioModel> agentes = [];
  bool cargando = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _cargarAgentes();
  }

  Future<void> _cargarAgentes() async {
    try {
      final lista = await _agenteService.obtenerAgentes();
      if (mounted) {
        setState(() {
          agentes = lista;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error al cargar agentes: $e';
          cargando = false;
        });
      }
    }
  }

  void _mostrarDetalleAgente(UsuarioModel agente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildDetalleAgente(agente),
    );
  }

  Widget _buildDetalleAgente(UsuarioModel agente) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con foto y nombre
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  agente.nombre ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${agente.username}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Información de contacto
          _buildInfoItem('Correo electrónico', agente.correo, Icons.email),
          _buildInfoItem('Teléfono', agente.telefono, Icons.phone),
          _buildInfoItem('Cédula de identidad', agente.ci, Icons.badge),
          _buildInfoItem('Ubicación', agente.ubicacion, Icons.location_on),

          if (agente.fecha_nacimiento != null)
            _buildInfoItem(
              'Fecha de nacimiento',
              _formatearFecha(agente.fecha_nacimiento!),
              Icons.cake,
            ),

          const SizedBox(height: 20),

          // Botón de contacto
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar bottom sheet
                _contactarAgente(agente);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Contactar Agente',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String titulo, String? valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor ?? 'No especificado',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  void _contactarAgente(UsuarioModel agente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar Agente'),
        content: Text('¿Deseas contactar a ${agente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _crearChatConAgente(agente);
            },
            child: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearChatConAgente(UsuarioModel agente) async {
    // Evitar múltiples taps

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Creando chat...'),
          ],
        ),
        duration: Duration(seconds: 30), // Largo para que no desaparezca rápido
      ),
    );

    try {
      // Crear el chat usando el ID del agente
      final resultado = await ContactoService().crearChat(agente.id!);

      // Ocultar el snackbar de carga
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (resultado['success'] == true) {
        final data = resultado['data'];
        final bool existente =
            data['message'] == 'CHAT YA EXISTENTE ENTRE CLIENTE Y AGENTE';

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existente
                  ? 'Ya tienes un chat con ${agente.nombre}'
                  : 'Chat creado con ${agente.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al chat si tienes la vista de chat
        if (existente || data['values'] != null) {
          _navegarAlChat(ChatModel.fromJson(data['values']));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Error al contactar agente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navegarAlChat(ChatModel chat) {
    // Si tienes una vista de chat, navega a ella
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetalleView(chat: chat)),
    );

    // Por ahora, solo mostrar mensaje
    print('Navegar al chat ID: ${chat.id} con ${chat.agente.nombre}');

    // O mostrar un diálogo informativo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Listo'),
        content: Text(
          'Puedes encontrar tu chat con ${chat.agente.nombre} en la sección de chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a la lista de chats
              // context.go('/chats');
            },
            child: const Text('Ir a Chats'),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaAgente(UsuarioModel agente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          agente.nombre ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${agente.username}'),
            if (agente.ubicacion?.isNotEmpty ?? false)
              Text(
                agente.ubicacion!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _mostrarDetalleAgente(agente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestros Agentes'),
        backgroundColor: Colors.blueAccent,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarAgentes,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : agentes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay agentes disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarAgentes,
              child: ListView.builder(
                itemCount: agentes.length,
                itemBuilder: (context, index) {
                  final agente = agentes[index];
                  return _buildTarjetaAgente(agente);
                },
              ),
            ),
    );
  }
}
