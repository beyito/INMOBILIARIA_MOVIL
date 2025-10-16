// views/contrato/form_contrato_servicios.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 FALTA ESTE IMPORT
import 'package:url_launcher/url_launcher.dart'; // 👈 FALTA ESTE IMPORT
import '../../models/contrato/contrato_model.dart';
import '../../services/contrato/contrato_service.dart';
import 'package:share_plus/share_plus.dart';

class FormContratoServicios extends StatefulWidget {
  const FormContratoServicios({super.key});

  @override
  State<FormContratoServicios> createState() => _FormContratoServiciosState();
}

class _FormContratoServiciosState extends State<FormContratoServicios> {
  final _formKey = GlobalKey<FormState>();
  final ContratoService _service = ContratoService();
  bool _loading = false;

  // Controladores para todos los campos
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
    _fechaController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Contrato de Servicios Inmobiliarios',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            'Generando contrato...',
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildSection(
              title: '📋 Información General',
              icon: Icons.info_outline,
              color: Colors.blue,
              children: [
                _buildTextField(
                  controller: _ciudadController,
                  label: 'Ciudad',
                  hint: 'Ej: Santa Cruz de la Sierra',
                  required: true,
                ),
                _buildTextField(
                  controller: _fechaController,
                  label: 'Fecha',
                  hint: 'DD/MM/AAAA',
                  required: true,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ],
            ),
            _buildSection(
              title: '🏢 Información de la Empresa',
              icon: Icons.business,
              color: Colors.green,
              children: [
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
                _buildTextField(
                  controller: _empresaCiController,
                  label: 'Cédula de Identidad',
                  required: true,
                ),
                _buildTextField(
                  controller: _empresaDomicilioController,
                  label: 'Domicilio de la Empresa',
                  required: true,
                ),
              ],
            ),
            _buildSection(
              title: '👤 Información del Cliente',
              icon: Icons.person,
              color: Colors.orange,
              children: [
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
                _buildTextField(
                  controller: _clienteEstadoCivilController,
                  label: 'Estado Civil',
                ),
                _buildTextField(
                  controller: _clienteProfesionController,
                  label: 'Profesión',
                ),
                _buildTextField(
                  controller: _clienteDomicilioController,
                  label: 'Domicilio',
                ),
              ],
            ),
            _buildSection(
              title: '👨‍💼 Información del Agente',
              icon: Icons.badge,
              color: Colors.purple,
              children: [
                _buildTextField(
                  controller: _agenteNombreController,
                  label: 'Nombre del Agente',
                  required: true,
                ),
                _buildTextField(
                  controller: _agenteCiController,
                  label: 'Cédula de Identidad',
                  required: true,
                ),
                _buildTextField(
                  controller: _agenteEstadoCivilController,
                  label: 'Estado Civil',
                ),
                _buildTextField(
                  controller: _agenteDomicilioController,
                  label: 'Domicilio',
                ),
              ],
            ),
            _buildSection(
              title: '🏠 Información del Inmueble',
              icon: Icons.home,
              color: Colors.brown,
              children: [
                _buildTextField(
                  controller: _inmuebleDireccionController,
                  label: 'Dirección del Inmueble',
                  required: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _inmuebleSuperficieController,
                        label: 'Superficie',
                        hint: 'Ej: 150m²',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _inmuebleDistritoController,
                        label: 'Distrito',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _inmuebleManzanaController,
                        label: 'Manzana',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _inmuebleLoteController,
                        label: 'Lote',
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  controller: _inmuebleZonaController,
                  label: 'Zona',
                ),
                _buildTextField(
                  controller: _inmuebleMatriculaController,
                  label: 'Matrícula',
                ),
                _buildTextField(
                  controller: _precioInmuebleController,
                  label: 'Precio del Inmueble',
                  required: true,
                  hint: 'Ej: \$250,000 USD',
                ),
              ],
            ),
            _buildSection(
              title: '💰 Términos del Contrato',
              icon: Icons.attach_money,
              color: Colors.teal,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _comisionController,
                        label: 'Comisión (%)',
                        required: true,
                        keyboardType: TextInputType.number,
                        hint: 'Ej: 4',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _vigenciaDiasController,
                        label: 'Vigencia (días)',
                        required: true,
                        keyboardType: TextInputType.number,
                        hint: 'Ej: 180',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildSection(
              title: '📞 Información de Contacto',
              icon: Icons.contact_phone,
              color: Colors.red,
              children: [
                _buildTextField(
                  controller: _direccionOficinaController,
                  label: 'Dirección de Oficina',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _telefonoOficinaController,
                        label: 'Teléfono',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _emailOficinaController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete todos los campos obligatorios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los campos marcados con * son requeridos para generar el contrato.',
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          hintText: hint,
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
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _generarContrato,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          '📄 Generar Contrato PDF',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _fechaController.text = _formatDate(picked);
    }
  }

  void _generarContrato() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
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
        );

        final file = await _service.generarContratoServicios(contrato);

        if (!mounted) return;

        if (file != null) {
          // ✅ INTENTAR MÚLTIPLES MÉTODOS
          await _abrirPDFConfiable(file);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  // ✅ MÉTODO MEJORADO PARA ABRIR PDF
  Future<void> _abrirPDFConfiable(File file) async {
    print('📁 PDF listo: ${file.path}');

    // Método 1: Share plus (más confiable)
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Contrato Generado');
      _mostrarExito('✅ Selecciona una app para abrir el PDF');
      return;
    } catch (e) {
      print('Share falló: $e');
    }

    // Método 2: URL Launcher
    try {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _mostrarExito('✅ PDF abierto');
        return;
      }
    } catch (e) {
      print('URL Launcher falló: $e');
    }

    // Método 3: Mostrar diálogo con ruta
    _mostrarExitoConRuta(file);
  }

  void _mostrarExitoConRuta(File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✅ Contrato generado'),
            Text('Ruta: ${file.path}', style: const TextStyle(fontSize: 10)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'COPIAR RUTA',
          onPressed: () {
            // Copiar ruta al portapapeles
            Clipboard.setData(ClipboardData(text: file.path));
          },
        ),
      ),
    );
  }

  // ✅ MOSTRAR ÉXITO
  void _mostrarExito(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
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
