// lib/views/contrato_alquiler/contrato_alquiler_form_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:movil_inmobiliaria/services/contrato/contrato_alquiler_service.dart';


class ContratoAlquilerFormPage extends StatefulWidget {
  const ContratoAlquilerFormPage({super.key});

  @override
  State<ContratoAlquilerFormPage> createState() => _ContratoAlquilerFormPageState();
}

class _ContratoAlquilerFormPageState extends State<ContratoAlquilerFormPage> {
  final _service = ContratoAlquilerService();
  final _formKey = GlobalKey<FormState>();

  // --- estado general
  bool _loading = false;

  // --- estado selección (como en web)
  int? _selectedInmuebleId;
  List<dynamic> _inmuebles = [];
  bool _loadingInmuebles = true;
  String? _errorSel;

  // --- datos del form
  final _formData = <String, dynamic>{
    'inmueble_id': null,
    'arrendatario_nombre': '',
    'arrendatario_ci': '',
    'arrendatario_domicilio': '',
    'monto': '',
    'garantia': '',
    'vigencia_meses': '12',
    'fecha_inicio': DateTime.now(),
    'fecha_fin': null,
    'ciudad': 'Santa Cruz',
  };

  @override
  void initState() {
    super.initState();
    _cargarInmuebles();
  }

  // ============= CARGA DE INMUEBLES (como en web) =============
  Future<void> _cargarInmuebles() async {
    setState(() {
      _loadingInmuebles = true;
      _errorSel = null;
    });
    try {
      final lista = await _service.listarInmueblesDisponiblesAlquiler();

      // “como en web”: solo por anuncio.disponible, sin importar tipo_op
      final disponibles = lista.where((i) {
        final estado = (i['anuncio']?['estado'] ?? '').toString().toLowerCase();
        return estado == 'disponible';
      }).toList();

      setState(() {
        _inmuebles = disponibles;
        _selectedInmuebleId = null; // nada preseleccionado
        _formData['inmueble_id'] = null;
      });
    } catch (e) {
      setState(() => _errorSel = 'No se pudo cargar inmuebles: $e');
    } finally {
      setState(() => _loadingInmuebles = false);
    }
  }

