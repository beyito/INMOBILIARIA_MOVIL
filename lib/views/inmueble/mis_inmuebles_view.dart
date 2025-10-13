// views/inmueble/mis_inmuebles_view.dart
import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';
import 'package:movil_inmobiliaria/models/inmueble/inmueble_model.dart';
import 'package:movil_inmobiliaria/views/inmueble/detalle_inmueble_view.dart';

class MisInmueblesView extends StatefulWidget {
  const MisInmueblesView({super.key});

  @override
  State<MisInmueblesView> createState() => _MisInmueblesViewState();
}

class _MisInmueblesViewState extends State<MisInmueblesView> {
  final InmuebleService _service = InmuebleService();
  List<InmuebleModel> _inmuebles = [];
  List<InmuebleModel> _inmueblesFiltrados = [];
  bool _cargando = true;
  String _error = '';
  String _filtroEstado = 'todos';
  String _filtroTipoOperacion = 'todos';
  String _filtroEstadoPublicado = 'todos';

  // Mapa para almacenar los estados de anuncio de cada inmueble
  final Map<int, String> _estadosAnuncio = {};
  @override
  void initState() {
    super.initState();
    _cargarMisInmuebles();
  }

  Future<void> _cargarMisInmuebles() async {
    try {
      setState(() => _cargando = true);
      final inmuebles = await _service.obtenerMisInmuebles(
        estado: _filtroEstado,
      );

      // Precargar estados de anuncio para cada inmueble
      if (_filtroEstado == 'publicados') {
        await _precargarEstadosAnuncio(inmuebles);
      }

      if (mounted) {
        setState(() {
          _inmuebles = inmuebles;
          _aplicarFiltros();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar inmuebles: $e';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _precargarEstadosAnuncio(List<InmuebleModel> inmuebles) async {
    for (var inmueble in inmuebles) {
      try {
        final estado = await _service.obtenerEstadoAnuncioDeInmueble(
          inmueble.id,
        );
        _estadosAnuncio[inmueble.id] = estado;
      } catch (e) {
        _estadosAnuncio[inmueble.id] = 'disponible'; // Valor por defecto
      }
    }
  }

  void _aplicarFiltros() {
    var resultado = _inmuebles;

    // Filtro por tipo de operación (siempre activo)
    if (_filtroTipoOperacion != 'todos') {
      resultado = resultado
          .where((i) => i.tipoOperacion == _filtroTipoOperacion)
          .toList();
    }

    // Filtro por estado de publicación (solo para publicados)
    if (_filtroEstado == 'publicados' && _filtroEstadoPublicado != 'todos') {
      resultado = resultado.where((i) {
        switch (_filtroEstadoPublicado) {
          case 'eliminados':
            // Para eliminados, solo verificamos isActive = false del INMUEBLE
            return (_estadosAnuncio[i.id] ?? 'disponible') == 'eliminado';
          case 'disponible':
            // Para disponible, verificamos isActive = true Y estado del anuncio = disponible
            return i.isActive &&
                (_estadosAnuncio[i.id] ?? 'disponible') == 'disponible';
          case 'vendido':
            return i.isActive &&
                (_estadosAnuncio[i.id] ?? 'disponible') == 'vendido';
          case 'alquilado':
            return i.isActive &&
                (_estadosAnuncio[i.id] ?? 'disponible') == 'alquilado';
          case 'anticretico':
            return i.isActive &&
                (_estadosAnuncio[i.id] ?? 'disponible') == 'anticretico';
          default:
            return true;
        }
      }).toList();
    }

    _inmueblesFiltrados = resultado;
  }

  Future<void> _cambiarFiltroEstado(String nuevoEstado) async {
    setState(() {
      _filtroEstado = nuevoEstado;
      _filtroEstadoPublicado = 'todos';
      _cargando = true;
    });

    try {
      final inmuebles = await _service.obtenerMisInmuebles(estado: nuevoEstado);

      // Precargar estados de anuncio si estamos en publicados
      if (nuevoEstado == 'publicados') {
        await _precargarEstadosAnuncio(inmuebles);
      }

      if (mounted) {
        setState(() {
          _inmuebles = inmuebles;
          _aplicarFiltros();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar inmuebles: $e';
          _cargando = false;
        });
      }
    }
  }

  void _cambiarFiltroTipoOperacion(String nuevoTipo) {
    setState(() {
      _filtroTipoOperacion = nuevoTipo;
      _aplicarFiltros();
    });
  }

  void _cambiarFiltroEstadoPublicado(String nuevoEstado) {
    setState(() {
      _filtroEstadoPublicado = nuevoEstado;
      _aplicarFiltros();
    });
  }

  // ========== ACCIONES ==========
  Future<void> _publicarInmueble(InmuebleModel inmueble) async {
    try {
      final success = await _service.publicarInmueble(inmueble.id);

      if (success && mounted) {
        _mostrarMensaje('"${inmueble.titulo}" publicado exitosamente', false);
        await _cambiarFiltroEstado(_filtroEstado);
      } else {
        _mostrarMensaje('Error al publicar el inmueble', true);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', true);
    }
  }

  Future<void> _cambiarEstadoAnuncio(
    InmuebleModel inmueble,
    String nuevoEstado,
  ) async {
    try {
      final success = await _service.cambiarEstadoAnuncio(
        inmueble.id,
        nuevoEstado,
      );

      if (success && mounted) {
        // Actualizar el estado en el mapa local
        _estadosAnuncio[inmueble.id] = nuevoEstado;

        _mostrarMensaje(
          'Estado cambiado a "${_obtenerTextoEstadoPublicado(nuevoEstado)}"',
          false,
        );
        _aplicarFiltros(); // Reaplicar filtros
      } else {
        _mostrarMensaje('Error al cambiar estado', true);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', true);
    }
  }

  Future<void> _quitarPublicacion(InmuebleModel inmueble) async {
    try {
      final success = await _service.quitarPublicacion(inmueble.id);

      if (success && mounted) {
        _mostrarMensaje('Publicación quitada exitosamente', false);
        await _cambiarFiltroEstado(_filtroEstado);
      } else {
        _mostrarMensaje('Error al quitar publicación', true);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', true);
    }
  }

  Future<void> _reactivarPublicacion(InmuebleModel inmueble) async {
    try {
      final success = await _service.activarPublicacion(inmueble.id);

      if (success && mounted) {
        _mostrarMensaje('"${inmueble.titulo}" reactivado exitosamente', false);
        await _cambiarFiltroEstado(_filtroEstado);
      } else {
        _mostrarMensaje('Error al reactivar la publicación', true);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', true);
    }
  }

  void _mostrarMensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  // ========== DIÁLOGOS ==========
  void _mostrarDialogoPublicar(InmuebleModel inmueble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar Inmueble'),
        content: Text('¿Publicar "${inmueble.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _publicarInmueble(inmueble);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCambiarEstado(InmuebleModel inmueble) {
    final estadosPermitidos = [
      'disponible',
      'vendido',
      'alquilado',
      'anticretico',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Text('Selecciona nuevo estado para "${inmueble.titulo}":'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ...estadosPermitidos.map((estado) {
            return TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cambiarEstadoAnuncio(inmueble, estado);
              },
              child: Text(_obtenerTextoEstadoPublicado(estado)),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _mostrarDialogoQuitarPublicacion(InmuebleModel inmueble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Publicación'),
        content: Text('¿Quitar "${inmueble.titulo}" de las publicaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _quitarPublicacion(inmueble);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoReactivar(InmuebleModel inmueble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar Publicación'),
        content: Text('¿Reactivar "${inmueble.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reactivarPublicacion(inmueble);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  void _navegarADetalle(InmuebleModel inmueble) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleInmuebleView(inmueble: inmueble),
      ),
    );
  }

  // ========== WIDGETS DE UI ==========

  Widget _buildFiltrosEstado() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _service.obtenerEstadosDisponibles().map((estado) {
            final seleccionado = _filtroEstado == estado;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _service.obtenerIconoEstado(estado),
                      size: 16,
                      color: seleccionado
                          ? Colors.white
                          : _service.obtenerColorEstado(estado),
                    ),
                    const SizedBox(width: 6),
                    Text(_service.obtenerTextoEstado(estado)),
                  ],
                ),
                selected: seleccionado,
                onSelected: (_) => _cambiarFiltroEstado(estado),
                backgroundColor: Colors.grey[100],
                selectedColor: _service.obtenerColorEstado(estado),
                labelStyle: TextStyle(
                  color: seleccionado ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFiltrosTipoOperacion() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Operación:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ..._service.obtenerTiposOperacion().map((tipo) {
              final seleccionado = _filtroTipoOperacion == tipo;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_service.obtenerTextoTipoOperacion(tipo)),
                  selected: seleccionado,
                  onSelected: (_) => _cambiarFiltroTipoOperacion(tipo),
                  backgroundColor: seleccionado
                      ? Colors.blue[100]
                      : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: seleccionado ? Colors.blue[800] : Colors.grey[700],
                    fontWeight: seleccionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosEstadoPublicado() {
    final estadosPublicado = [
      'todos',
      'disponible',
      'vendido',
      'alquilado',
      'anticretico',
      'eliminados',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Estado Anuncio:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ),
            ...estadosPublicado.map((estado) {
              final seleccionado = _filtroEstadoPublicado == estado;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_obtenerTextoEstadoPublicado(estado)),
                  selected: seleccionado,
                  onSelected: (_) => _cambiarFiltroEstadoPublicado(estado),
                  backgroundColor: seleccionado ? Colors.blue : Colors.white,
                  labelStyle: TextStyle(
                    color: seleccionado ? Colors.white : Colors.blue[800],
                    fontWeight: seleccionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: seleccionado
                        ? Colors.blue
                        : (Colors.blue[300] ?? Colors.blue),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _obtenerTextoEstadoPublicado(String estado) {
    switch (estado) {
      case 'todos':
        return 'Todos';
      case 'disponible':
        return 'Disponible';
      case 'vendido':
        return 'Vendido';
      case 'alquilado':
        return 'Alquilado';
      case 'anticretico':
        return 'Anticrético';
      case 'eliminados':
        return 'Eliminados';
      default:
        return estado;
    }
  }

  Color _getColorEstadoPublicado(String estado) {
    switch (estado) {
      case 'disponible':
        return Colors.green;
      case 'vendido':
        return Colors.orange;
      case 'alquilado':
        return Colors.blue;
      case 'anticretico':
        return Colors.purple;
      case 'eliminados':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadgeEstado(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _service.obtenerColorEstado(estado).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _service.obtenerColorEstado(estado),
          width: 1,
        ),
      ),
      child: Text(
        _service.obtenerTextoEstado(estado),
        style: TextStyle(
          color: _service.obtenerColorEstado(estado),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadgeEstadoPublicado(String estadoPublicado, bool isActive) {
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'Eliminado',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorEstadoPublicado(estadoPublicado).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorEstadoPublicado(estadoPublicado),
          width: 1,
        ),
      ),
      child: Text(
        _obtenerTextoEstadoPublicado(estadoPublicado),
        style: TextStyle(
          color: _getColorEstadoPublicado(estadoPublicado),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(InmuebleModel inmueble) {
    if (!(inmueble.isActive ?? true)) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _mostrarDialogoReactivar(inmueble),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reactivar Publicación'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
          ),
        ),
      );
    }

    switch (_filtroEstado) {
      case 'publicados':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoCambiarEstado(inmueble),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Cambiar Estado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoQuitarPublicacion(inmueble),
                icon: const Icon(Icons.visibility_off, size: 18),
                label: const Text('Quitar Publicación'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        );

      case 'aprobado':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _mostrarDialogoPublicar(inmueble),
            icon: const Icon(Icons.public, size: 18),
            label: const Text('Publicar Inmueble'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case 'pendiente':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: null,
            child: Text(
              'Esperando aprobación',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );

      case 'rechazado':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Implementar edición
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Editar y Reenviar'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTarjetaInmueble(InmuebleModel inmueble) {
    // Determinar qué mostrar en el badge
    final String textoBadge;
    final Color colorBadge;

    if (!inmueble.isActive) {
      // Si el inmueble está inactivo, mostrar "Eliminado"
      textoBadge = 'Eliminado';
      colorBadge = Colors.red;
    } else {
      // Si el inmueble está activo, mostrar el estado del anuncio
      final estadoAnuncio = _estadosAnuncio[inmueble.id] ?? 'disponible';
      textoBadge = _obtenerTextoEstadoPublicado(estadoAnuncio);
      colorBadge = _getColorEstadoPublicado(estadoAnuncio);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navegarADetalle(inmueble),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (inmueble.fotos?.isNotEmpty ?? false)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      inmueble.fotos!.first.url,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.home,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.home, size: 50, color: Colors.grey),
                  ),

                // Badge de estado principal
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildBadgeEstado(inmueble.estado),
                ),

                // Badge de estado del anuncio (solo para publicados)
                if (_filtroEstado == 'publicados')
                  Positioned(
                    top: 40,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorBadge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBadge, width: 1),
                      ),
                      child: Text(
                        textoBadge,
                        style: TextStyle(
                          color: colorBadge,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Badge de tipo de operación
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorTipoOperacion(
                        inmueble.tipoOperacion,
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      inmueble.tipoOperacion.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Contador de fotos
                if (inmueble.fotos?.isNotEmpty ?? false)
                  Positioned(
                    top: 40,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${inmueble.fotos!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inmueble.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${inmueble.precio}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${inmueble.direccion}, ${inmueble.ciudad}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildCaracteristica(
                        Icons.aspect_ratio,
                        '${inmueble.superficie} m²',
                      ),
                      const SizedBox(width: 16),
                      _buildCaracteristica(
                        Icons.bed,
                        '${inmueble.dormitorios} dorm.',
                      ),
                      const SizedBox(width: 16),
                      _buildCaracteristica(
                        Icons.bathtub,
                        '${inmueble.banos} baños',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildBotonesAccion(inmueble),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorTipoOperacion(String tipoOperacion) {
    switch (tipoOperacion) {
      case 'venta':
        return Colors.green;
      case 'alquiler':
        return Colors.blue;
      case 'anticretico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCaracteristica(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarMisInmuebles,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_inmueblesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _service.obtenerIconoEstado(_filtroEstado),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay inmuebles ${_service.obtenerTextoEstado(_filtroEstado).toLowerCase()}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_filtroTipoOperacion != 'todos')
              Text(
                'con operación de ${_service.obtenerTextoTipoOperacion(_filtroTipoOperacion).toLowerCase()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (_filtroEstado == 'publicados' &&
                _filtroEstadoPublicado != 'todos')
              Text(
                'con estado ${_obtenerTextoEstadoPublicado(_filtroEstadoPublicado).toLowerCase()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cambiarFiltroEstado(_filtroEstado),
      child: ListView.builder(
        itemCount: _inmueblesFiltrados.length,
        itemBuilder: (context, index) {
          final inmueble = _inmueblesFiltrados[index];
          return _buildTarjetaInmueble(inmueble);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inmuebles'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFiltrosEstado(),
          _buildFiltrosTipoOperacion(),
          if (_filtroEstado == 'publicados') _buildFiltrosEstadoPublicado(),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }
}
