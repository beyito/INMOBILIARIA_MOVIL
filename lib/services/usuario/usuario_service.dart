import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import '../../models/usuario/usuario_model.dart';
import '../../models/response__model.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioService {
  final String baseUrl = '${Config.baseUrl}/usuario';
  // "http://10.0.2.2:8000/usuario";
  // "http://192.168.100.12:8000/usuario";
  final AuthService authService = AuthService();

  // Mostrar usuarios
  Future<ApiResponse<List<UsuarioModel>>> mostrarUsuarios() async {
    final token = await authService.getToken();
    if (token == null) return ApiResponse.error("Usuario no autenticado");

    final response = await http.get(
      Uri.parse('$baseUrl/listar_usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 2) {
        return ApiResponse.error(
          "No tienes permisos para acceder a esta función",
        );
      }

      final List<dynamic> usuariosJson = data['values'];
      final usuarios = usuariosJson
          .map((json) => UsuarioModel.fromJson(json))
          .toList();
      return ApiResponse.success(usuarios);
    } else {
      final error = jsonDecode(response.body);
      return ApiResponse.error(error['error'] ?? 'Error al cargar usuarios');
    }
  }

  Future<Map<String, dynamic>> editarPerfil(int userId, Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    return {'success': false, 'message': 'Usuario no autenticado'};
  }

  try {
    final response = await http.patch(
      Uri.parse('$baseUrl/editar_usuario/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    final resData = jsonDecode(response.body);
    
    // V--- AÑADE ESTE PRINT PARA VER LA RESPUESTA COMPLETA ---V
    print('RESPUESTA DEL SERVIDOR (EDITAR PERFIL): $resData');

    if (resData['status'] == 1) {
      return {'success': true, 'data': resData['values']};
    } else {
      // Formateamos el error si viene detallado
      String errorMessage = resData['message'] ?? 'Error desconocido';
      if (resData['values'] != null && resData['values'] is Map) {
         final errors = resData['values'] as Map<String, dynamic>;
         errorMessage = errors.entries.map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}').join('\n');
      }
      return {'success': false, 'message': errorMessage};
    }
  } catch (e) {
    return {'success': false, 'message': 'Error de conexión: $e'};
  }
}
}
