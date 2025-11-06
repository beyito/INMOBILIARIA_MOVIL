import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// ✅ CAMBIO 1: Usa el servicio correcto
import 'package:movil_inmobiliaria/services/contrato/contrato_service_anti.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // ✅ CAMBIO 2: Importar 'open_filex'

// Importa el Badge de la página de lista
import 'contrato_anticretico_list_page.dart' show EstadoBadge; 

class ContratoAnticreticoDetailPage extends StatefulWidget {
  final String contratoId;
  const ContratoAnticreticoDetailPage({Key? key, required this.contratoId}) : super(key: key);
  @override
  _ContratoAnticreticoDetailPageState createState() => _ContratoAnticreticoDetailPageState();
}

class _ContratoAnticreticoDetailPageState extends State<ContratoAnticreticoDetailPage> {
  // Asegúrate que el nombre de la clase 'ContratoService' coincida con tu archivo
  final ContratoService _service = ContratoService(); 
  Map<String, dynamic>? _contrato;
  bool _isLoadingDetail = true;
  String? _loadingAction; // Para saber qué botón está cargando
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _fetchDetalle();
  }

  Future<void> _fetchDetalle() async {
    setState(() { _isLoadingDetail = true; _error = null; _success = null; });
    try {
      final data = await _service.getContratoDetalle(int.parse(widget.contratoId));
      setState(() { _contrato = data; _isLoadingDetail = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingDetail = false; });
    }
  }

  // --- Lógica de Acciones ---

  Future<void> _handleAprobar() async {
    setState(() { _loadingAction = 'aprobar'; _error = null; _success = null; });
    try {
      final data = await _service.aprobarContrato(_contrato!['id']);
      setState(() {
        _success = data['message'] ?? 'Contrato Aprobado';
        _contrato = data['contrato'] ?? _contrato; // Actualiza el contrato
      });
    } catch (e) { setState(() { _error = e.toString(); }); } 
    finally { setState(() { _loadingAction = null; }); }
  }
  
  Future<void> _handleFinalizar() async {
    setState(() { _loadingAction = 'finalizar'; _error = null; _success = null; });
    try {
      final data = await _service.finalizarContrato(_contrato!['id']);
      setState(() {
        _success = data['message'] ?? 'Contrato Finalizado';
        _contrato!['estado'] = 'finalizado'; // Actualiza estado localmente
      });
    } catch (e) { setState(() { _error = e.toString(); }); } 
    finally { setState(() { _loadingAction = null; }); }
  }

  // --- LÓGICA DE DESCARGA DE PDF ---
  Future<void> _handleDescargar() async {
    setState(() { _loadingAction = 'descargar'; _error = null; _success = null; });
    try {
      // 1. Obtener los bytes del archivo desde el servicio
      final Uint8List bytes = await _service.descargarContratoPDF(_contrato!['id']);

      // 2. Obtener un directorio temporal para guardar el archivo
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/contrato_anticretico_${_contrato!['id']}.pdf';

      // 3. Escribir los bytes en un archivo
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // ✅ CAMBIO 3: Usar 'OpenFilex.open'
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        setState(() { _success = 'Archivo abierto para visualización.'; });
      } else {
        throw Exception('No se pudo abrir el PDF: ${result.message}');
      }

    } catch (e) { 
      setState(() { _error = e.toString(); }); 
    } finally { 
      setState(() { _loadingAction = null; }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto de tu código 'build' no cambia) ...
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle Contrato #${widget.contratoId}"),
      ),
      body: _buildContenido(),
    );
  }

  Widget _buildContenido() {
    if (_isLoadingDetail) return const Center(child: CircularProgressIndicator());
    if (_error != null && _contrato == null) return Center(child: Text("Error: $_error"));
    if (_contrato == null) return const Center(child: Text("No se encontró el contrato."));

    final c = _contrato!;
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Mensajes de Alerta
        if (_error != null) 
          AlertMessage(tipo: 'error', mensaje: _error!),
        if (_success != null) 
          AlertMessage(tipo: 'success', mensaje: _success!),
        
        // Tarjeta de Detalles
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Cabecera de la Tarjeta
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "ID: ${c['id']}",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    EstadoBadge(estado: c['estado'] ?? 'desconocido'),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Cuerpo de la Tarjeta
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InfoItem(icon: LucideIcons.user, label: "Propietario", value: "${c['parte_contratante_nombre']} (CI: ${c['parte_contratante_ci']})"),
                    InfoItem(icon: LucideIcons.user, label: "Anticresista", value: "${c['parte_contratada_nombre']} (CI: ${c['parte_contratada_ci']})"),
                    InfoItem(icon: LucideIcons.building, label: "Inmueble", value: c['inmueble_direccion'] ?? 'N/A'),
                    InfoItem(icon: LucideIcons.calendar, label: "Fecha Contrato", value: c['fecha_contrato'] ?? 'N/A'),
                    InfoItem(icon: LucideIcons.dollarSign, label: "Monto (USD)", value: "\$${double.tryParse(c['monto']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}", isHighlighted: true),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Acciones de la Tarjeta
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap( // Wrap para que los botones se ajusten en pantallas pequeñas
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (c['estado'] == 'pendiente')
                      ActionButton(
                        label: "Aprobar",
                        icon: LucideIcons.check,
                        color: Colors.green,
                        isLoading: _loadingAction == 'aprobar',
                        onPressed: _handleAprobar,
                      ),
                    if (c['estado'] == 'activo')
                      ActionButton(
                        label: "Finalizar",
                        icon: LucideIcons.x,
                        color: Colors.blue,
                        isLoading: _loadingAction == 'finalizar',
                        onPressed: _handleFinalizar,
                      ),
                    ActionButton(
                      label: "Descargar PDF",
                      icon: LucideIcons.fileDown,
                      color: Colors.grey.shade700,
                      isLoading: _loadingAction == 'descargar',
                      onPressed: _handleDescargar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Widgets de UI (no cambian) ---

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;
  const InfoItem({Key? key, required this.icon, required this.label, required this.value, this.isHighlighted = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value, 
                  style: isHighlighted
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                    : Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  const ActionButton({Key? key, required this.label, required this.icon, required this.color, required this.isLoading, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 16),
      label: Text(isLoading ? 'Procesando...' : label),
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class AlertMessage extends StatelessWidget {
  final String tipo;
  final String mensaje;
  const AlertMessage({Key? key, required this.tipo, required this.mensaje}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isError = tipo == 'error';
    final bgColor = isError ? Colors.red.shade100 : Colors.green.shade100;
    final iconColor = isError ? Colors.red.shade700 : Colors.green.shade700;
    final icon = isError ? LucideIcons.shieldAlert : LucideIcons.checkCircle2;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(mensaje)),
        ],
      ),
    );
  }
}