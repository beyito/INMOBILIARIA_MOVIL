// widgets/dialogo_progreso_subida.dart - CREAR este archivo
import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';

class DialogoProgresoSubida extends StatefulWidget {
  final Stream<ProgresoSubida>? streamProgreso;
  final String titulo;

  const DialogoProgresoSubida({
    super.key,
    this.streamProgreso,
    this.titulo = 'Registrando Inmueble',
  });

  @override
  State<DialogoProgresoSubida> createState() => _DialogoProgresoSubidaState();
}

class _DialogoProgresoSubidaState extends State<DialogoProgresoSubida> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              widget.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Stream de progreso
            StreamBuilder<ProgresoSubida>(
              stream: widget.streamProgreso,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildCargandoInicial();
                }

                final progreso = snapshot.data!;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Estado actual
                    Text(
                      progreso.estado,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    LinearProgressIndicator(
                      value: progreso.porcentaje,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),

                    // Porcentaje y contador
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progreso.porcentaje * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${progreso.completadas}/${progreso.total}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // Spinner adicional cuando está procesando
                    if (progreso.estado.contains('Procesando'))
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargandoInicial() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Iniciando proceso...'),
      ],
    );
  }
}
