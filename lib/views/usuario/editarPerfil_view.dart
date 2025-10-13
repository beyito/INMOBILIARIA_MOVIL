import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/models/usuario/usuario_model.dart';
import 'package:movil_inmobiliaria/services/usuario/usuario_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final usuarioService = UsuarioService();

  late TextEditingController usernameController;
  late TextEditingController nombreController;
  late TextEditingController correoController;
  late TextEditingController ciController;
  late TextEditingController telefonoController;

  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(
      text: widget.userData?['username'],
    );
    nombreController = TextEditingController(text: widget.userData?['nombre']);
    correoController = TextEditingController(text: widget.userData?['correo']);
    ciController = TextEditingController(text: widget.userData?['ci']);
    telefonoController = TextEditingController(
      text: widget.userData?['telefono'],
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final usuario = UsuarioModel(
      username: usernameController.text,
      nombre: nombreController.text,
      correo: correoController.text,
      ci: ciController.text,
      telefono: telefonoController.text,
    );
    print(usuario.grupo_id);
    final result = await usuarioService.editarPerfil(usuario);

    setState(() => loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil actualizado exitosamente 🎉"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, result.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? "Error desconocido"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar perfil")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField("Usuario", usernameController),
                    const SizedBox(height: 16),
                    _buildTextField("Nombre completo", nombreController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Correo",
                      correoController,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "CI",
                      ciController,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Teléfono",
                      telefonoController,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text("Guardar cambios"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? "Campo obligatorio" : null,
    );
  }
}
