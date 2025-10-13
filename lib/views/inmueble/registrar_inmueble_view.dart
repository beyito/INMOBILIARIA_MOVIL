import 'dart:async' show StreamController;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movil_inmobiliaria/widgets/dialogo_progreso_subida.dart';
import '../../services/inmueble/inmueble_service.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class RegistrarInmuebleView extends StatefulWidget {
  const RegistrarInmuebleView({super.key});

  @override
  State<RegistrarInmuebleView> createState() => _RegistrarInmuebleViewState();
}

class _RegistrarInmuebleViewState extends State<RegistrarInmuebleView> {
  void _mostrarSnackBar(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final StreamController<ProgresoSubida> _progresoController =
      StreamController<ProgresoSubida>.broadcast();

  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final superficieCtrl = TextEditingController();
  final dormitoriosCtrl = TextEditingController();
  final banosCtrl = TextEditingController();
  final ciudadCtrl = TextEditingController();
  final zonaCtrl = TextEditingController();

  List<File> fotos = [];
  LatLng? ubicacionSeleccionada;
  final picker = ImagePicker();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> tiposInmueble = [];
  Map<String, dynamic>? clienteSeleccionado;
  Map<String, dynamic>? tipoInmuebleSeleccionado;
  String? tipoOperacionSeleccionado;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    Future.microtask(() async {
      await _cargarClientes();
      await _cargarTiposInmueble();
    });
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      await Future.wait([_cargarClientes(), _cargarTiposInmueble()]);
    } catch (e) {
      // Solo mostrar error si el widget todavía existe
      if (mounted) {
        _mostrarSnackBar('Error al cargar datos: $e');
      }
    }
  }

  Future<void> _cargarClientes() async {
    final service = InmuebleService();
    final lista = await service.obtenerClientesChat();

    // 🔹 VERIFICAR mounted ANTES de setState
    if (mounted) {
      setState(() => clientes = lista);
    }
  }

  Future<void> _cargarTiposInmueble() async {
    final service = InmuebleService();
    final lista = await service.obtenerTiposInmueble();

    // 🔹 VERIFICAR mounted ANTES de setState
    if (mounted) {
      setState(() => tiposInmueble = lista);
    }
  }

  Future<void> _seleccionarFotos() async {
    final seleccionadas = await picker.pickMultiImage();
    if (seleccionadas.isNotEmpty) {
      setState(() {
        fotos.addAll(seleccionadas.map((x) => File(x.path)));
      });
    }
  }

  // 🔹 NUEVO MÉTODO: Limpiar todos los campos
  void _limpiarCampos() {
    print('🔹 INICIANDO LIMPIEZA CON NUEVA FORM KEY...');

    // 1. Crear una NUEVA key para el formulario (esto fuerza reset completo)
    _formKey = GlobalKey<FormState>();

    // 2. Limpiar controllers manualmente con text = '' (más agresivo)
    tituloCtrl.text = '';
    descripcionCtrl.text = '';
    direccionCtrl.text = '';
    ciudadCtrl.text = '';
    zonaCtrl.text = '';
    superficieCtrl.text = '';
    dormitoriosCtrl.text = '';
    banosCtrl.text = '';
    precioCtrl.text = '';

    // 3. Resetear todas las variables de estado
    setState(() {
      clienteSeleccionado = null;
      tipoInmuebleSeleccionado = null;
      tipoOperacionSeleccionado = null;
      fotos.clear();
      ubicacionSeleccionada = null;
    });

    print('🔹 LIMPIEZA COMPLETADA - Nueva form key creada');
  }

  Future<void> _registrarInmueble() async {
    if (!_formKey.currentState!.validate()) return;
    if (ubicacionSeleccionada == null) {
      _mostrarSnackBar('Selecciona una ubicación en el mapa');
      return;
    }
    if (fotos.isEmpty) {
      _mostrarSnackBar('Debes seleccionar al menos una foto');
      return;
    }
    if (clienteSeleccionado == null ||
        tipoInmuebleSeleccionado == null ||
        tipoOperacionSeleccionado == null) {
      _mostrarSnackBar('Debes seleccionar cliente, tipo y operación');
      return;
    }

    setState(() => cargando = true);

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DialogoProgresoSubida(streamProgreso: _progresoController.stream),
    );

    try {
      final data = {
        'cliente': clienteSeleccionado!['id'],
        'tipo_inmueble_id': tipoInmuebleSeleccionado!['id'],
        'titulo': tituloCtrl.text,
        'descripcion': descripcionCtrl.text,
        'direccion': direccionCtrl.text,
        'ciudad': ciudadCtrl.text,
        'zona': zonaCtrl.text,
        'superficie': double.tryParse(superficieCtrl.text) ?? 0,
        'dormitorios': int.tryParse(dormitoriosCtrl.text) ?? 0,
        'baños': int.tryParse(banosCtrl.text) ?? 0,
        'precio': double.tryParse(precioCtrl.text) ?? 0,
        'tipo_operacion': tipoOperacionSeleccionado!,
        'latitud': double.parse(
          ubicacionSeleccionada!.latitude.toStringAsFixed(6),
        ),
        'longitud': double.parse(
          ubicacionSeleccionada!.longitude.toStringAsFixed(6),
        ),
      };

      final service = InmuebleService();

      await service.registrarInmuebleConProgreso(
        data: data,
        fotosLocales: fotos,
        onProgreso: (progreso) {
          if (!_progresoController.isClosed) {
            _progresoController.add(progreso);
          }
        },
      );

      // Cerrar diálogo de progreso
      if (mounted) Navigator.of(context).pop();

      // 🔹 MOSTRAR DIÁLOGO DE ÉXITO CON OPCIONES
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Éxito!', style: TextStyle(color: Colors.green)),
            content: const Text(
              'Inmueble registrado correctamente. Esperando aprobación del administrador.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                children: [
                  // 🔹 BOTÓN PARA REGISTRAR OTRO INMUEBLE
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar diálogo de éxito
                        _limpiarCampos(); // Limpiar todos los campos
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Registrar Otro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🔹 BOTÓN PARA SALIR
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar diálogo de éxito
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(
                            context,
                          ).pop(true); // Salir de la pantalla
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso en caso de error
      if (mounted) Navigator.of(context).pop();

      _mostrarSnackBar('Error: $e');
      print('Error detallado: $e');
    } finally {
      if (!_progresoController.isClosed) {
        _progresoController.close();
      }

      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  // 🔹 También puedes agregar un botón manual para limpiar
  void _mostrarDialogoLimpiar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar formulario'),
        content: const Text(
          '¿Estás seguro de que quieres limpiar todos los campos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _limpiarCampos();
              _mostrarSnackBar('Formulario limpiado');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Inmueble'),
        actions: [
          // 🔹 BOTÓN PARA LIMPIAR FORMULARIO MANUALMENTE
          IconButton(
            onPressed: _mostrarDialogoLimpiar,
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Limpiar formulario',
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🔹 Dropdown Cliente
                        // En la sección de Dropdowns en el build, cambia a esto:

                        // 🔹 Dropdown Cliente - VERSIÓN MEJORADA
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: clienteSeleccionado,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Seleccione un cliente',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...clientes.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${c['nombre'] ?? 'Sin nombre'} (${c['username'] ?? ''}) (${c['grupo_nombre'] ?? ''})',
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) =>
                              setState(() => clienteSeleccionado = val),
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                          ),
                          validator: (v) =>
                              v == null ? 'Seleccione un cliente' : null,
                        ),
                        const SizedBox(height: 10),

                        // 🔹 Dropdown Tipo Inmueble - VERSIÓN MEJORADA
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: tipoInmuebleSeleccionado,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Seleccione tipo de inmueble',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...tiposInmueble.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t['nombre'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) =>
                              setState(() => tipoInmuebleSeleccionado = val),
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Inmueble',
                          ),
                          validator: (v) => v == null
                              ? 'Seleccione un tipo de inmueble'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // 🔹 Dropdown Tipo Operación - VERSIÓN MEJORADA
                        DropdownButtonFormField<String>(
                          value: tipoOperacionSeleccionado,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Seleccione tipo de operación',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...['venta', 'alquiler', 'anticretico'].map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                          ],
                          onChanged: (val) =>
                              setState(() => tipoOperacionSeleccionado = val),
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Operación',
                          ),
                          validator: (v) => v == null
                              ? 'Seleccione un tipo de operación'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // 🔹 Campos de texto
                        TextFormField(
                          controller: tituloCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descripcionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                          ),
                          maxLines: 3,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: direccionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: ciudadCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: zonaCtrl,
                          decoration: const InputDecoration(labelText: 'Zona'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: superficieCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Superficie',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: dormitoriosCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dormitorios',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: banosCtrl,
                          decoration: const InputDecoration(labelText: 'Baños'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: precioCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Precio',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Fotos
                        Row(
                          children: [
                            Text(
                              'Fotos:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (fotos.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() => fotos.clear());
                                  _mostrarSnackBar('Fotos eliminadas');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar todas'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...fotos.map(
                              (f) => Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.file(
                                    f,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => fotos.remove(f));
                                    },
                                    child: Container(
                                      color: Colors.black54,
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _seleccionarFotos,
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.add_a_photo, size: 30),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // 🔹 Mapa
                        Row(
                          children: [
                            Text(
                              'Selecciona ubicación:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (ubicacionSeleccionada != null)
                              TextButton(
                                onPressed: () {
                                  setState(() => ubicacionSeleccionada = null);
                                  _mostrarSnackBar('Ubicación eliminada');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar ubicación'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 300,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: const LatLng(-17.7833, -63.1821),
                              initialZoom: 15,
                              minZoom: 5,
                              maxZoom: 18,
                              onTap: (tapPosition, point) {
                                setState(() => ubicacionSeleccionada = point);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${Config.mapTilerApiKey}',
                                additionalOptions: {
                                  'key': Config.mapTilerApiKey,
                                },
                                userAgentPackageName: 'com.inmobiliaria.app',
                              ),
                              if (ubicacionSeleccionada != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: ubicacionSeleccionada!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (ubicacionSeleccionada != null)
                          Text(
                            'Lat: ${ubicacionSeleccionada!.latitude.toStringAsFixed(6)}, '
                            'Lng: ${ubicacionSeleccionada!.longitude.toStringAsFixed(6)}',
                          ),

                        const SizedBox(height: 30),

                        // 🔹 BOTONES FINALES
                        Row(
                          children: [
                            // BOTÓN LIMPIAR
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cleaning_services),
                                label: const Text('Limpiar'),
                                onPressed: _mostrarDialogoLimpiar,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // BOTÓN REGISTRAR
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Registrar Inmueble'),
                                onPressed: _registrarInmueble,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (cargando)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _progresoController.close();
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    direccionCtrl.dispose();
    precioCtrl.dispose();
    superficieCtrl.dispose();
    dormitoriosCtrl.dispose();
    banosCtrl.dispose();
    ciudadCtrl.dispose();
    zonaCtrl.dispose();
    super.dispose();
  }
}
