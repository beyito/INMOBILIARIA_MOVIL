// views/contrato/form_contrato_servicios.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/contrato/contrato_model.dart';
import '../../models/inmueble/inmueble_model.dart';
import '../../services/contrato/contrato_service.dart';
import '../../services/contrato/inmueble_no_publicado_service.dart';
import '../../services/usuario/usuario_service.dart';

class FormContratoServicios extends StatefulWidget {
  final VoidCallback? onBack;

  const FormContratoServicios({super.key, this.onBack});

  @override
  State<FormContratoServicios> createState() => _FormContratoServiciosState();
}

class _FormContratoServiciosState extends State<FormContratoServicios> {
  final _formKey = GlobalKey<FormState>();
  final ContratoService _contratoService = ContratoService();
  final InmuebleService _inmuebleService = InmuebleService();
  final UsuarioService _usuarioService = UsuarioService();

  bool _loading = false;
  bool _loadingInmuebles = false;
  bool _loadingAgentes = false;
  String _message = '';

  List<InmuebleModel> _inmuebles = [];
  List<Map<String, dynamic>> _agentes = []; // Lista simple de agentes
  InmuebleModel? _inmuebleSeleccionado;
  Map<String, dynamic>? _agenteSeleccionado;

  // Datos del usuario logueado
  Map<String, dynamic>? _currentUser;
  bool _isAgente = false;

  // Controladores
  final _ciudadController = TextEditingController();
  final _fechaController = TextEditingController();
  final _empresaNombreController = TextEditingController();
  final _empresaRepresentanteController = TextEditingController();
  final _empresaCiController = TextEditingController();
  final _empresaDomicilioController = TextEditingController();
  final _clienteNombreController = TextEditingController();
  final _clienteCiController = TextEditingController();
  final _clienteEstadoCivilController = TextEditingController();
  final _clienteProfesionController = TextEditingController();
  final _clienteDomicilioController = TextEditingController();
  final _agenteNombreController = TextEditingController();
  final _agenteCiController = TextEditingController();
  final _agenteEstadoCivilController = TextEditingController();
  final _agenteDomicilioController = TextEditingController();
  final _inmuebleDireccionController = TextEditingController();
  final _inmuebleSuperficieController = TextEditingController();
  final _inmuebleDistritoController = TextEditingController();
  final _inmuebleManzanaController = TextEditingController();
  final _inmuebleLoteController = TextEditingController();
  final _inmuebleZonaController = TextEditingController();
  final _inmuebleMatriculaController = TextEditingController();
  final _precioInmuebleController = TextEditingController();
  final _comisionController = TextEditingController();
  final _vigenciaDiasController = TextEditingController();
  final _direccionOficinaController = TextEditingController();
  final _telefonoOficinaController = TextEditingController();
  final _emailOficinaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toIso8601String().split('T')[0];
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    await _cargarUsuarioActual();
    await _cargarInmuebles();

