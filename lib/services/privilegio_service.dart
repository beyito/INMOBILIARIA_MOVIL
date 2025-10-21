// lib/services/privilegio_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privilegio_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class PrivilegioService {
  final String baseUrl = '${Config.baseUrl}/usuario';

  Future<List<Privilegio>> getPrivilegios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Verificamos si hay un token antes de hacer la llamada
    if (token == null || token.isEmpty) {
      print("❌ Error: No se encontró token de autenticación. El usuario debe iniciar sesión.");
      throw Exception('Token no encontrado');
    }

    final url = Uri.parse('$baseUrl/get_privilegios');
    print("▶️ Realizando petición GET de PRIVILEGIOS a: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      // --- DEPURACIÓN CLAVE ---
      print("StatusCode de Privilegios: ${response.statusCode}");
      print("✅ Respuesta CRUDA de PRIVILEGIOS: ${response.body}");
      // -------------------------

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Verificamos si la clave 'values' existe y es una lista
        if (data is Map && data.containsKey('values') && data['values'] is List) {
          final List valores = data['values'];
          print("✅ Privilegios procesados correctamente.");
          return valores.map((e) => Privilegio.fromJson(e)).toList();
        } else {
          throw Exception("La respuesta del servidor no tiene el formato esperado (falta la lista 'values').");
        }
      } else {
        print("❌ La API de privilegios respondió con un error. Body: ${response.body}");
        throw Exception('Error al obtener privilegios. Código: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error CATASTRÓFICO en PrivilegioService: $e");
      throw Exception('Fallo en la llamada de red de privilegios: $e');
    }
  }
}