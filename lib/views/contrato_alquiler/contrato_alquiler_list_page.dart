// lib/views/contrato_alquiler/contrato_alquiler_list_page.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:movil_inmobiliaria/services/contrato/contrato_alquiler_service.dart';
import 'package:movil_inmobiliaria/views/contrato_alquiler/contrato_alquiler_detail_page.dart';
import 'package:movil_inmobiliaria/views/contrato_alquiler/contrato_alquiler_form_page.dart';

class ContratoAlquilerListPage extends StatefulWidget {
  const ContratoAlquilerListPage({super.key});

  @override
  State<ContratoAlquilerListPage> createState() => _ContratoAlquilerListPageState();
}

class _ContratoAlquilerListPageState extends State<ContratoAlquilerListPage> {
  final _service = ContratoAlquilerService();
  bool _loading = true;
  List<dynamic> _contratos = [];
  List<dynamic> _filtered = [];

  String _search = '';
  String _estado = 'todos';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; });
    try {
      final lista = await _service.listarContratosAlquiler();
      setState(() {
        _contratos = lista;
        _filtered = List.from(lista);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _applyFilters() {
    var r = _contratos.where((c) {
      final inmueble = (c['inmueble'] ?? {}) as Map<String, dynamic>;
      final titulo = (inmueble['titulo'] ?? '').toString().toLowerCase();
      final inquilino = ((c['inquilino'] ?? {})['nombre'] ?? '').toString().toLowerCase();
      final ciudad = (c['ciudad'] ?? '').toString().toLowerCase();
      final term = _search.toLowerCase();
      final matchesText = titulo.contains(term) || inquilino.contains(term) || ciudad.contains(term);
      final matchesEstado = _estado == 'todos' ? true : (c['estado'] == _estado);
      return matchesText && matchesEstado;
    }).toList();
    setState(() { _filtered = r; });
  }

  String _fmtFecha(dynamic iso) {
    if (iso == null || iso.toString().isEmpty) return '—';
    try {
      final d = DateTime.parse(iso.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos de Alquiler'),
        actions: [
          IconButton(
            tooltip: 'Nuevo Contrato',
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContratoAlquilerFormPage()));
              if (mounted) _fetch();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // búsqueda y filtro
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(LucideIcons.search),
                            hintText: 'Buscar por inmueble, inquilino o ciudad...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            _search = v;
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _estado,
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'activo', child: Text('Activos')),
                          DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() { _estado = v; });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No se encontraron contratos'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 1.2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final c = _filtered[i] as Map<String, dynamic>;
                              final inmueble = (c['inmueble'] ?? {}) as Map<String, dynamic>;
                              final titulo = inmueble['titulo'] ?? 'Sin título';
                              final direccion = inmueble['direccion'] ?? 'Sin dirección';
                              final estado = (c['estado'] ?? '').toString();
                              final monto = (c['monto'] ?? 0);
                              final inquilino = ((c['inquilino'] ?? {})['nombre'] ?? 'Sin inquilino').toString();
                              final fecha = _fmtFecha(c['fecha_contrato']);

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        gradient: LinearGradient(colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary.withOpacity(0.85),
                                        ]),
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('$titulo', maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(LucideIcons.mapPin, size: 16, color: Colors.white70),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text('$direccion', maxLines: 1, overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(color: Colors.white70)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: estado == 'activo' ? Colors.greenAccent : Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(estado.toUpperCase(),
                                                style: TextStyle(
                                                  color: estado == 'activo' ? Colors.green.shade900 : Colors.grey.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              _IconBadge(icon: LucideIcons.dollarSign),
                                              const SizedBox(width: 8),
                                              Text('Bs ${_fmtMonto(monto)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ]),
                                            const SizedBox(height: 8),
                                            Row(children: [
                                              _IconBadge(icon: LucideIcons.user),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(inquilino)),
                                            ]),
                                            const SizedBox(height: 8),
                                            Row(children: [
                                              _IconBadge(icon: LucideIcons.calendar),
                                              const SizedBox(width: 8),
                                              Text(fecha),
                                            ]),
                                            const Spacer(),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(LucideIcons.eye),
                                                label: const Text('Ver Contrato'),
                                                onPressed: () {
                                                  final id = (c['id'] as num).toInt();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ContratoAlquilerDetailPage(contratoId: id),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _fmtMonto(dynamic v) {
    try {
      final n = (v as num).toDouble();
      return n.toStringAsFixed(2);
    } catch (_) {
      return v?.toString() ?? '0.00';
    }
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}
