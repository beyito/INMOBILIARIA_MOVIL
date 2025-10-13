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
  final String baseUrl = '${Config.baseUrl}/usuario'; // 👈 cambia tu URL
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _step = 1; // 1=correo, 2=código, 3=nueva pass
  bool _isLoading = false;
  String _message = '';

  Future<void> _enviarCodigo() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/recuperacion-codigo/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"correo": _correoController.text}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["status"] == 1) {
        setState(() {
          _message = "Código enviado a tu correo.";
          _step = 2;
        });
      } else {
        setState(() => _message = data["message"] ?? "Error al enviar código.");
      }
    } catch (e) {
      setState(() => _message = "Error de conexión: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verificarCodigo() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/recuperacion-codigo-confirmar/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": _correoController.text,
          "code": _codigoController.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["status"] == 1) {
        setState(() {
          _message = "Código validado. Ahora ingresa tu nueva contraseña.";
          _step = 3;
        });
      } else {
        setState(() => _message = data["message"] ?? "Código inválido.");
      }
    } catch (e) {
      setState(() => _message = "Error de conexión: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cambiarPassword() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/recuperacion-codigo-actualizar/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": _correoController.text,
          "password": _passwordController.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["status"] == 1) {
        setState(() {
          _message = "Contraseña actualizada correctamente ✅";
          _step = 4; // flujo terminado
        });
      } else {
        setState(
          () => _message = data["message"] ?? "Error al actualizar contraseña.",
        );
      }
    } catch (e) {
      setState(() => _message = "Error de conexión: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_step == 1) ...[
              TextField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: "Correo"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _enviarCodigo,
                child: const Text("Enviar código"),
              ),
            ] else if (_step == 2) ...[
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: "Código recibido"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verificarCodigo,
                child: const Text("Verificar código"),
              ),
            ] else if (_step == 3) ...[
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Nueva contraseña",
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _cambiarPassword,
                child: const Text("Actualizar contraseña"),
              ),
            ] else if (_step == 4) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("Tu contraseña fue cambiada exitosamente."),
            ],
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
