import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'editarPerfil_view.dart';
import 'dart:convert';
import 'package:movil_inmobiliaria/config/config.dart';

class PerfilView extends StatefulWidget {
  static const name = 'perfil-screen';
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  Map<String, dynamic>? userData;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          errorMessage = "No hay token guardado";
          loading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${Config.baseUrl}/usuario/profile/',
        ), // 👈 Ajusta la ruta a la de tu backend
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data; // Aquí deberías recibir username, email, rol, etc.
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = "Error al cargar perfil (${response.statusCode})";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de usuario"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar perfil",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData),
                ),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField("Usuario", userData?['username']),
                          Divider(),
                          _buildField("Nombre completo", userData?['nombre']),
                          Divider(),
                          _buildField("CI", userData?['ci']),
                          Divider(),
                          _buildField("Correo", userData?['correo']),
                          Divider(),
                          _buildField("Teléfono", userData?['telefono']),
                          Divider(),
                          _buildField("Rol", userData?['rolNombre']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Función helper para mostrar título y valor
  Widget _buildField(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value ?? '---',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
