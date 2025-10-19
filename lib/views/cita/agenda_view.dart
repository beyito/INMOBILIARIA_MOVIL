import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/cita/cita_service.dart';
import '../../models/cita/cita_model.dart';
import 'crear_cita_view.dart';
import 'reprogramar_cita_view.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final CitaService api = CitaService();
  DateTime focused = DateTime.now();
  late Future<List<CitaModel>> future;

  // Meses y días en español (sin usar locale)
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _mesesCorto = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  static const _diasCorto = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<CitaModel>> _load() {
    // Carga las citas del mes visible
    final monthStart = DateTime(focused.year, focused.month, 1);
    final monthEnd = DateTime(focused.year, focused.month + 1, 0);
    final f = DateFormat('yyyy-MM-dd'); // sin locale
    return api.listar(
      mias: true,
      desde: f.format(monthStart),
      hasta: f.format(monthEnd),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      focused = DateTime(focused.year, focused.month + delta, 1);
      future = _load();
    });
  }

  // Normaliza cualquier fecha del backend a 'yyyy-MM-dd'
  String _toDateKey(String raw) {
    if (raw.isEmpty) return '';
    final cut = raw.length >= 10 ? raw.substring(0, 10) : raw;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cut)) return cut;
    final dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('yyyy-MM-dd').format(dt) : cut;
  }

  // Agrupa citas por día
  Map<String, List<CitaModel>> _groupByDay(List<CitaModel> all) {
    final map = <String, List<CitaModel>>{};
    for (final c in all) {
      final key = _toDateKey(c.fechaCita);
      if (key.isEmpty) continue;
      map.putIfAbsent(key, () => []).add(c);
    }
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    }
    return map;
  }

  String _mesAnioEs(DateTime d) {
    final m = _meses[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  String _diaMesCortoEs(DateTime d) {
    final m = _mesesCorto[d.month - 1];
    return '${d.day} $m';
  }

  @override
  Widget build(BuildContext context) {
    final tituloMes = _mesAnioEs(focused);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final ok = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CrearCitaView()));
          if (ok == true) setState(() => future = _load());
        },
      ),
      body: FutureBuilder<List<CitaModel>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final all = snap.data ?? <CitaModel>[];
          final byDay = _groupByDay(all);
          final fKey = DateFormat('yyyy-MM-dd').format(focused);
          final delDia = byDay[fKey] ?? const <CitaModel>[];

          return Column(
            children: [
              // Header de mes con flechas
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          tituloMes,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),

              // Encabezado: días de la semana (español)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: List.generate(7, (i) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          _diasCorto[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Calendario mensual propio con puntos
              _MonthGrid(
                month: DateTime(focused.year, focused.month, 1),
                selected: focused,
                onSelect: (d) => setState(() => focused = d),
                hasEvents: (d) =>
                    byDay.containsKey(DateFormat('yyyy-MM-dd').format(d)),
              ),

              // Encabezado del día
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Citas de ${_diaMesCortoEs(focused)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Lista de citas del día
              Expanded(
                child: delDia.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes citas para este día',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: delDia.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = delDia[i];
                          return ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: Text(c.titulo),
                            subtitle: Text(
                              '${c.horaInicio} – ${c.horaFin}\n${c.clienteNombre ?? "Cliente"}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () async {
                                final ok = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReprogramarCitaView(cita: c),
                                  ),
                                );
                                if (ok == true)
                                  setState(() => future = _load());
                              },
                            ),
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Eliminar cita'),
                                  content: const Text(
                                    '¿Seguro que deseas eliminar esta cita?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await CitaService().eliminar(c.id);
                                setState(() => future = _load());
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Calendario mensual simple con puntos (sin usar locale)
/// ─────────────────────────────────────────────────────────
class _MonthGrid extends StatelessWidget {
  final DateTime month; // primer día del mes
  final DateTime selected; // día seleccionado
  final void Function(DateTime) onSelect;
  final bool Function(DateTime) hasEvents;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.hasEvents,
  });

  @override
  Widget build(BuildContext context) {
    final first = month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // weekday: 1=lun ... 7=dom; queremos 0..6 con lunes=0
    final startWeekday = (first.weekday + 6) % 7;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7.0).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (r) {
          return Row(
            children: List.generate(7, (c) {
              final idx = r * 7 + c;
              final dayNum = idx - startWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 42));
              }
              final date = DateTime(month.year, month.month, dayNum);
              final isSelected = DateUtils.isSameDay(date, selected);
              final event = hasEvents(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(date),
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.15)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (event)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
