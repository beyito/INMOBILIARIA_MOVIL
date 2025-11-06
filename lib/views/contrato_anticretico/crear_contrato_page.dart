import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:movil_inmobiliaria/services/contrato/contrato_service_anti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class CrearContratoPage extends StatefulWidget {
  const CrearContratoPage({Key? key}) : super(key: key);
  @override
  _CrearContratoPageState createState() => _CrearContratoPageState();
}

class _CrearContratoPageState extends State<CrearContratoPage> {
  final _formKey = GlobalKey<FormState>();
  final ContratoService _service = ContratoService();
  
  // Estado de carga
  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;
  String? _error;
  String? _success;

  // Datos para Dropdowns
  List<dynamic> _agentes = [];
  List<dynamic> _inmuebles = [];

  // Datos del usuario (para rol)
  bool _isAdmin = false;
  int? _userId;

  // Controladores del formulario
  final _formData = {
    'inmueble_id': '',
    'agente_id': '',
    'ciudad': 'Santa Cruz',
    'fecha_contrato': DateTime.now().toIso8601String().split('T')[0],
    'cliente_nombre': '',
    'cliente_ci': '',
    'cliente_domicilio': '',
    'monto': '',
    'comision_porcentaje': '5',
    'vigencia_meses': '12',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoadingDropdowns = true; _error = null; });
    try {
      // 1. Obtener datos del usuario desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('id');
      final grupoNombre = prefs.getString('grupo_nombre') ?? '';
      _isAdmin = grupoNombre.toLowerCase() == 'administrador';
      
      // 2. Cargar Inmuebles
      final inmueblesData = await _service.getInmueblesDisponibles();
      
      // 3. Cargar Agentes (solo si es Admin)
      if (_isAdmin) {
        _agentes = await _service.getAgentes();
      } else if (_userId != null) {
        _formData['agente_id'] = _userId.toString();
      }

      setState(() {
        _inmuebles = inmueblesData
            .where((i) => i['tipo_operacion'] == 'anticretico' && i['estado'] == 'aprobado')
            .toList();
        _isLoadingDropdowns = false;
      });

    } catch (e) {
      setState(() { _error = "Error al cargar datos: $e"; _isLoadingDropdowns = false; });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_formData['agente_id'] == null || _formData['agente_id']!.isEmpty) {
      setState(() { _error = "No se pudo identificar al agente."; });
      return;
    }

    setState(() { _isSubmitting = true; _error = null; _success = null; });
    
    try {
      final response = await _service.crearContratoAnticretico(_formData);
      setState(() {
        _success = "Contrato ID: ${response['id']} creado con éxito.";
        _isSubmitting = false;
      });
      // Limpia el formulario y vuelve atrás
      _formKey.currentState!.reset();
      await Future.delayed(Duration(seconds: 2));
      if (mounted) context.pop();
      
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }
  
  // Estilos (puedes moverlos)
  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
  TextStyle _headerStyle() => Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Contrato Anticrético"),
      ),
      body: _isLoadingDropdowns
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_error != null) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                if (_success != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_success!, style: TextStyle(color: Colors.green.shade700)),
                  ),

                Text("Selección de Partes", style: _headerStyle()),
                const SizedBox(height: 16),

                // Inmueble
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Inmueble Disponible (Anticrético) *"),
                  value: _formData['inmueble_id']!.isEmpty ? null : _formData['inmueble_id'],
                  items: _inmuebles.map((i) => DropdownMenuItem(
                    value: i['id'].toString(),
                    child: Text("(ID: ${i['id']}) ${i['titulo']}"),
                  )).toList(),
                  onChanged: (val) => setState(() => _formData['inmueble_id'] = val ?? ''),
                  validator: (val) => (val == null || val.isEmpty) ? 'Seleccione un inmueble' : null,
                ),
                
                const SizedBox(height: 16),
                
                // Agente (Condicional)
                if (_isAdmin)
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Agente que gestiona *"),
                    value: _formData['agente_id']!.isEmpty ? null : _formData['agente_id'],
                    items: _agentes.map((a) => DropdownMenuItem(
                      value: a['id'].toString(),
                      child: Text(a['nombre'] ?? a['username']),
                    )).toList(),
                    onChanged: (val) => setState(() => _formData['agente_id'] = val ?? ''),
                    validator: (val) => (val == null || val.isEmpty) ? 'Seleccione un agente' : null,
                  )
                else
                  TextFormField(
                    decoration: _inputDecoration("Agente").copyWith(
                      suffixIcon: Icon(LucideIcons.userCheck, color: Colors.green)
                    ),
                    initialValue: "Agente ID: $_userId (Auto-asignado)",
                    readOnly: true,
                  ),
                
                const SizedBox(height: 24),
                Text("Datos del Anticresista (Cliente)", style: _headerStyle()),
                const SizedBox(height: 16),
                
                TextFormField(
                  decoration: _inputDecoration("Nombre del Anticresista *"),
                  onSaved: (val) => _formData['cliente_nombre'] = val ?? '',
                  validator: (val) => (val == null || val.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _inputDecoration("CI del Anticresista *"),
                  onSaved: (val) => _formData['cliente_ci'] = val ?? '',
                  validator: (val) => (val == null || val.isEmpty) ? 'Campo requerido' : null,
                ),

                const SizedBox(height: 24),
                Text("Datos del Contrato", style: _headerStyle()),
                const SizedBox(height: 16),
                
                TextFormField(
                  decoration: _inputDecoration("Monto del Anticrético (\$us) *"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => _formData['monto'] = val ?? '',
                  validator: (val) => (val == null || val.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                // ... (Puedes añadir el resto de campos: comision, vigencia, fecha, ciudad...)
                
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: _isSubmitting 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(LucideIcons.plusCircle),
                  label: Text(_isSubmitting ? "Creando..." : "Crear Contrato"),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}