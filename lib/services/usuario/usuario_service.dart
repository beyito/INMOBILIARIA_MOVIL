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

  Future<ApiResponse<UsuarioModel>> editarPerfil(UsuarioModel usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final id = prefs.getInt('id');

    if (token == null || id == null) {
      return ApiResponse.error("Sesión no válida");
    }

    final response = await http.patch(
      Uri.parse('${Config.baseUrl}/usuario/editar_usuario/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(usuario.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 2) {
        return ApiResponse.error(
          "No tienes permisos para acceder a esta función",
        );
      }

      final usuarioMap = data['values']['usuario'] ?? data['values'];
      final usuarioActualizado = UsuarioModel.fromJson(usuarioMap);
      return ApiResponse.success(usuarioActualizado);
    } else {
      return ApiResponse.error(
        "Error al actualizar perfil (${response.statusCode})",
      );
    }
  }
}
