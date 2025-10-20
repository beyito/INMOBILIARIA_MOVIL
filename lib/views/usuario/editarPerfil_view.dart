// lib/views/usuario/editarPerfil_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/usuario/usuario_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();

  late TextEditingController _usernameController;
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _ciController;
  late TextEditingController _telefonoController;
  late TextEditingController _ubicacionController; // <-- Campo añadido
  late TextEditingController _passwordController; // <-- Campo añadido

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.userData ?? {};
    _usernameController = TextEditingController(text: user['username'] ?? '');
    _nombreController = TextEditingController(text: user['nombre'] ?? '');
    _correoController = TextEditingController(text: user['correo'] ?? '');
    _ciController = TextEditingController(text: user['ci'] ?? '');
    _telefonoController = TextEditingController(text: user['telefono'] ?? '');
    _ubicacionController = TextEditingController(text: user['ubicacion'] ?? '');
    _passwordController = TextEditingController(); // El campo de contraseña empieza vacío
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _ciController.dispose();
    _telefonoController.dispose();
    _ubicacionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Creamos un mapa flexible, igual que en la web
    Map<String, dynamic> dataToSend = {
      'username': _usernameController.text,
      'nombre': _nombreController.text,
      'correo': _correoController.text,
      'ci': _ciController.text,
      'telefono': _telefonoController.text,
      'ubicacion': _ubicacionController.text,
    };

    // 🔑 LÓGICA CLAVE: Solo añadimos la contraseña si el usuario escribió algo
    if (_passwordController.text.trim().isNotEmpty) {
      dataToSend['password'] = _passwordController.text.trim();
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id') ?? 0;

    final result = await _usuarioService.editarPerfil(userId, dataToSend);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado exitosamente 🎉"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Devuelve 'true' para indicar que se actualizó
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Error desconocido"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(label: "Nombre de usuario", controller: _usernameController, icon: Icons.account_circle),
            _buildTextField(label: "Nombre completo", controller: _nombreController, icon: Icons.person),
            _buildTextField(label: "Correo", controller: _correoController, icon: Icons.email, keyboardType: TextInputType.emailAddress),
            _buildTextField(label: "CI", controller: _ciController, icon: Icons.badge, keyboardType: TextInputType.number),
            _buildTextField(label: "Teléfono", controller: _telefonoController, icon: Icons.phone, keyboardType: TextInputType.phone),
            _buildTextField(label: "Ubicación", controller: _ubicacionController, icon: Icons.location_city),
            
            const SizedBox(height: 24),
            Text("Cambiar Contraseña (opcional)", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            
            _buildTextField(label: "Nueva Contraseña", controller: _passwordController, icon: Icons.lock, obscureText: true, isRequired: false),

            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar Cambios"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "Este campo es obligatorio";
          }
          return null;
        },
      ),
    );
  }
}