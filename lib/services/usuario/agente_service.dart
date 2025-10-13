// services/agente_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'package:movil_inmobiliaria/models/usuario/usuario_model.dart';

class AgenteService {
  final String baseUrl = '${Config.baseUrl}/usuario';

  Future<List<UsuarioModel>> obtenerAgentes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/listar-agentes'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final agentesJson = body['values'] as List;

      return agentesJson.map((json) => UsuarioModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los agentes');
    }
  }
}
