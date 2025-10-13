import 'dart:async';
import 'dart:convert';
import 'package:movil_inmobiliaria/models/login_response.dart';
import 'package:movil_inmobiliaria/models/usuario/usuario_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class AuthService {
  final String baseUrl = '${Config.baseUrl}/usuario';
  // "http://10.0.2.2:8000/usuario";
  // "http://192.168.100.12:8000/usuario";

  // Login
  Future<LoginResponse> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      if (username.isEmpty && password.isEmpty) {
        return LoginResponse.failure("Usuario y Contraseña están vacíos");
      } else if (username.isEmpty) {
        return LoginResponse.failure("Usuario no puede estar vacío");
      } else {
        return LoginResponse.failure("Contraseña no puede estar vacía");
      }
    }
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // <-- aquí el timeout

      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        final values = data['values'];
        final user = UsuarioModel.fromJson(values);
        // Guardar token localmente
        final prefs = await SharedPreferences.getInstance();
        final id = user.id ?? 0;
        final token = values['token'];
        final username = user.username ?? '';
        final grupo = user.grupo_id ?? 0;
        final usuario = values['usuario'];
        print(user.id);
        print(user.username);

        await prefs.setString('token', token);
        await prefs.setInt('id', id);
        await prefs.setInt('grupo', grupo);
        await prefs.setString('username', username ?? '');

        return LoginResponse.success(
          token: token,
          id: id,
          usuario: UsuarioModel.fromJson(usuario),
        );
      } else {
        final error = data['message']; //?? 'Error de login';
        return LoginResponse.failure(error);
      }
    } on TimeoutException {
      return LoginResponse.failure(
        "Tiempo de espera agotado. Intenta de nuevo.",
      );
    } catch (e) {
      return LoginResponse.failure("Error inesperado: $e");
    }
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<UsuarioModel?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    final username = prefs.getString('username');
    if (id != null && username != null) {
      return UsuarioModel(id: id, username: username);
    }
    return null;
  }
}