  // ======================= GENERAR ============================
  Future<void> _generar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
    });

    try {
      final payload = {
        'agente_id': await ContratoAlquilerService().leerAgenteIdOAsegurarlo(),
        'inmueble_id': _formData['inmueble_id'],
        'arrendatario_nombre': _formData['arrendatario_nombre'],
        'arrendatario_ci': _formData['arrendatario_ci'],
        'arrendatario_domicilio': _formData['arrendatario_domicilio'],
        'monto_alquiler': _formData['monto']?.toString(),
        'monto_garantia': (_formData['garantia'] ?? '0').toString(),
        'vigencia_meses': _formData['vigencia_meses']?.toString(),
        'fecha_inicio': _fmtDate(_formData['fecha_inicio']),
        'fecha_fin': _fmtDate(_formData['fecha_fin']),
        'ciudad': _formData['ciudad'],
      };

      final data = await _service.generarContratoAlquiler(payload);

      final pdfUrl = (data['values'] ?? {})['pdf_url'];
      if (pdfUrl is String && pdfUrl.isNotEmpty) {
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await _descargarYAbrirDesdeUrl(pdfUrl);
        }
        if (mounted) Navigator.pop(context);
        return;
      }

      throw Exception('La respuesta no contiene pdf_url');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==================== UTILIDADES ===========================
  Future<void> _descargarYAbrirDesdeUrl(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('No se pudo descargar el PDF ($url)');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/contrato_alquiler_generado.pdf');
    await file.writeAsBytes(res.bodyBytes);
    final r = await OpenFilex.open(file.path);
    if (r.type.name != 'done') {
      throw Exception('No se pudo abrir el PDF descargado: ${r.message}');
    }
  }

  Future<int> _leerAgenteId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('usuario');
    if (raw != null) {
      final m = jsonDecode(raw);
      if (m is Map && m['id'] != null) return (m['id'] as num).toInt();
    }
    throw Exception('No se pudo identificar al agente. Inicia sesión nuevamente.');
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  // ======================== UI ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Contrato de Alquiler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle(icon: LucideIcons.home, title: '1. Inmueble'),
              const SizedBox(height: 8),

              // ======= SELECTOR COMO EN WEB =======
              DropdownButtonFormField<int>(
                value: _selectedInmuebleId,
                isExpanded: true,
                items: _inmuebles.map((i) {
                  final id = (i['id'] as num).toInt();
                  final titulo = (i['titulo'] ?? 'Sin título').toString();
                  final ciudad = (i['ciudad'] ?? '').toString();
                  final precio = (i['precio'] ?? '').toString();
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text('$titulo — $ciudad (Bs. $precio)'),
                  );
                }).toList(),
                hint: Text(_loadingInmuebles ? 'Cargando…' : 'Seleccionar inmueble…'),
                onChanged: _loadingInmuebles
                    ? null
                    : (v) {
                        // ignore: avoid_print
                        print('✅ inmueble_id seleccionado = $v');
                        setState(() {
                          _selectedInmuebleId = v;
                          _formData['inmueble_id'] = v;
                        });
                      },
                validator: (v) => v == null ? 'Selecciona un inmueble' : null,
                decoration: const InputDecoration(
                  labelText: 'Inmueble Disponible',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorSel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorSel!, style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 16),

              // ======= RESTO DEL FORM =======
              _SectionTitle(icon: LucideIcons.user, title: '2. Datos del Arrendatario'),
              const SizedBox(height: 8),
              _TextField(
                label: 'Nombre Completo',
                onSaved: (v) => _formData['arrendatario_nombre'] = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              _TextField(
                label: 'Cédula de Identidad (CI)',
                onSaved: (v) => _formData['arrendatario_ci'] = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              _TextField(
                label: 'Domicilio del Arrendatario',
                onSaved: (v) => _formData['arrendatario_domicilio'] = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              _SectionTitle(icon: LucideIcons.fileDigit, title: '3. Condiciones'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TextField(
                      label: 'Monto de Alquiler (Bs)',
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _formData['monto'] = v?.trim() ?? '0',
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TextField(
                      label: 'Monto de Garantía (Bs)',
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _formData['garantia'] = (v == null || v.isEmpty) ? '0' : v.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionTitle(icon: LucideIcons.calendar, title: '4. Vigencia'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TextField(
                      label: 'Vigencia (meses)',
                      keyboardType: TextInputType.number,
                      initialValue: _formData['vigencia_meses'],
                      onSaved: (v) => _formData['vigencia_meses'] = v?.trim() ?? '12',
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Fecha Inicio',
                      initial: _formData['fecha_inicio'] as DateTime,
                      onSaved: (d) => _formData['fecha_inicio'] = d,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Fecha Fin',
                      initial: _formData['fecha_fin'],
                      onSaved: (d) => _formData['fecha_fin'] = d,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _TextField(
                label: 'Ciudad (lugar de firma)',
                initialValue: 'Santa Cruz',
                onSaved: (v) => _formData['ciudad'] = v?.trim() ?? 'Santa Cruz',
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _loading || _loadingInmuebles ? null : _generar,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.fileText),
                  label: Text(_loading ? 'Generando...' : 'Generar Contrato PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= widgets base =================
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final TextInputType? keyboardType;
  final FormFieldSetter<String>? onSaved;
  final String? Function(String?)? validator;

  const _TextField({
    required this.label,
    this.initialValue,
    this.keyboardType,
    this.onSaved,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '',
      ).copyWith(labelText: label),
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }
}

/// DatePicker como FormField que guarda su valor al hacer `FormState.save()`.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? initial;
  final FormFieldSetter<DateTime?> onSaved;

  const _DateField({required this.label, this.initial, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime?>(
      initialValue: initial,
      onSaved: onSaved,
      validator: (d) => d == null ? 'Selecciona fecha' : null,
      builder: (state) {
        Future<void> _pick() async {
          final now = DateTime.now();
          final base = state.value ?? now;
          final d = await showDatePicker(
            context: context,
            initialDate: base,
            firstDate: DateTime(2000),
            lastDate: DateTime(now.year + 5),
            locale: const Locale('es', 'BO'),
          );
          if (d != null) state.didChange(d);
        }

        final text = state.value == null
            ? ''
            : '${state.value!.day.toString().padLeft(2, '0')}/'
              '${state.value!.month.toString().padLeft(2, '0')}/'
              '${state.value!.year}';

        return InkWell(
          onTap: _pick,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              errorText: state.errorText,
            ),
            child: Text(text.isEmpty ? 'Seleccionar fecha' : text),
          ),
        );
      },
    );
  }
}
