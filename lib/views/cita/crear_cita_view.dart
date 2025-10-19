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

  // ───────── FECHA en español (solo aquí) ─────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
      //locale: const Locale('es'), // 👈 textos del diálogo en español
      helpText: 'Selecciona la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (d != null) {
      data["fecha_cita"] = DateFormat('yyyy-MM-dd').format(d);
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
