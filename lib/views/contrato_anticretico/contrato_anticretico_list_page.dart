import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:movil_inmobiliaria/services/contrato/contrato_service_anti.dart';

class ContratoAnticreticoListPage extends StatefulWidget {
  const ContratoAnticreticoListPage({Key? key}) : super(key: key);
  @override
  _ContratoAnticreticoListPageState createState() => _ContratoAnticreticoListPageState();
}

class _ContratoAnticreticoListPageState extends State<ContratoAnticreticoListPage> {
  final ContratoService _service = ContratoService();
  List<dynamic> _contratos = [];
  List<dynamic> _contratosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarLista();
    _searchController.addListener(_filtrarLista);
  }

  Future<void> _cargarLista() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getListaContratosAnticretico();
      setState(() {
        _contratos = data;
        _contratosFiltrados = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filtrarLista() {
    final term = _searchController.text.toLowerCase();
    setState(() {
      _contratosFiltrados = _contratos.where((c) {
        return (c['id']?.toString() ?? '').contains(term) ||
               (c['propietario']?.toLowerCase() ?? '').contains(term) ||
               (c['anticresista']?.toLowerCase() ?? '').contains(term) ||
               (c['estado']?.toLowerCase() ?? '').contains(term);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión Anticrético"),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarLista,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Buscar por ID, nombre, estado...",
                  prefixIcon: Icon(LucideIcons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(LucideIcons.plusCircle),
        label: const Text("Crear Contrato"),
        onPressed: () {
          // Navega a la página de creación
          context.push('/crear-contrato-anticretico');
        },
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("Error: $_error"));
    if (_contratosFiltrados.isEmpty) {
      return Center(
        child: Text(_searchController.text.isEmpty
            ? "No hay contratos registrados."
            : "No se encontraron coincidencias."),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _contratosFiltrados.length,
      itemBuilder: (context, index) {
        final contrato = _contratosFiltrados[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text("ID: ${contrato['id']} - ${contrato['propietario']}"),
            subtitle: Text(contrato['anticresista'] ?? 'Sin anticresista'),
            trailing: EstadoBadge(estado: contrato['estado'] ?? 'desconocido'),
            onTap: () {
              // Navega a la página de detalle
              context.push('/contrato-anticretico-detalle/${contrato['id']}');
            },
          ),
        );
      },
    );
  }
}

// Widget de "Estado" (usado en la lista y detalle)
class EstadoBadge extends StatelessWidget {
  final String estado;
  const EstadoBadge({Key? key, required this.estado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colores = {
      'pendiente': Colors.yellow.shade700,
      'activo': Colors.green.shade700,
      'finalizado': Colors.blue.shade700,
      'cancelado': Colors.red.shade700,
    };
    final Map<String, Color> bgColores = {
      'pendiente': Colors.yellow.shade100,
      'activo': Colors.green.shade100,
      'finalizado': Colors.blue.shade100,
      'cancelado': Colors.red.shade100,
    };
    final color = colores[estado] ?? Colors.grey.shade700;
    final bgColor = bgColores[estado] ?? Colors.grey.shade100;

    return Chip(
      label: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: bgColor,
      padding: EdgeInsets.zero,
    );
  }
}