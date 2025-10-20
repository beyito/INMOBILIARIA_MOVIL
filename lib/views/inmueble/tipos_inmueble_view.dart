import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/tipoinmueble/tipo_inmueble_model.dart';
import '../../provider/tipo_inmueble_provider.dart';
import '../../widgets/tipo_inmueble_form.dart';

class TiposInmuebleView extends StatelessWidget {
  const TiposInmuebleView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TipoInmuebleProvider(),
      // El Builder crea un nuevo 'context' que está DEBAJO del Provider.
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Gestionar Tipos de Inmueble'),
              actions: [
                // Este Consumer usa el 'context' del Builder, que sí encuentra el Provider.
                Consumer<TipoInmuebleProvider>(
                  builder: (context, provider, child) {
                    return IconButton(
                      icon: const Icon(LucideIcons.refreshCw),
                      onPressed: provider.isLoading ? null : () => provider.fetchData(),
                      tooltip: 'Actualizar listado',
                    );
                  },
                ),
              ],
            ),
            body: const _TiposInmuebleBody(),
            floatingActionButton: FloatingActionButton.extended(
              // Este botón ahora también usa el 'context' correcto del Builder.
              onPressed: () => _showTipoFormModal(context),
              label: const Text('Nuevo Tipo'),
              icon: const Icon(LucideIcons.plus),
            ),
          );
        }
      ),
    );
  }
}

class _TiposInmuebleBody extends StatelessWidget {
  const _TiposInmuebleBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TipoInmuebleProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchData(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _StatCards(),
          const SizedBox(height: 16),
          _SearchBar(),
          const SizedBox(height: 8),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(provider.error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.tipos.isEmpty)
            const _EmptyState()
          else
            const _TiposTable(),
        ],
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TipoInmuebleProvider>();
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Total', value: provider.totalCount.toString())),
        const SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Activos', value: provider.activosCount.toString(), color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: StatCard(label: 'Inactivos', value: provider.inactivosCount.toString(), color: Colors.grey)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<TipoInmuebleProvider>();
    return TextField(
      onChanged: (value) => provider.buscar(value),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o descripción...',
        prefixIcon: const Icon(LucideIcons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}

class _TiposTable extends StatelessWidget {
  const _TiposTable();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TipoInmuebleProvider>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final tipo in provider.tipos)
            ListTile(
              title: Text(tipo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tipo.descripcion ?? 'Sin descripción'),
              leading: Chip(
                label: Text(tipo.isActive ? 'Activo' : 'Inactivo'),
                backgroundColor: tipo.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                labelStyle: TextStyle(color: tipo.isActive ? Colors.green.shade800 : Colors.grey.shade700),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.pencil, color: const Color.fromARGB(255, 77, 138, 199)),
                    onPressed: () => _showTipoFormModal(context, tipo: tipo),
                  ),
                  if (tipo.isActive)
                    IconButton(
                      icon: Icon(LucideIcons.trash, color: Colors.red.shade700),
                      onPressed: () => _confirmAndExecute(
                        context,
                        '¿Desactivar este tipo?',
                        () => provider.eliminar(tipo.id),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(LucideIcons.power, color: Colors.green.shade700),
                      onPressed: () => provider.activar(tipo.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Icon(LucideIcons.building2, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text('Sin resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Crea un tipo de inmueble o ajusta tu búsqueda.', style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

void _showTipoFormModal(BuildContext context, {TipoInmueble? tipo}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return ChangeNotifierProvider.value(
        value: context.read<TipoInmuebleProvider>(),
        child: TipoInmuebleForm(initial: tipo),
      );
    },
  );
}

void _confirmAndExecute(BuildContext context, String title, Future<void> Function() action) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            action();
            Navigator.of(ctx).pop();
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}