    // Solo cargar agentes si el usuario no es agente
    if (!_isAgente) {
      await _cargarAgentes();
    }
  }

  Future<void> _cargarUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_profile');

    if (userString != null) {
      setState(() {
        _currentUser = json.decode(userString) as Map<String, dynamic>;
        _isAgente = _currentUser?['grupo_id'] == 2; // 2 = agente

        // Auto-rellenar datos del agente si es agente
        if (_isAgente) {
          _agenteSeleccionado = _currentUser;
          _agenteNombreController.text = _currentUser?['nombre'] ?? '';
          _agenteCiController.text = _currentUser?['ci'] ?? '';
          _agenteEstadoCivilController.text =
              _currentUser?['estado_civil'] ?? '';
          _agenteDomicilioController.text = _currentUser?['ubicacion'] ?? '';
        }
      });
    }
  }

  Future<void> _cargarInmuebles() async {
    setState(() {
      _loadingInmuebles = true;
      _message = '';
    });

    try {
      final response = await _inmuebleService.getInmueblesNoPublicados();
      setState(() {
        _inmuebles =
            response.map((item) => InmuebleModel.fromJson(item)).toList();
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error al cargar la lista de inmuebles: $e';
      });
    } finally {
      setState(() {
        _loadingInmuebles = false;
      });
    }
  }

  Future<void> _cargarAgentes() async {
    setState(() {
      _loadingAgentes = true;
      _message = '';
    });

    try {
      // Si el usuario NO es agente, necesitamos cargar la lista de agentes disponibles
      // Pero como no tenemos un endpoint específico, podemos manejarlo de dos formas:

      // Opción 1: Si no hay endpoint para agentes, mostrar mensaje
      setState(() {
        _agentes = []; // Lista vacía por ahora
        _message = 'ℹ️ Función de selección de agentes no disponible';
      });

      // Opción 2: Si quieres implementarlo después, aquí iría la llamada al servicio
      // final response = await _usuarioService.getAgentes();
      // setState(() {
      //   _agentes = List<Map<String, dynamic>>.from(response);
      // });
    } catch (e) {
      setState(() {
        _message = '❌ Error al cargar la lista de agentes: $e';
      });
    } finally {
      setState(() {
        _loadingAgentes = false;
      });
    }
  }

  void _seleccionarInmueble(int? inmuebleId) {
    if (inmuebleId == null) {
      setState(() {
        _inmuebleSeleccionado = null;
        _limpiarCamposInmueble();
      });
      return;
    }

    final inmueble = _inmuebles.firstWhere(
      (i) => i.id == inmuebleId,
      orElse: () => InmuebleModel(
        id: 0,
        tipoInmueble: TipoInmuebleModel(
          // ✅ Corregido: usar TipoInmuebleModel
          id: 0,
          nombre: '',
          descripcion: '',
          isActive: false,
        ),
        titulo: '',
        descripcion: '',
        direccion: '',
        ciudad: '',
        zona: '',
        superficie: '',
        dormitorios: 0,
        banos: 0,
        precio: '',
        tipoOperacion: '',
        estado: '',
        latitud: 0,
        longitud: 0,
        isActive: false,
        agente: 0,
        cliente: 0,
      ),
    );

    setState(() {
      _inmuebleSeleccionado = inmueble;

      // Solo autocompletar campos que existen en tu modelo
      _inmuebleDireccionController.text = inmueble.direccion;
      _inmuebleSuperficieController.text = inmueble.superficie;
      _inmuebleZonaController.text = inmueble.zona;
      _precioInmuebleController.text = inmueble.precio;

      // Los campos que no existen en tu modelo quedan vacíos
      _inmuebleDistritoController.clear();
      _inmuebleManzanaController.clear();
      _inmuebleLoteController.clear();
      _inmuebleMatriculaController.clear();
    });
  }

  void _limpiarCamposInmueble() {
    _inmuebleDireccionController.clear();
    _inmuebleSuperficieController.clear();
    _inmuebleDistritoController.clear();
    _inmuebleManzanaController.clear();
    _inmuebleLoteController.clear();
    _inmuebleZonaController.clear();
    _inmuebleMatriculaController.clear();
    _precioInmuebleController.clear();
  }

  void _seleccionarAgente(int? agenteId) {
    if (agenteId == null) {
      setState(() {
        _agenteSeleccionado = null;
        _agenteNombreController.clear();
        _agenteCiController.clear();
        _agenteEstadoCivilController.clear();
        _agenteDomicilioController.clear();
      });
      return;
    }

    final agente = _agentes.firstWhere(
      (a) => a['id'] == agenteId,
      orElse: () => {'id': 0, 'nombre': '', 'ci': ''},
    );

    setState(() {
      _agenteSeleccionado = agente;
      _agenteNombreController.text = agente['nombre'] ?? '';
      _agenteCiController.text = agente['ci'] ?? '';
      _agenteEstadoCivilController.text = agente['estado_civil'] ?? '';
      _agenteDomicilioController.text = agente['domicilio'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _loading ? _buildLoading() : _buildForm(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            '⏳ Generando PDF...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),

            // Mensaje de estado
            if (_message.isNotEmpty) _buildMessageCard(),

            // Formulario
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSection(
                        title: '📋 Información General',
                        children: _buildGeneralInfo(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '🏢 Información de la Empresa',
                        children: _buildCompanyInfo(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '👤 Información del Cliente',
                        children: _buildClientInfo(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '👨‍💼 Información del Agente',
                        children: _buildAgentInfo(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '🏠 Selección de Inmueble',
                        children: _buildPropertySelection(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '💰 Términos del Contrato',
                        children: _buildContractTerms(),
                      ),
                      _buildDivider(),
                      _buildSection(
                        title: '📞 Información de Contacto',
                        children: _buildContactInfo(),
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      if (!_isFormValid()) _buildWarningMessage(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrato de Servicios Inmobiliarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      children: const [
                        TextSpan(text: 'Complete '),
                        TextSpan(
                          text: 'todos los campos ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: 'para generar el contrato'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onBack != null)
              ElevatedButton(
                onPressed: widget.onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[500],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 4),
                    Text('Volver'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    final isSuccess = _message.contains('✅');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Text(
        _message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSuccess ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Divider(
        color: Colors.grey[300],
        height: 1,
      ),
    );
  }

  List<Widget> _buildGeneralInfo() {
    return [
      _buildTextFieldRow([
        _buildTextField(
          controller: _ciudadController,
          label: 'Ciudad',
          required: true,
        ),
        _buildTextField(
          controller: _fechaController,
          label: 'Fecha',
          required: true,
          readOnly: true,
          onTap: () => _selectDate(context),
        ),
      ]),
    ];
  }

  List<Widget> _buildCompanyInfo() {
    return [
      _buildTextFieldRow([
        _buildTextField(
          controller: _empresaNombreController,
          label: 'Nombre de la Empresa',
          required: true,
        ),
        _buildTextField(
          controller: _empresaRepresentanteController,
          label: 'Representante Legal',
          required: true,
        ),
      ]),
      _buildTextFieldRow([
        _buildTextField(
          controller: _empresaCiController,
          label: 'CI Representante',
          required: true,
        ),
        _buildTextField(
          controller: _empresaDomicilioController,
          label: 'Domicilio Empresa',
        ),
      ]),
    ];
  }

  List<Widget> _buildClientInfo() {
    return [
      _buildTextFieldRow([
        _buildTextField(
          controller: _clienteNombreController,
          label: 'Nombre Completo',
          required: true,
        ),
        _buildTextField(
          controller: _clienteCiController,
          label: 'Cédula de Identidad',
          required: true,
        ),
      ]),
      _buildTextFieldRow([
        _buildTextField(
          controller: _clienteEstadoCivilController,
          label: 'Estado Civil',
        ),
        _buildTextField(
          controller: _clienteProfesionController,
          label: 'Profesión',
        ),
      ]),
      _buildTextField(
        controller: _clienteDomicilioController,
        label: 'Domicilio',
      ),
    ];
  }

  List<Widget> _buildAgentInfo() {
    return [
      if (_isAgente)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agente Asignado (Usted)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Nombre: ${_currentUser?['nombre'] ?? ''}'),
              Text('CI: ${_currentUser?['ci'] ?? 'No especificado'}'),
            ],
          ),
        )
      else
        _buildAgenteSelector(),
      const SizedBox(height: 16),
      _buildTextFieldRow([
        _buildTextField(
          controller: _agenteEstadoCivilController,
          label: 'Estado Civil del Agente',
        ),
        _buildTextField(
          controller: _agenteDomicilioController,
          label: 'Domicilio del Agente',
        ),
      ]),
    ];
  }

  Widget _buildAgenteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccionar Agente *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int?>(
          initialValue: _agenteSeleccionado?['id'],
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                _loadingAgentes
                    ? 'Cargando agentes...'
                    : 'Seleccione un agente',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            ..._agentes.map((agente) {
              return DropdownMenuItem(
                value: agente['id'],
                child: Text(
                    '${agente['nombre']} - ${agente['ci']?.isNotEmpty == true ? agente['ci'] : 'Sin CI'}'),
              );
            }),
          ],
          onChanged: _loadingAgentes ? null : _seleccionarAgente,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null) {
              return 'Debe seleccionar un agente';
            }
            return null;
          },
        ),
      ],
    );
  }

  List<Widget> _buildPropertySelection() {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Inmueble *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int?>(
            initialValue: _inmuebleSeleccionado?.id,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  _loadingInmuebles
                      ? 'Cargando inmuebles...'
                      : 'Seleccione un inmueble',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              ..._inmuebles.map((inmueble) {
                return DropdownMenuItem(
                  value: inmueble.id,
                  child: Text(
                      '${inmueble.titulo} - ${inmueble.direccion} - ${inmueble.ciudad}'),
                );
              }),
            ],
            onChanged: _loadingInmuebles ? null : _seleccionarInmueble,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) {
              if (value == null) {
                return 'Debe seleccionar un inmueble';
              }
              return null;
            },
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Campos que se autocompletan (los que existen en tu modelo)
      _buildTextFieldRow([
        _buildTextField(
          controller: _inmuebleDireccionController,
          label: 'Dirección del Inmueble',
          required: true,
          readOnly: true,
        ),
        _buildTextField(
          controller: _precioInmuebleController,
          label: 'Precio del Inmueble',
          required: true,
          readOnly: true,
        ),
      ]),
      _buildTextFieldRow([
        _buildTextField(
          controller: _inmuebleSuperficieController,
          label: 'Superficie',
          readOnly: true,
        ),
        _buildTextField(
          controller: _inmuebleZonaController,
          label: 'Zona',
          readOnly: true,
        ),
      ]),

      // Campos que NO se autocompletan (el usuario los debe llenar manualmente)
      _buildTextFieldRow([
        _buildTextField(
          controller: _inmuebleDistritoController,
          label: 'Distrito',
        ),
        _buildTextField(
          controller: _inmuebleManzanaController,
          label: 'Manzana',
        ),
      ]),
      _buildTextFieldRow([
        _buildTextField(
          controller: _inmuebleLoteController,
          label: 'Lote',
        ),
        _buildTextField(
          controller: _inmuebleMatriculaController,
          label: 'Matrícula',
        ),
      ]),
    ];
  }

  List<Widget> _buildContractTerms() {
    return [
      _buildTextFieldRow([
        _buildTextField(
          controller: _comisionController,
          label: 'Comisión (%)',
          required: true,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _vigenciaDiasController,
          label: 'Vigencia (días)',
          required: true,
          keyboardType: TextInputType.number,
        ),
      ]),
    ];
  }

  List<Widget> _buildContactInfo() {
    return [
      _buildTextField(
        controller: _direccionOficinaController,
        label: 'Dirección Oficina',
      ),
      _buildTextFieldRow([
        _buildTextField(
          controller: _telefonoOficinaController,
          label: 'Teléfono',
          keyboardType: TextInputType.phone,
        ),
        _buildTextField(
          controller: _emailOficinaController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
      ]),
    ];
  }

  Widget _buildTextFieldRow(List<Widget> children) {
    return Row(
      children: children
          .map((child) => Expanded(child: child))
          .expand((widget) => [widget, const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: 'Ingrese ${label.toLowerCase()}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (required && (value == null || value.isEmpty)) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onBack != null)
            ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _generarContrato,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print, size: 20),
                const SizedBox(width: 8),
                Text(_loading
                    ? '⏳ Generando PDF...'
                    : '📄 Generar Contrato PDF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.yellow, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️ Complete todos los campos obligatorios para habilitar la generación del contrato',
              style: TextStyle(
                color: Colors.yellow[700],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    final requiredFields = [
      _ciudadController,
      _fechaController,
      _empresaNombreController,
      _empresaRepresentanteController,
      _empresaCiController,
      _clienteNombreController,
      _clienteCiController,
      _agenteNombreController,
      _agenteCiController,
      _inmuebleDireccionController,
      _precioInmuebleController,
      _comisionController,
      _vigenciaDiasController,
    ];

    return requiredFields
        .every((controller) => controller.text.trim().isNotEmpty);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _fechaController.text = picked.toIso8601String().split('T')[0];
    }
  }

  void _generarContrato() async {
    if (!_isFormValid()) {
      setState(() {
        _message = '❌ Complete todos los campos obligatorios';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
        _message = '';
      });

      try {
        // Obtener el ID del agente
        int agenteId;
        if (_isAgente) {
          // Si es agente, usar su propio ID
          agenteId = _currentUser?['id'] ?? 0;
        } else {
          // Si no es agente, necesitaríamos un selector de agentes
          // Por ahora usamos un valor por defecto o mostramos error
          setState(() {
            _message = '❌ Debe seleccionar un agente';
            _loading = false;
          });
          return;
        }

        // Verificar que tenemos un inmueble seleccionado
        if (_inmuebleSeleccionado == null) {
          setState(() {
            _message = '❌ Debe seleccionar un inmueble';
            _loading = false;
          });
          return;
        }

        final contrato = ContratoServicios(
          ciudad: _ciudadController.text,
          fecha: _fechaController.text,
          empresaNombre: _empresaNombreController.text,
          empresaRepresentante: _empresaRepresentanteController.text,
          empresaCi: _empresaCiController.text,
          empresaDomicilio: _empresaDomicilioController.text,
          clienteNombre: _clienteNombreController.text,
          clienteCi: _clienteCiController.text,
          clienteEstadoCivil: _clienteEstadoCivilController.text,
          clienteProfesion: _clienteProfesionController.text,
          clienteDomicilio: _clienteDomicilioController.text,
          agenteNombre: _agenteNombreController.text,
          agenteCi: _agenteCiController.text,
          agenteEstadoCivil: _agenteEstadoCivilController.text,
          agenteDomicilio: _agenteDomicilioController.text,
          inmuebleDireccion: _inmuebleDireccionController.text,
          inmuebleSuperficie: _inmuebleSuperficieController.text,
          inmuebleDistrito: _inmuebleDistritoController.text,
          inmuebleManzana: _inmuebleManzanaController.text,
          inmuebleLote: _inmuebleLoteController.text,
          inmuebleZona: _inmuebleZonaController.text,
          inmuebleMatricula: _inmuebleMatriculaController.text,
          precioInmueble: _precioInmuebleController.text,
          comision: _comisionController.text,
          vigenciaDias: _vigenciaDiasController.text,
          direccionOficina: _direccionOficinaController.text,
          telefonoOficina: _telefonoOficinaController.text,
          emailOficina: _emailOficinaController.text,
          // ✅ AGREGAR ESTOS CAMPOS QUE FALTAN
          agenteId: agenteId,
          inmuebleId: _inmuebleSeleccionado!.id,
        );

        final file = await _contratoService.generarContratoServicios(contrato);

        if (!mounted) return;

        if (file != null) {
          await _abrirPDFConfiable(file);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _message = '❌ Error: $e';
        });
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _abrirPDFConfiable(File file) async {
    // Método 1: Share plus
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Contrato Generado');
      setState(() {
        _message = '✅ Selecciona una app para abrir el PDF';
      });
      return;
    } catch (e) {
      print('Share falló: $e');
    }

    // Método 2: URL Launcher
    try {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        setState(() {
          _message = '✅ PDF abierto';
        });
        return;
      }
    } catch (e) {
      print('URL Launcher falló: $e');
    }

    setState(() {
      _message = '✅ Contrato generado en: ${file.path}';
    });
  }

  @override
  void dispose() {
    // Dispose de todos los controllers
    _ciudadController.dispose();
    _fechaController.dispose();
    _empresaNombreController.dispose();
    _empresaRepresentanteController.dispose();
    _empresaCiController.dispose();
    _empresaDomicilioController.dispose();
    _clienteNombreController.dispose();
    _clienteCiController.dispose();
    _clienteEstadoCivilController.dispose();
    _clienteProfesionController.dispose();
    _clienteDomicilioController.dispose();
    _agenteNombreController.dispose();
    _agenteCiController.dispose();
    _agenteEstadoCivilController.dispose();
    _agenteDomicilioController.dispose();
    _inmuebleDireccionController.dispose();
    _inmuebleSuperficieController.dispose();
    _inmuebleDistritoController.dispose();
    _inmuebleManzanaController.dispose();
    _inmuebleLoteController.dispose();
    _inmuebleZonaController.dispose();
    _inmuebleMatriculaController.dispose();
    _precioInmuebleController.dispose();
    _comisionController.dispose();
    _vigenciaDiasController.dispose();
    _direccionOficinaController.dispose();
    _telefonoOficinaController.dispose();
    _emailOficinaController.dispose();
    super.dispose();
  }
}
