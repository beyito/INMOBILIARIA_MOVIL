// lib/services/usuario/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/config.dart'; // Ajusta la ruta si es necesario

class AuthService {
  final String baseUrl = '${Config.baseUrl}/usuario';

  // Login: Ahora devuelve un mapa simple para indicar éxito o error.
  Future<Map<String, dynamic>> login(String username, String password) async {
  if (username.isEmpty || password.isEmpty) {
    return {'success': false, 'error': 'Usuario y contraseña son requeridos.'};
  }
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (data['status'] == 1) {
      final values = data['values'];
      final token = values['token'];
      final usuarioData = values['usuario'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      if (usuarioData != null && usuarioData['id'] != null) {
        await prefs.setInt('id', usuarioData['id']);
        await prefs.setString('userName', usuarioData['nombre'] ?? '');
        await prefs.setString('user_profile', jsonEncode(usuarioData));
      }
      
      // <-- CAMBIO CLAVE: Devolvemos el usuario junto con el éxito
      return {'success': true, 'usuario': usuarioData}; 
    } else {
      return {'success': false, 'error': data['message'] ?? 'Error desconocido'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Error de conexión: $e'};
  }
}

  // NUEVA FUNCIÓN DE REGISTRO
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      // AÑADIMOS UN PRINT PARA DEPURAR Y VER SIEMPRE LA RESPUESTA
      print('RESPUESTA DEL SERVIDOR (REGISTRO): $data');

      if (data['status'] == 1) {
        if (userData['username'] != null && userData['password'] != null) {
          return await login(userData['username'], userData['password']);
        }
        return {'success': true, 'message': 'Registro exitoso, por favor inicie sesión.'};
      } else {
        // MEJORA: Si la API devuelve errores por campo en 'values', los formateamos.
        String errorMessage = data['message'] ?? 'Error de registro.';
        if (data['values'] != null && data['values'] is Map) {
           final errors = data['values'] as Map<String, dynamic>;
           // Convertimos el mapa de errores en un solo string legible.
           errorMessage = errors.entries.map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}').join('\n');
        }
        return {'success': false, 'error': errorMessage};
      }
    } on TimeoutException {
       return {'success': false, 'error': 'Tiempo de espera agotado. Revisa tu conexión.'};
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor.'};
    }
  }
  Future<Map<String, dynamic>?> getMyProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final userString = prefs.getString('user_profile');

  if (userString != null) {
    // Decodificamos el string JSON de vuelta a un Mapa
    return json.decode(userString) as Map<String, dynamic>;
  }
  return null;
}

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('id');
    await prefs.remove('userName');
  }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}