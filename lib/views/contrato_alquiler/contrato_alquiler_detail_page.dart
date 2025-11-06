// lib/views/contrato_alquiler/contrato_alquiler_detail_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:movil_inmobiliaria/services/contrato/contrato_alquiler_service.dart';

class ContratoAlquilerDetailPage extends StatefulWidget {
  final int contratoId;
  const ContratoAlquilerDetailPage({super.key, required this.contratoId});

  @override
  State<ContratoAlquilerDetailPage> createState() => _ContratoAlquilerDetailPageState();
}

class _ContratoAlquilerDetailPageState extends State<ContratoAlquilerDetailPage> {
  final _service = ContratoAlquilerService();
  bool _loading = true;
  String? _error;
  String? _pdfPath; // guardamos el path local del PDF descargado

  @override
  void initState() {
    super.initState();
    _fetchPdf();
  }

  Future<void> _fetchPdf() async {
    setState(() { _loading = true; _error = null; });
    try {
      final Uint8List bytes = await _service.obtenerContratoPdf(widget.contratoId);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/contrato_alquiler_${widget.contratoId}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      setState(() { _pdfPath = filePath; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _abrir() async {
    if (_pdfPath == null) return;
    final result = await OpenFilex.open(_pdfPath!);
    if (result.type.name != 'done') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el PDF: ${result.message ?? 'desconocido'}')),
      );
    }
  }

  Future<void> _descargar() async {
    // En móvil ya lo tenemos guardado en _pdfPath. Podrías moverlo a Downloads si quieres.
    if (_pdfPath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archivo guardado en temporal.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.contratoId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Contrato de Alquiler #$id'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Descargar PDF',
            onPressed: _pdfPath != null ? _descargar : null,
            icon: const Icon(LucideIcons.fileDown),
          ),
          IconButton(
            tooltip: 'Abrir PDF',
            onPressed: _pdfPath != null ? _abrir : null,
            icon: const Icon(LucideIcons.fileText),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _pdfPath == null
                  ? const Center(child: Text('No se encontró el contrato.'))
                  : _PreviewHint(path: _pdfPath!),
    );
  }
}

/// Nota: renderizar PDF embebido requiere plugins extra.
/// Aquí mostramos un “hint” y usamos abrir/descargar con open_filex.
class _PreviewHint extends StatelessWidget {
  final String path;
  const _PreviewHint({required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 48),
          const SizedBox(height: 12),
          Text('PDF descargado en:\n$path', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Usa el botón “Abrir PDF” del AppBar para visualizar.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
