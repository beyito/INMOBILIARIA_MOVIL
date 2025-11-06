// lib/services/contrato/contrato_alquiler_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Ajusta esta importación a tu config real
import 'package:movil_inmobiliaria/config/config.dart' show Config;

class ContratoAlquilerService {
  final String baseUrl = Config.baseUrl; // p.ej: http://192.168.100.148:8000

  // =================== HEADERS / AUTH ===================
  Future<Map<String, String>> _authHeaders({bool isJson = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No hay token guardado. Inicia sesión nuevamente.');
    }

    final headers = <String, String>{
      'Authorization': 'Token $token', // Cambia a 'Bearer' si usas JWT
      'Accept': 'application/json',
    };
    if (isJson) headers['Content-Type'] = 'application/json';
    return headers;
  }

  // =================== PERFIL / AGENTE ===================
  /// Intenta leer el id del agente desde SharedPreferences; si no existe,
  /// consulta /usuario/profile, guarda el usuario y devuelve el id.
  Future<int> leerAgenteIdOAsegurarlo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) buscar en prefs claves comunes
    for (final k in ['usuario', 'user', 'profile', 'usuario_json']) {
      final raw = prefs.getString(k);
      if (raw != null && raw.isNotEmpty) {
        try {
          final m = jsonDecode(raw);
          if (m is Map && m['id'] != null) {
            return (m['id'] as num).toInt();
          }
          if (m is Map && m['usuario'] is Map && m['usuario']['id'] != null) {
            return (m['usuario']['id'] as num).toInt();
          }
        } catch (_) {}
      }
    }

    // 2) pedir al backend y guardar
    final uri = Uri.parse('$baseUrl/usuario/profile');
    final res = await http.get(uri, headers: await _authHeaders());

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(utf8.decode(res.bodyBytes));

      int? id;
      Map<String, dynamic>? usuarioPlano;

      if (body is Map && body['values'] is Map && body['values']['usuario'] is Map) {
        id = (body['values']['usuario']['id'] as num?)?.toInt();
        usuarioPlano = Map<String, dynamic>.from(body['values']['usuario'] as Map);
      } else if (body is Map && body['usuario'] is Map) {
        id = (body['usuario']['id'] as num?)?.toInt();
        usuarioPlano = Map<String, dynamic>.from(body['usuario'] as Map);
      } else if (body is Map && body['id'] != null) {
        id = (body['id'] as num?)?.toInt();
        usuarioPlano = Map<String, dynamic>.from(body);
      }

      if (id != null) {
        // guarda bajo la clave estándar 'usuario' para el resto de la app
        await prefs.setString('usuario', jsonEncode(usuarioPlano ?? {'id': id}));
        return id;
      }
      throw Exception('Perfil recibido sin id válido desde /usuario/profile.');
    }

    throw Exception(
      'No se pudo identificar al agente (HTTP ${res.statusCode}). Inicia sesión nuevamente.',
    );
  }

  // =================== CONTRATOS ALQUILER ===================
  /// Genera el contrato y retorna el JSON del backend (debe traer `pdf_url`).
  Future<Map<String, dynamic>> generarContratoAlquiler(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/contrato/generarContratoAlquilerPdf');
    final res = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );

    final decodedBody = _tryDecode(res.bodyBytes);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) return decodedBody;
      throw Exception('Respuesta inesperada al generar contrato.');
    }

    final msg = _extractBackendMessage(decodedBody) ??
        'Error al generar contrato (${res.statusCode})';
    throw Exception(msg);
  }

  /// Lista contratos de alquiler (usa ?tipo=alquiler como en tu web).
  Future<List<dynamic>> listarContratosAlquiler() async {
    final uri = Uri.parse('$baseUrl/contrato/listar?tipo=alquiler');
    final res = await http.get(uri, headers: await _authHeaders());

    final decodedBody = _tryDecode(res.bodyBytes);

    if (res.statusCode == 200) {
      if (decodedBody is Map<String, dynamic>) {
        final valores = decodedBody['values'] ?? {};
        final contratos = valores is Map ? valores['contratos'] : null;
        if (contratos is List) return contratos;
        return <dynamic>[];
      }
      return <dynamic>[];
    }

    final msg = _extractBackendMessage(decodedBody) ??
        'Error al listar contratos (${res.statusCode})';
    throw Exception(msg);
  }

  /// Descarga el PDF del contrato (endpoint `ver/<id>` devuelve blob/pdf).
  Future<Uint8List> obtenerContratoPdf(int id) async {
    final uri = Uri.parse('$baseUrl/contrato/ver/$id');
    final res = await http.get(uri, headers: await _authHeaders(isJson: false));

    if (res.statusCode == 200) return res.bodyBytes;

    // Intentar leer mensaje si vino JSON de error
    final decodedBody = _tryDecode(res.bodyBytes);
    final msg = _extractBackendMessage(decodedBody) ??
        'No se pudo obtener el PDF (${res.statusCode})';
    throw Exception(msg);
  }

  // =================== INMUEBLES ===================
  /// Carga inmuebles disponibles (como en web: SOLO estado "disponible").
  Future<List<dynamic>> listarInmueblesDisponiblesAlquiler() async {
    final uri = Uri.parse('$baseUrl/inmueble/listar_inmuebles');
    final res = await http.get(uri, headers: await _authHeaders());

    final decodedBody = _tryDecode(res.bodyBytes);

    if (res.statusCode == 200) {
      if (decodedBody is Map<String, dynamic>) {
        final valores = decodedBody['values'] ?? {};
        final inmuebles = (valores is Map ? valores['inmuebles'] : null) as List<dynamic>?;

        if (inmuebles == null) return <dynamic>[];

        // ✅ filtro igual a web: SOLO por anuncio.estado == 'disponible'
        final filtrados = inmuebles.where((i) {
          final estado = (i['anuncio']?['estado'] ?? '').toString().toLowerCase();
          return estado == 'disponible';
        }).toList();

        return filtrados;
      }
      return <dynamic>[];
    }

    final msg = _extractBackendMessage(decodedBody) ??
        'Error al listar inmuebles (${res.statusCode})';
    throw Exception(msg);
  }

  // =================== HELPERS ===================
  dynamic _tryDecode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }

  String? _extractBackendMessage(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      if (decodedBody['message'] is String) return decodedBody['message'] as String;
      if (decodedBody['detail'] is String) return decodedBody['detail'] as String;
      if (decodedBody['error'] is String) return decodedBody['error'] as String;
    }
    return null;
  }
}
