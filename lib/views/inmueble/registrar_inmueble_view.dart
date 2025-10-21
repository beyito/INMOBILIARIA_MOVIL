import 'dart:async' show StreamController;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'package:movil_inmobiliaria/services/inmueble/inmueble_service.dart';
import 'package:movil_inmobiliaria/widgets/dialogo_progreso_subida.dart';
import 'package:movil_inmobiliaria/services/auth_service.dart';

//== Widget principal de la vista ==//
class RegistrarInmuebleView extends StatefulWidget {
  const RegistrarInmuebleView({super.key});

  @override
  State<RegistrarInmuebleView> createState() => _RegistrarInmuebleViewState();
}

class _RegistrarInmuebleViewState extends State<RegistrarInmuebleView> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  // Controladores para los campos de texto
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final superficieCtrl = TextEditingController();
  final dormitoriosCtrl = TextEditingController(text: '0');
  final banosCtrl = TextEditingController(text: '0');
  final ciudadCtrl = TextEditingController(text: 'Santa Cruz');
  final zonaCtrl = TextEditingController();

  // Variables de estado
  final StreamController<ProgresoSubida> _progresoController =
      StreamController<ProgresoSubida>.broadcast();
  List<File> _fotos = [];
  LatLng? _ubicacionSeleccionada;
  final _picker = ImagePicker();

  Map<String, dynamic>? _currentUserProfile;
  bool get _esAdmin => _currentUserProfile?['grupo_nombre']?.toString().toLowerCase() == 'administrador';
  bool get _esAgente => _currentUserProfile?['grupo_nombre']?.toString().toLowerCase() == 'agente';

  // Variables para el rol de admin y listas de datos
  List<Map<String, dynamic>> _agentes = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _tiposInmueble = [];

  // Variables para los valores seleccionados en los dropdowns
  Map<String, dynamic>? _agenteSeleccionado;
  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _tipoInmuebleSeleccionado;
  String? _tipoOperacionSeleccionado;

  // Control de estado de la vista
  bool _estaGuardando = false;
  bool _datosInicialesCargados = false;


  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    // Liberar todos los recursos para evitar fugas de memoria
    _mapController.dispose();
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

  // --- Lógica de Negocio --- //

  /// Carga todos los datos necesarios para los dropdowns del formulario de una sola vez.
  Future<void> _cargarDatosIniciales() async {
    if (_datosInicialesCargados) return;

    try {
      // 1. Obtenemos el perfil del usuario actual para saber su rol.
      final userProfile = await AuthService().getMyProfile();
      if (userProfile == null) {
        throw Exception("No se pudo obtener el perfil del usuario.");
      }
      _currentUserProfile = userProfile;

      final service = InmuebleService();
      
      // 2. Preparamos las tareas de carga de datos.
      final tareas = <Future>[
        service.obtenerClientes(),
        service.obtenerTiposInmueble(),
      ];

      // 3. Si el usuario es administrador, añadimos la tarea de cargar la lista de agentes.
      if (_esAdmin) {
        tareas.add(service.obtenerAgentes());
      }

      // 4. Ejecutamos todas las tareas en paralelo.
      final resultados = await Future.wait(tareas);

      // 5. Actualizamos el estado con los datos recibidos.
      if (mounted) {
        setState(() {
          _clientes = (resultados[0] as List).cast<Map<String, dynamic>>();
          _tiposInmueble = (resultados[1] as List).cast<Map<String, dynamic>>();
          
          if (_esAdmin) {
            _agentes = (resultados[2] as List).cast<Map<String, dynamic>>();
          }
          
          _datosInicialesCargados = true; 
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Error al cargar datos iniciales: $e', esError: true);
      }
    }
  }
  
  /// Usa el GPS para mover el mapa a la ubicación actual del usuario.
  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarSnackBar('El servicio de ubicación está desactivado.', esError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarSnackBar('Permiso de ubicación denegado.', esError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarSnackBar('Permiso de ubicación denegado permanentemente.', esError: true);
        return;
      }
      
      _mostrarSnackBar('Obteniendo ubicación...');
      Position position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _ubicacionSeleccionada = currentLocation;
      });

      _mapController.move(currentLocation, 15.0);

    } catch(e) {
      _mostrarSnackBar('No se pudo obtener la ubicación: $e', esError: true);
    }
  }

  /// Abre la galería para que el usuario seleccione múltiples imágenes.
  Future<void> _seleccionarFotos() async {
    final seleccionadas = await _picker.pickMultiImage(imageQuality: 85);
    if (seleccionadas.isNotEmpty) {
      setState(() {
        _fotos.addAll(seleccionadas.map((x) => File(x.path)));
      });
    }
  }

  /// Limpia todos los campos y selecciones del formulario.
  void _limpiarCampos() {
    _formKey.currentState?.reset();
    tituloCtrl.clear();
    descripcionCtrl.clear();
    direccionCtrl.clear();
    ciudadCtrl.text = 'Santa Cruz';
    zonaCtrl.clear();
    superficieCtrl.clear();
    dormitoriosCtrl.text = '0';
    banosCtrl.text = '0';
    precioCtrl.clear();

    setState(() {
      _agenteSeleccionado = null;
      _clienteSeleccionado = null;
      _tipoInmuebleSeleccionado = null;
      _tipoOperacionSeleccionado = null;
      _fotos.clear();
      _ubicacionSeleccionada = null;
    });
    _mostrarSnackBar('Formulario limpiado');
  }

  /// Valida y envía los datos del formulario al servicio para registrar el inmueble.
  // En: lib/views/inmueble/registrar_inmueble_view.dart

