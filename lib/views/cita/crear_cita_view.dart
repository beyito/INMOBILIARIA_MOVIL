import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cita/cita_service.dart';

class CrearCitaView extends StatefulWidget {
  const CrearCitaView({super.key});

  @override
  State<CrearCitaView> createState() => _CrearCitaViewState();
}

class _CrearCitaViewState extends State<CrearCitaView> {
  final formKey = GlobalKey<FormState>();

  final data = <String, dynamic>{
    "titulo": "",
    "descripcion": "",
    "agente": null, // se setea con el usuario logueado
    "cliente": null, // ID manual
    "fecha_cita": "",
    "hora_inicio": "",
    "hora_fin": "",
    "inmueble_id": null,
    "ubicacion": "",
  };

  @override
  void initState() {
    super.initState();
    _initAgente();
  }

  Future<void> _initAgente() async {
    final prefs = await SharedPreferences.getInstance();
    data["agente"] = prefs.getInt('id');
    setState(() {});
  }

  // ───────── FECHA en español (sin locale, con calendario propio) ─────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = data["fecha_cita"].isEmpty
        ? now
        : DateTime.tryParse(data["fecha_cita"]) ?? now;

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DatePickerSheet(
        initialDate: initial,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
      ),
    );

    if (selected != null) {
      data["fecha_cita"] = DateFormat('yyyy-MM-dd').format(selected);
      setState(() {});
    }
  }

  // ───────── HORA 24h (evita 12 AM/PM -> 00:00) ─────────
  Future<void> _pickTime(String key) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: key == 'hora_inicio'
          ? 'Selecciona hora de inicio'
          : 'Selecciona hora de fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        // Fuerza formato 24 horas en el diálogo
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (t != null) {
      final hh = t.hour.toString().padLeft(2, '0'); // ya viene en 24h
      final mm = t.minute.toString().padLeft(2, '0');
      data[key] = '$hh:$mm:00';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = TextStyle(color: Colors.grey[600]);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Título'),
                onSaved: (v) => data['titulo'] = v?.trim(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (v) => data['descripcion'] = v?.trim(),
              ),

              const SizedBox(height: 8),
              Text('Fecha', style: subtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  data['fecha_cita'].isEmpty
                      ? 'Seleccionar fecha'
                      : data['fecha_cita'],
                ),
                onTap: _pickDate,
              ),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        data['hora_inicio'].isEmpty
                            ? 'Hora inicio'
                            : data['hora_inicio'],
                      ),
                      onTap: () => _pickTime('hora_inicio'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        data['hora_fin'].isEmpty
                            ? 'Hora fin'
                            : data['hora_fin'],
                      ),
                      onTap: () => _pickTime('hora_fin'),
                    ),
                  ),
                ],
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Cliente (ID)'),
                keyboardType: TextInputType.number,
                onSaved: (v) => data['cliente'] = int.tryParse(v ?? ''),
                validator: (v) => (v == null || int.tryParse(v) == null)
                    ? 'Ingresa un ID válido'
                    : null,
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Propiedad (ID opcional)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (v) => data['inmueble_id'] = (v == null || v.isEmpty)
                    ? null
                    : int.tryParse(v),
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                ),
                onSaved: (v) => data['ubicacion'] = v?.trim(),
              ),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();

                  // Validaciones mínimas antes de llamar al backend
                  if (data['fecha_cita'].isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona una fecha')),
                    );
                    return;
                  }
                  if (data['hora_inicio'].isEmpty || data['hora_fin'].isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona horas de inicio y fin'),
                      ),
                    );
                    return;
                  }
                  if (data['cliente'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa el ID de cliente')),
                    );
                    return;
                  }

                  final created = await CitaService().crear(data);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cita creada: ${created.titulo}')),
                  );
                  Navigator.of(context).pop(true);
                },
                child: const Text('Crear cita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Hoja inferior: Calendario en español SIN locale global
/// ─────────────────────────────────────────────────────────
class _DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _selected;
  late DateTime _visibleMonth;

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
  static const _diasCorto = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
        1,
      );
    });
  }

  bool _isDisabled(DateTime d) {
    return d.isBefore(
          DateTime(
            widget.firstDate.year,
            widget.firstDate.month,
            widget.firstDate.day,
          ),
        ) ||
        d.isAfter(
          DateTime(
            widget.lastDate.year,
            widget.lastDate.month,
            widget.lastDate.day,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final tituloMes =
        '${_meses[_visibleMonth.month - 1][0].toUpperCase()}${_meses[_visibleMonth.month - 1].substring(1)} ${_visibleMonth.year}';
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final startWeekday =
        (DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday + 6) %
        7; // lunes=0
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7.0).ceil();

    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con mes
              Row(
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

              // Días de la semana
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: List.generate(
                    7,
                    (i) => Expanded(
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
                    ),
                  ),
                ),
              ),

              // Grilla de días
              Column(
                children: List.generate(rows, (r) {
                  return Row(
                    children: List.generate(7, (c) {
                      final idx = r * 7 + c;
                      final dayNum = idx - startWeekday + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 44));
                      }
                      final date = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month,
                        dayNum,
                      );
                      final disabled = _isDisabled(date);
                      final isSelected = DateUtils.isSameDay(date, _selected);

                      return Expanded(
                        child: GestureDetector(
                          onTap: disabled
                              ? null
                              : () => setState(() => _selected = date),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(.15)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: disabled ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),

              const SizedBox(height: 12),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
