// services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ContactoService {
  final String baseUrl = '${Config.baseUrl}/contacto';

  Future<Map<String, dynamic>> crearChat(int agenteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/chats/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'agente_id': agenteId,
        'cliente_id': prefs.getInt('id'),
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Error al crear chat',
      };
    }
  }

  Future<Map<String, dynamic>> obtenerChatExistente(int agenteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/chats/?agente=$agenteId'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final chats = body['values'] as List;

      if (chats.isNotEmpty) {
        return {'success': true, 'data': chats.first, 'exists': true};
      }
    }

    return {'success': false, 'exists': false};
  }
}
