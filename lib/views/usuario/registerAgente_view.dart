import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class RegisterAgenteView extends StatefulWidget {
  static const name = 'registerAgente-screen';
  const RegisterAgenteView({super.key});

  @override
  State<RegisterAgenteView> createState() => _RegisterAgenteViewState();
}

class _RegisterAgenteViewState extends State<RegisterAgenteView> {
  final _formKey = GlobalKey<FormState>();
  // nombre = models.CharField(max_length=100)
  //     correo = models.EmailField(unique=True)
  //     telefono = models.CharField(max_length=20)
  //     numero_licencia = models.CharField(max_length=50, unique=True)
  //     experiencia = models.IntegerField(default=0)
  //     ci
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _numeroLicenciaController =
      TextEditingController();
  final TextEditingController _experienciaController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _registrarAgente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final data = {
      "nombre": _nombreController.text,
      "correo": _correoController.text,
      "ci": _ciController.text,
      "telefono": _telefonoController.text,
      "numero_licencia": _numeroLicenciaController.text,
      "experiencia": int.tryParse(_experienciaController.text) ?? 0,
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${Config.baseUrl}/usuario/registerAgente/',
          // "http://10.0.2.2:8000/usuario/registerAgente/" ,
        ), // Ajusta tu endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Mostrar el mensaje que viene del backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? "Solicitud enviada")),
        );

        // Si quieres cerrar la pantalla solo si fue éxito (status == 1)
        if (resData['status'] == 1) {
          if (mounted) {
            context.pop(); // Volver a la pantalla anterior
          } // Volver a la pantalla anterior
        } else {
          // Si status != 1, mostrar error
          setState(() {
            _errorMessage = resData['message'] ?? "Error desconocido";
          });
        }
      } else {
        setState(() {
          _errorMessage = resData['message'] ?? "Error desconocido";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Agente"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent.shade100,
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Usar Card para agrupar los campos
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nombreController,
                        label: "Nombre completo",
                        icon: Icons.person,
                        validatorMsg: "Ingrese el nombre",
                      ),
                      _buildTextField(
                        controller: _correoController,
                        label: "Correo",
                        icon: Icons.email,
                        validatorMsg: "Ingrese el correo",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        controller: _ciController,
                        label: "CI",
                        icon: Icons.badge,
                      ),
                      _buildTextField(
                        controller: _telefonoController,
                        label: "Teléfono",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _numeroLicenciaController,
                        label: "Número de licencia",
                        icon: Icons.card_membership,
                        validatorMsg: "Ingrese número de licencia",
                      ),
                      _buildTextField(
                        controller: _experienciaController,
                        label: "Experiencia (años)",
                        icon: Icons.timeline,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _registrarAgente,
                        icon: const Icon(Icons.save),
                        label: const Text("Registrar"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Función helper para crear TextFormFields con estilo
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validatorMsg,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validatorMsg != null
            ? (value) => value!.isEmpty ? validatorMsg : null
            : null,
      ),
    );
  }
}
