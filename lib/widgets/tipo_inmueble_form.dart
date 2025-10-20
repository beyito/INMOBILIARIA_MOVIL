// lib/widgets/tipo_inmueble_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tipoinmueble/tipo_inmueble_model.dart';
import '../provider/tipo_inmueble_provider.dart';

class TipoInmuebleForm extends StatefulWidget {
  final TipoInmueble? initial;

  const TipoInmuebleForm({super.key, this.initial});

  @override
  State<TipoInmuebleForm> createState() => _TipoInmuebleFormState();
}

class _TipoInmuebleFormState extends State<TipoInmuebleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initial?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.initial?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<TipoInmuebleProvider>().crearOActualizar(
        tipo: widget.initial,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
      );
      // Si todo sale bien, cerramos el modal
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Mostrar un error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding para que el teclado no tape el formulario
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'Nuevo Tipo' : 'Editar Tipo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  child: Text(_isSaving ? 'Guardando…' : 'Guardar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}