// lib/views/usuario/recuperacionPassword_view.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movil_inmobiliaria/config/config.dart';

class RecuperacionPasswordView extends StatefulWidget {
  static const name = 'recuperacionPassword-screen';
  const RecuperacionPasswordView({super.key});

  @override
  State<RecuperacionPasswordView> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<RecuperacionPasswordView> {
  final String baseUrl = '${Config.baseUrl}/usuario';
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _step = 1; // 1=correo, 2=código, 3=nueva pass, 4=éxito
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  // URLs CORREGIDAS (sin la barra '/' al final)
  final Uri _urlEnviarCodigo = Uri.parse('${Config.baseUrl}/usuario/recuperacion-codigo/');
  final Uri _urlVerificarCodigo = Uri.parse('${Config.baseUrl}/usuario/recuperacion-codigo-confirmar/');
  final Uri _urlCambiarPassword = Uri.parse('${Config.baseUrl}/usuario/recuperacion-codigo-actualizar/');

  Future<void> _enviarCodigo() async {
    setState(() { _isLoading = true; _message = ''; _isError = false; });
    try {
      final res = await http.post(_urlEnviarCodigo, headers: {"Content-Type": "application/json"}, body: jsonEncode({"correo": _correoController.text}));
      final data = jsonDecode(res.body);
      if (data["status"] == 1) {
        setState(() { _message = "Código enviado a tu correo."; _step = 2; });
      } else {
        setState(() { _message = data["message"] ?? "Error al enviar código."; _isError = true; });
      }
    } catch (e) {
      setState(() { _message = "Error de conexión."; _isError = true; });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verificarCodigo() async {
    setState(() { _isLoading = true; _message = ''; _isError = false; });
    try {
      final res = await http.post(_urlVerificarCodigo, headers: {"Content-Type": "application/json"}, body: jsonEncode({"correo": _correoController.text, "code": _codigoController.text}));
      final data = jsonDecode(res.body);
      if (data["status"] == 1) {
        setState(() { _message = "Código validado. Ahora ingresa tu nueva contraseña."; _step = 3; });
      } else {
        setState(() { _message = data["message"] ?? "Código inválido."; _isError = true; });
      }
    } catch (e) {
      setState(() { _message = "Error de conexión."; _isError = true; });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cambiarPassword() async {
    setState(() { _isLoading = true; _message = ''; _isError = false; });
    try {
      final res = await http.post(_urlCambiarPassword, headers: {"Content-Type": "application/json"}, body: jsonEncode({"correo": _correoController.text, "password": _passwordController.text}));
      final data = jsonDecode(res.body);
      if (data["status"] == 1) {
        setState(() { _message = "Contraseña actualizada correctamente ✅"; _step = 4; });
      } else {
        setState(() { _message = data["message"] ?? "Error al actualizar contraseña."; _isError = true; });
      }
    } catch (e) {
      setState(() { _message = "Error de conexión."; _isError = true; });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget currentStepWidget;
    switch (_step) {
      case 1:
        currentStepWidget = _buildStep1();
        break;
      case 2:
        currentStepWidget = _buildStep2();
        break;
      case 3:
        currentStepWidget = _buildStep3();
        break;
      case 4:
        currentStepWidget = _buildStep4();
        break;
      default:
        currentStepWidget = Container();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Contraseña")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security_update_good_outlined, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: currentStepWidget,
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_message.isNotEmpty && _step != 4)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _message,
                  style: TextStyle(color: _isError ? Colors.red : Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() => Column(key: const ValueKey(1), children: [
    const Text("Ingresa tu correo para enviarte un código de recuperación."),
    const SizedBox(height: 16),
    TextField(controller: _correoController, decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: _isLoading ? null : _enviarCodigo, child: const Text("Enviar código")),
  ]);

  Widget _buildStep2() => Column(key: const ValueKey(2), children: [
    Text("Revisa tu bandeja de entrada e ingresa el código que te enviamos a ${_correoController.text}."),
    const SizedBox(height: 16),
    TextField(controller: _codigoController, decoration: const InputDecoration(labelText: "Código de verificación", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: _isLoading ? null : _verificarCodigo, child: const Text("Verificar código")),
  ]);

  Widget _buildStep3() => Column(key: const ValueKey(3), children: [
    const Text("Tu código fue verificado. Ahora puedes establecer una nueva contraseña."),
    const SizedBox(height: 16),
    TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Nueva contraseña", border: OutlineInputBorder()), obscureText: true),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: _isLoading ? null : _cambiarPassword, child: const Text("Actualizar contraseña")),
  ]);

  Widget _buildStep4() => Column(key: const ValueKey(4), children: [
    const Icon(Icons.check_circle, color: Colors.green, size: 80),
    const SizedBox(height: 20),
    Text(_message, style: const TextStyle(color: Colors.green, fontSize: 16), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Volver al Login")),
  ]);
}