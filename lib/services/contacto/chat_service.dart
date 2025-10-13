// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import 'package:movil_inmobiliaria/config/config.dart'; // baseUrl
// import 'package:shared_preferences/shared_preferences.dart';

// class ChatService {
//   final String baseUrl = '${Config.baseUrl}/contacto';

//   // 🔹 Listar chats del usuario autenticado
//   Future<List<ChatModel>> getChats() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';

//     final response = await http.get(
//       Uri.parse('$baseUrl/chats/'),
//       headers: {'Authorization': 'Token $token'},
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final values = data['values'] ?? [];
//       return List<ChatModel>.from(values.map((x) => ChatModel.fromJson(x)));
//     } else {
//       throw Exception('Error al obtener chats');
//     }
//   }

//   // 🔹 Obtener mensajes de un chat específico
//   Future<List<MensajeModel>> getMensajes(int chatId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';

//     final response = await http.get(
//       Uri.parse('$baseUrl/chats/$chatId/mensajes/'),
//       headers: {'Authorization': 'Token $token'},
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final values = data['values'] ?? [];
//       return List<MensajeModel>.from(
//         values.map((x) => MensajeModel.fromJson(x)),
//       );
//     } else {
//       throw Exception('Error al obtener mensajes');
//     }
//   }

//   // 🔹 Enviar mensaje a un chat
//   Future<void> enviarMensaje(int chatId, String mensaje) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';
//     final id = prefs.getInt('id') ?? 0;
//     final response = await http.post(
//       Uri.parse('$baseUrl/mensajes/'),
//       headers: {
//         'Authorization': 'Token $token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({'chat': chatId, 'usuario': id, 'mensaje': mensaje}),
//     );

//     if (response.statusCode != 200) {
//       throw Exception('Error al enviar mensaje');
//     }
//   }
// }

// lib/services/contacto/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/contacto/chat_model.dart';
import '../../models/contacto/mensaje_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ChatService {
  final String baseUrl = '${Config.baseUrl}/contacto'; // o tu URL en Render

  // Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('token');
  // }

  // Obtener lista de chats del usuario
  Future<List<ChatModel>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/chats/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final values = data['values'] ?? [];
      return List<ChatModel>.from(values.map((x) => ChatModel.fromJson(x)));
    } else {
      throw Exception('Error al obtener chats');
    }
  }

  // Obtener mensajes anteriores (si el backend los expone)
  Future<List<MensajeModel>> getMensajes(int chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/chats/$chatId/mensajes/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final values = data['values'] ?? [];
      return List<MensajeModel>.from(
        values.map((x) => MensajeModel.fromJson(x)),
      );
    } else {
      throw Exception('Error al obtener mensajes');
    }
  }
}
