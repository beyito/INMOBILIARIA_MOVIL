// lib/views/reportes/reportes_page.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';

import 'package:movil_inmobiliaria/services/reportes/reportes_service.dart';

// === Constantes del formulario (las mismas que ya usabas) ===
const List<Map<String, String>> TIPOS_REPORTE = [
  {"v": "inmuebles", "label": "Inmuebles"},
  {"v": "contratos", "label": "Contratos"},
  {"v": "citas", "label": "Citas"},
  {"v": "anuncios", "label": "Anuncios"},
  {"v": "agentes", "label": "Agentes"},
  {"v": "clientes", "label": "Clientes"},
];

const Map<String, List<Map<String, String>>> ESTADO_OPTIONS = {
  "inmuebles": [
    {"v": "aprobado", "label": "Aprobado"},
    {"v": "pendiente", "label": "Pendiente"},
    {"v": "rechazado", "label": "Rechazado"},
  ],
  "contratos": [
    {"v": "activo", "label": "Activo"},
    {"v": "pendiente", "label": "Pendiente"},
    {"v": "finalizado", "label": "Finalizado"},
    {"v": "cancelado", "label": "Cancelado"},
  ],
  "citas": [], "anuncios": [], "agentes": [], "clientes": [],
};

// Enum de modo
enum ReportMode { ia, rapido }

class ReportesPage extends StatefulWidget {
  const ReportesPage({Key? key}) : super(key: key);
  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  // --- Estado principal ---
  ReportMode _mode = ReportMode.ia;
  bool _isLoading = false;
  String? _error;

  // --- Resultados ---
  List<dynamic> _rows = [];
  List<String> _columns = [];

  // --- API ---
  final ReportesService _reportesService = ReportesService();

  // --- Modo rápido ---
  String _tipoRapido = "inmuebles";
  String? _estadoRapido;
  final _ciudadController = TextEditingController();

  // --- Modo IA ---
  final _promptController = TextEditingController();

  // ================== Exportar PDF ==================
  Future<void> _exportarPdf() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero genera un reporte')),
      );
      return;
    }

    final prompt = _mode == ReportMode.ia
        ? (_promptController.text.trim().isEmpty
            ? 'Reporte IA'
            : _promptController.text.trim())
        : 'Reporte Rápido de $_tipoRapido';

    setState(() => _isLoading = true);
    try {
      final path = await _reportesService.exportarReportePdf(
        data: _rows,
        prompt: prompt,
      );

      final r = await OpenFilex.open(path);
      if (r.type.name != 'done') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descargado en: $path (no se pudo abrir: ${r.message})')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================== IA ==================
  Future<void> _runReporteIA() async {
    if (_promptController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _error = null; _rows = []; _columns = []; });
    try {
      final data = await _reportesService.generarReporteIA(_promptController.text.trim());
      _actualizarResultados(data);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ================== Rápido ==================
  Future<void> _runReporteRapido() async {
    FocusScope.of(context).unfocus();
    final builderJson = {
      "tipo": _tipoRapido,
      "filtros": {
        "estado": _estadoRapido ?? "",
        "ciudad": _ciudadController.text.trim(),
        "fechaDesde": "",
        "fechaHasta": "",
        "montoOp": "gte",
        "montoValor": "",
      },
    };
    setState(() { _isLoading = true; _error = null; _rows = []; _columns = []; });
    try {
      final data = await _reportesService.generarReporteDirecto(builderJson);
      _actualizarResultados(data);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _actualizarResultados(List<dynamic> data) {
    setState(() {
      _rows = data;
      if (data.isNotEmpty && data[0] is Map) {
        _columns = (data[0] as Map<String, dynamic>).keys.toList();
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exportBtn = IconButton(
      tooltip: 'Exportar PDF',
      onPressed: _isLoading ? null : _exportarPdf,
      icon: const Icon(LucideIcons.download),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Módulo de Reportes"),
        actions: [exportBtn], // ← botón de exportar en AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Selector de modo
          Center(
            child: SegmentedButton<ReportMode>(
              segments: const [
                ButtonSegment(value: ReportMode.ia, label: Text("Modo IA"), icon: Icon(LucideIcons.brainCircuit)),
                ButtonSegment(value: ReportMode.rapido, label: Text("Filtros"), icon: Icon(LucideIcons.filter)),
              ],
              selected: {_mode},
              onSelectionChanged: (sel) {
                setState(() {
                  _mode = sel.first;
                  _error = null; _rows = []; _columns = [];
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Formularios
          if (_mode == ReportMode.ia)
            _buildModoIAForm()
          else
            _buildModoRapidoForm(),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Text("Resultados", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _buildErrorWidget(_error!)
          else if (_rows.isEmpty)
            const Center(child: Text("No hay datos. Genere un reporte."))
          else
            _buildReporteTabla(),

          const SizedBox(height: 24),
          // Botón grande alternativo (por si prefieres además de AppBar)
          // ElevatedButton.icon(
          //   onPressed: _isLoading || _rows.isEmpty ? null : _exportarPdf,
          //   icon: const Icon(LucideIcons.download),
          //   label: const Text('Exportar PDF'),
          // ),
        ],
      ),
    );
  }

  // ======== UI helpers ========

  Widget _buildModoIAForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: "Escribe tu solicitud",
                hintText: "Ej: Inmuebles aprobados en Santa Cruz...",
                border: OutlineInputBorder(),
                icon: Icon(LucideIcons.search),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text("Generar Reporte IA"),
              onPressed: _runReporteIA,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModoRapidoForm() {
    final estados = ESTADO_OPTIONS[_tipoRapido] ?? [];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _tipoRapido,
              decoration: const InputDecoration(
                labelText: "Tipo de Reporte",
                border: OutlineInputBorder(),
              ),
              items: TIPOS_REPORTE
                  .map((opt) => DropdownMenuItem(
                        value: opt["v"],
                        child: Text(opt["label"]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                if (v != null) {
                  _tipoRapido = v;
                  _estadoRapido = null;
                }
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _estadoRapido,
              decoration: InputDecoration(
                labelText: "Estado",
                border: const OutlineInputBorder(),
                enabled: estados.isNotEmpty,
              ),
              hint: const Text("Todos"),
              items: estados
                  .map((opt) => DropdownMenuItem(
                        value: opt["v"],
                        child: Text(opt["label"]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _estadoRapido = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ciudadController,
              decoration: const InputDecoration(
                labelText: "Ciudad (Opcional)",
                hintText: "Ej: Santa Cruz",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text("Generar Reporte"),
              onPressed: _runReporteRapido,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteTabla() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          columns: _columns
              .map((c) => DataColumn(
                    label: Text(
                      c.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: _rows
              .map((row) => DataRow(
                    cells: _columns
                        .map((c) => DataCell(Text((row as Map)[c]?.toString() ?? '—')))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, color: Colors.red),
          const SizedBox(width: 8),
          Flexible(child: Text(error)),
        ],
      ),
    );
  }
}
