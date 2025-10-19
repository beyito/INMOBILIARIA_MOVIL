import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cita/cita_model.dart';
import '../../services/cita/cita_service.dart';

class ReprogramarCitaView extends StatefulWidget {
  final CitaModel cita;
  const ReprogramarCitaView({super.key, required this.cita});

  @override
  State<ReprogramarCitaView> createState() => _ReprogramarCitaViewState();
}

class _ReprogramarCitaViewState extends State<ReprogramarCitaView> {
  final formKey = GlobalKey<FormState>();
  late String fecha;
  late String hi;
  late String hf;

  @override
  void initState() {
    super.initState();
    fecha = widget.cita.fechaCita;
    hi = widget.cita.horaInicio;
    hf = widget.cita.horaFin;
  }

  Future<void> _pickDate() async {
    final parts = fecha.split('-').map((e) => int.parse(e)).toList();
    final initial = DateTime(parts[0], parts[1], parts[2]);
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
      initialDate: initial,
      //locale: const Locale('es'),
    );
    if (d != null) {
      fecha = DateFormat('yyyy-MM-dd').format(d);
      setState(() {});
    }
  }

  Future<void> _pickTime(String key) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      final v = '$hh:$mm:00';
      if (key == 'hi')
        hi = v;
      else
        hf = v;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = TextStyle(color: Colors.grey[600]);

    return Scaffold(
      appBar: AppBar(title: const Text('Reprogramar cita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              Text(
                widget.cita.titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('Fecha', style: subtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(fecha),
                onTap: _pickDate,
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(hi),
                      onTap: () => _pickTime('hi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(hf),
                      onTap: () => _pickTime('hf'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await CitaService().reprogramar(widget.cita.id, {
                    "fecha_cita": fecha,
                    "hora_inicio": hi,
                    "hora_fin": hf,
                  });
                  if (!mounted) return;
                  Navigator.of(context).pop(true);
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
