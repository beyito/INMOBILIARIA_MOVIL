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

    final response = await http.get(
      Uri.parse('$baseUrl/get_privilegios'),
      headers: {'Authorization': 'Token $token'},
    );

    print('JSON RECIBIDO DE PRIVILEGIOS: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List valores = data['values'];
      return valores.map((e) => Privilegio.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener privilegios');
    }
  }
}
