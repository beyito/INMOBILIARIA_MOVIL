import 'package:flutter/material.dart';
import 'package:movil_inmobiliaria/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../provider/chat_provider.dart';
import 'package:provider/provider.dart';
import '../../models/usuario/usuario_model.dart';

class LoginPage extends StatefulWidget {
  static const name = 'login-screen';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final resAuth = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (resAuth.status == 1) {
        // ⚡ Aquí seteas el usuario en el ChatProvider
        final chatProvider = context.read<ChatProvider>();
        final usuario = resAuth.usuario;
        print(usuario); // 👈 aquí accedes al usuario
        chatProvider.setUser(
          usuario!,
          'ws://192.168.100.12:8000/ws/user/${usuario.id}/?token=${resAuth.token}',
        );
        chatProvider.loadChats();
        // Login exitoso
        context.go('/home/0');
      } else {
        setState(() {
          _errorMessage = resAuth.error ?? 'Error desconocido';
        });
      }
    } catch (e) {
      print('Error al conectar con el servidor: $e');
      setState(() {
        _errorMessage = 'Error al conectar con el servidor: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo o avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent.shade100,
                child: const Icon(Icons.home, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),

              const Text(
                "Bienvenido a Nuestra Inmobiliaria",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Card con campos de login
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
                        controller: _usernameController,
                        label: "Usuario",
                        icon: Icons.person,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Contraseña",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      // Dentro del Card, después del botón de "Iniciar sesión"
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await login(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                                child: const Text("Iniciar sesión"),
                              ),
                            ),
                      // Mostrar error si existe
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      // 👇 Nuevo botón de "Olvidaste tu contraseña?"
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push(
                              '/recuperar-password',
                            ); // Aquí debe ir tu ruta de recuperación
                          },
                          child: const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Links de registro
              Column(
                children: [
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      "¿No estás registrado? Regístrate aquí",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/agente'),
                    child: const Text(
                      "¿Eres agente inmobiliario? Trabaja con nosotros aquí",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función helper para los campos de texto con ícono
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
