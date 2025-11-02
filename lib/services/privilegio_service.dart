import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privilegio_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'auth_service.dart'; // 👈 PASO 1: Importar AuthService para poder hacer logout

class PrivilegioService {
  final String baseUrl = '${Config.baseUrl}/usuario';
  final AuthService _authService = AuthService(); // 👈 PASO 2: Crear una instancia para usarla

  Future<List<Privilegio>> getPrivilegios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print("❌ Error: No se encontró token. Forzando logout.");
      await _authService.logout();
      throw Exception('Token no encontrado');
    }

    final url = Uri.parse('$baseUrl/get_privilegios');
    print("▶️ Realizando petición de PRIVILEGIOS a: $url con token: $token");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30)); // Aumentamos el timeout por si la red es lenta

      print("StatusCode de Privilegios: ${response.statusCode}");
      print("Respuesta de PRIVILEGIOS: ${response.body}");

      // Si la respuesta es 401 (No Autorizado), el token es inválido.
      if (response.statusCode == 401) {
        // 👇 ¡AQUÍ ESTÁ LA LÓGICA CLAVE!
        print("🔴 Token inválido detectado (401). Forzando logout...");
        await _authService.logout(); // Forzamos el cierre de sesión
        throw Exception('Token inválido o expirado'); // Lanzamos un error específico para que la UI sepa qué hacer
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data is Map && data.containsKey('values') && data['values'] is List) {
          final List valores = data['values'];
          print("✅ Privilegios procesados correctamente.");
          return valores.map((e) => Privilegio.fromJson(e)).toList();
        } else {
          throw Exception("La respuesta del servidor no tiene el formato esperado.");
        }
      } 
      // Para cualquier otro error del servidor (500, 404, etc.)
      else {
        throw Exception('Error al obtener privilegios. Código: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error CATASTRÓFICO en PrivilegioService: $e");
      // Si el error ya es el que lanzamos nosotros, lo volvemos a lanzar.
      if (e.toString().contains('Token inválido')) {
        throw e;
      }
      // Si es un error de red, lanzamos uno nuevo.
      throw Exception('Fallo en la llamada de red de privilegios: $e');
    }
  }
}