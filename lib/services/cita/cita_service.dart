import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import '../../models/cita/cita_model.dart';

class CitaService {
  final String base = '${Config.baseUrl}/cita';

  Future<List<CitaModel>> listar({
    bool mias = true,
    String? desde, // "YYYY-MM-DD"
    String? hasta, // "YYYY-MM-DD"
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final qs = <String>[
      if (mias) 'mias=1',
      if (desde != null) 'desde=$desde',
      if (hasta != null) 'hasta=$hasta',
    ].join('&');

    // 👈 usa la ruta correcta del backend
    final uri = Uri.parse('${Config.baseUrl}/cita/?$qs');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Token $token', 'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Error al listar citas (HTTP ${res.statusCode})');
    }

    final decoded = json.decode(res.body);

    // El backend devuelve: {"values": {"citas": [ ... ]}}
    List raw = const [];
    if (decoded is Map &&
        decoded['values'] is Map &&
        (decoded['values'] as Map)['citas'] is List) {
      raw = (decoded['values'] as Map)['citas'] as List;
    } else if (decoded is Map && decoded['citas'] is List) {
      raw = decoded['citas'] as List;
    } else if (decoded is List) {
      raw = decoded;
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => CitaModel.fromJson(e))
        .toList();
  }

  Future<CitaModel> crear(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$base/crear/');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (res.statusCode >= 300) {
      throw Exception('Error al crear cita');
    }
    final m = json.decode(res.body)['values'];
    return CitaModel.fromJson(m);
  }

  Future<CitaModel> reprogramar(int id, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$base/$id/reprogramar/');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (res.statusCode >= 300) {
      throw Exception('Error al reprogramar');
    }
    final m = json.decode(res.body)['values'];
    return CitaModel.fromJson(m);
  }

  Future<void> eliminar(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$base/$id/eliminar/');
    final res = await http.delete(
      uri,
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode >= 300) {
      throw Exception('Error al eliminar');
    }
  }
}