Future<void> _registrarInmueble() async {
  if (!(_formKey.currentState?.validate() ?? false)) {
    _mostrarSnackBar('Por favor, completa los campos requeridos', esError: true);
    return;
  }
  if (_esAdmin && _agenteSeleccionado == null) {
    _mostrarSnackBar('Como administrador, debes seleccionar un agente.', esError: true);
    return;
  }
  if (_ubicacionSeleccionada == null) {
    _mostrarSnackBar('Selecciona una ubicación en el mapa', esError: true);
    return;
  }
  if (_fotos.isEmpty) {
    _mostrarSnackBar('Debes seleccionar al menos una foto', esError: true);
    return;
  }

  setState(() => _estaGuardando = true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => DialogoProgresoSubida(streamProgreso: _progresoController.stream),
  );

  try {
    // --- 🔹 INICIO DE LA CORRECCIÓN 🔹 ---
    
    // 1. Determinamos el ID del agente de forma inteligente
    int? agenteId;
    if (_esAdmin) {
      agenteId = _agenteSeleccionado!['id'];
    } else if (_esAgente) {
      agenteId = _currentUserProfile!['id'];
    }

    // 2. Construimos el mapa de datos usando la variable 'agenteId'
    final data = {
      if (agenteId != null) 'agente': agenteId, // <-- Usamos la variable aquí
      if (_clienteSeleccionado != null) 'cliente': _clienteSeleccionado!['id'],
      'tipo_inmueble_id': _tipoInmuebleSeleccionado!['id'],
      'titulo': tituloCtrl.text,
      'descripcion': descripcionCtrl.text,
      'direccion': direccionCtrl.text,
      'ciudad': ciudadCtrl.text,
      'zona': zonaCtrl.text,
      'superficie': double.tryParse(superficieCtrl.text) ?? 0,
      'dormitorios': int.tryParse(dormitoriosCtrl.text) ?? 0,
      'baños': int.tryParse(banosCtrl.text) ?? 0,
      'precio': double.tryParse(precioCtrl.text) ?? 0,
      'tipo_operacion': _tipoOperacionSeleccionado!,
      'latitud': double.parse(_ubicacionSeleccionada!.latitude.toStringAsFixed(6)),
      'longitud': double.parse(_ubicacionSeleccionada!.longitude.toStringAsFixed(6)),
    };
    
    // --- 🔹 FIN DE LA CORRECCIÓN 🔹 ---

    await InmuebleService().registrarInmuebleConProgreso(
      data: data,
      fotosLocales: _fotos,
      onProgreso: (progreso) {
        if (!_progresoController.isClosed) _progresoController.add(progreso);
      },
    );

    if (mounted) {
      Navigator.of(context).pop();
      _mostrarDialogoExito();
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop();
      _mostrarSnackBar('Error al registrar: $e', esError: true);
    }
  } finally {
    if (mounted) setState(() => _estaGuardando = false);
  }
}

  // --- Widgets de UI y Helpers --- //

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarDialogoConfirmacionLimpiar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Formulario'),
        content: const Text('¿Estás seguro de que deseas borrar todos los datos ingresados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _limpiarCampos();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ ¡Éxito!', style: TextStyle(color: Colors.green)),
        content: const Text(
          'Inmueble registrado correctamente. Esperando aprobación del administrador.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _limpiarCampos();
            },
            child: const Text('Registrar Otro'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); 
              }
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Inmueble'),
        actions: [
          IconButton(
            onPressed: _mostrarDialogoConfirmacionLimpiar,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar formulario',
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _estaGuardando,
        child: !_datosInicialesCargados 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSeccionDatosPrincipales(theme, inputDecoration),
                    const SizedBox(height: 20),
                    _buildSeccionDetalles(theme, inputDecoration),
                    const SizedBox(height: 20),
                    _buildSeccionUbicacion(theme, inputDecoration),
                    const SizedBox(height: 20),
                    _buildSeccionGaleria(theme),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _registrarInmueble,
                      icon: _estaGuardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_alt_outlined),
                      label: Text(_estaGuardando ? 'Guardando...' : 'Registrar Inmueble'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCardConTitulo({required String titulo, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionDatosPrincipales(ThemeData theme, InputDecoration decoration) {
    return _buildCardConTitulo(
      titulo: 'Datos Principales',
      children: [
        if (_esAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<Map<String, dynamic>>(
              value: _agenteSeleccionado,
              items: _agentes.map((a) => DropdownMenuItem(
                value: a,
                child: Text('${a['nombre_completo'] ?? a['username']}'),
              )).toList(),
              onChanged: (val) => setState(() => _agenteSeleccionado = val),
              decoration: decoration.copyWith(labelText: 'Agente Asignado', prefixIcon: const Icon(Icons.person_search_outlined)),
              validator: (v) => (_esAdmin && v == null) ? 'Seleccione un agente' : null,
            ),
          ),
        
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _clienteSeleccionado,
          items: _clientes.map((c) => DropdownMenuItem(
            value: c,
            child: Text('${c['nombre_completo'] ?? c['username']}'),
          )).toList(),
          onChanged: (val) => setState(() => _clienteSeleccionado = val),
          decoration: decoration.copyWith(labelText: 'Cliente (Opcional)', prefixIcon: const Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _tipoInmuebleSeleccionado,
          items: _tiposInmueble.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t['nombre'] ?? 'Sin nombre'),
          )).toList(),
          onChanged: (val) => setState(() => _tipoInmuebleSeleccionado = val),
          decoration: decoration.copyWith(labelText: 'Tipo de Inmueble', prefixIcon: const Icon(Icons.category_outlined)),
          validator: (v) => v == null ? 'Seleccione un tipo' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoOperacionSeleccionado,
          items: ['venta', 'alquiler', 'anticretico']
              .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
              .toList(),
          onChanged: (val) => setState(() => _tipoOperacionSeleccionado = val),
          decoration: decoration.copyWith(labelText: 'Tipo de Operación', prefixIcon: const Icon(Icons.request_quote_outlined)),
          validator: (v) => v == null ? 'Seleccione una operación' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: tituloCtrl,
          decoration: decoration.copyWith(labelText: 'Título del Anuncio', prefixIcon: const Icon(Icons.title)),
          validator: (v) => (v == null || v.isEmpty) ? 'El título es obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildSeccionDetalles(ThemeData theme, InputDecoration decoration) {
    return _buildCardConTitulo(
      titulo: 'Detalles del Inmueble',
      children: [
        TextFormField(
          controller: descripcionCtrl,
          decoration: decoration.copyWith(labelText: 'Descripción', prefixIcon: const Icon(Icons.description_outlined)),
          maxLines: 4,
          validator: (v) => (v == null || v.isEmpty) ? 'La descripción es obligatoria' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: precioCtrl,
                decoration: decoration.copyWith(labelText: 'Precio (\$)', prefixIcon: const Icon(Icons.attach_money_outlined)),
                keyboardType: TextInputType.number,
                 validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: superficieCtrl,
                decoration: decoration.copyWith(labelText: 'Superficie (m²)', prefixIcon: const Icon(Icons.square_foot_outlined)),
                keyboardType: TextInputType.number,
                 validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _InputStepper(label: 'Dormitorios', controller: dormitoriosCtrl, icon: Icons.king_bed_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _InputStepper(label: 'Baños', controller: banosCtrl, icon: Icons.bathtub_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionUbicacion(ThemeData theme, InputDecoration decoration) {
    return _buildCardConTitulo(
      titulo: 'Ubicación',
      children: [
        TextFormField(
          controller: direccionCtrl,
          decoration: decoration.copyWith(labelText: 'Dirección', prefixIcon: const Icon(Icons.location_on_outlined)),
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ciudadCtrl,
                decoration: decoration.copyWith(labelText: 'Ciudad', prefixIcon: const Icon(Icons.location_city_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: zonaCtrl,
                decoration: decoration.copyWith(labelText: 'Zona / Barrio', prefixIcon: const Icon(Icons.map_outlined)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Toca el mapa para fijar la ubicación:', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 250,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-17.7833, -63.1821),
                    initialZoom: 14,
                    onTap: (_, point) => setState(() => _ubicacionSeleccionada = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${Config.mapTilerApiKey}',
                    ),
                    if (_ubicacionSeleccionada != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _ubicacionSeleccionada!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                      ]),
                  ],
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    onPressed: _goToMyLocation,
                    tooltip: 'Mi ubicación',
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildSeccionGaleria(ThemeData theme) {
    return _buildCardConTitulo(
      titulo: 'Galería de Fotos',
      children: [
        if (_fotos.isEmpty)
          const Text('Añade al menos una foto del inmueble.'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._fotos.map((file) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    InkWell(
                      onTap: () => setState(() => _fotos.remove(file)),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                )),
            InkWell(
              onTap: _seleccionarFotos,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.add_a_photo_outlined, size: 30), Text("Añadir")],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

//== Widget Personalizado para Inputs Numéricos ==//
class _InputStepper extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _InputStepper({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Icon(icon, color: Colors.grey.shade600),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
              ),
              Column(
                children: [
                  _buildStepperButton(Icons.add, () => _updateValue(1)),
                  _buildStepperButton(Icons.remove, () => _updateValue(-1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateValue(int amount) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    int newValue = currentValue + amount;
    if (newValue >= 0) {
      controller.text = newValue.toString();
    }
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade300),
            bottom: icon == Icons.add ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}