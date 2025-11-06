// lib/services/reportes/reportes_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ReportesService {
  Future<List<dynamic>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return [
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
      token.isEmpty
    ];
  }

  // --- Helper: parsear filename de Content-Disposition ---
  String _parseFilename(Map<String, String> headers, {String fallback = 'reporte.pdf'}) {
  final dispo = (headers['content-disposition'] ?? headers['Content-Disposition'] ?? '').trim();
  if (dispo.isEmpty) return fallback;

  // 1) filename* = UTF-8''nombre%20con%20espacios.pdf
  final mStar = RegExp(
    r"filename\*\s*=\s*(?:UTF-8''|utf-8'')?([^;]+)",
    caseSensitive: false,
  ).firstMatch(dispo);
  if (mStar != null && mStar.groupCount >= 1) {
    final raw = mStar.group(1)!.trim().replaceAll('"', '');
    try {
      return Uri.decodeFull(raw);
    } catch (_) {
      return raw;
    }
  }

  // 2) filename="nombre con espacios.pdf"
  final mQuoted = RegExp(r'filename\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(dispo);
  if (mQuoted != null && mQuoted.groupCount >= 1) {
    return mQuoted.group(1)!.trim();
  }

  // 3) filename=nombre_sin_comillas.pdf
  final mBare = RegExp(r'filename\s*=\s*([^;]+)', caseSensitive: false).firstMatch(dispo);
  if (mBare != null && mBare.groupCount >= 1) {
    return mBare.group(1)!.trim().replaceAll('"', '');
  }

  return fallback;
}
  // --- Helper: decodificar respuesta JSON segura ---
  List<dynamic> _handleResponse(http.Response response) {
    dynamic data;
    final rawBody = utf8.decode(response.bodyBytes);
    try {
      data = jsonDecode(rawBody);
    } catch (_) {
      throw Exception("Error del servidor: $rawBody");
    }
    if (response.statusCode == 200) {
      if (data is List<dynamic>) return data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'] as List<dynamic>;
      }
      throw Exception("Respuesta 200 pero JSON inesperado.");
    }
    if (data is Map<String, dynamic> && data['error'] is String) {
      throw Exception(data['error']);
    }
    throw Exception(data.toString());
  }

  /// IA: /reportes/generar-json/
  Future<List<dynamic>> generarReporteIA(String prompt) async {
    final [headers, sinToken] = await _getAuthHeaders();
    if (sinToken) throw Exception('Token inválido');

    final url = Uri.parse('${Config.baseUrl}/reportes/generar-json/');
    final res = await http.post(url,
        headers: headers as Map<String, String>,
        body: jsonEncode({'prompt': prompt}));

    return _handleResponse(res);
  }

  /// Rápido: /reportes/directo/
  Future<List<dynamic>> generarReporteDirecto(Map<String, dynamic> builderJson) async {
    final [headers, sinToken] = await _getAuthHeaders();
    if (sinToken) throw Exception('Token inválido');

    final url = Uri.parse('${Config.baseUrl}/reportes/directo/');
    final res = await http.post(url,
        headers: headers as Map<String, String>,
        body: jsonEncode(builderJson));

    return _handleResponse(res);
  }

  /// ✅ Exportar PDF (descarga y guarda en /tmp del dispositivo)
  /// Retorna la ruta del archivo guardado.
  Future<String> exportarReportePdf({
    required List<dynamic> data,
    required String prompt,
  }) async {
    final [headers, sinToken] = await _getAuthHeaders();
    if (sinToken) throw Exception('Token inválido');

    final url = Uri.parse('${Config.baseUrl}/reportes/exportar/');
    final body = jsonEncode({
      'data': data,
      'formato': 'pdf',
      'prompt': prompt,
    });

    final res = await http.post(url, headers: headers as Map<String, String>, body: body);

    if (res.statusCode == 200) {
      final bytes = res.bodyBytes;
      final filename = _parseFilename(
        res.headers,
        fallback: 'reporte_${DateTime.now().toIso8601String().substring(0,10)}.pdf',
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');

      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    // Intentar mensaje del backend si no fue 200
    try {
      final m = jsonDecode(utf8.decode(res.bodyBytes));
      if (m is Map && m['message'] is String) {
        throw Exception('No se pudo exportar: ${m['message']}');
      }
    } catch (_) {}
    throw Exception('No se pudo exportar el PDF (HTTP ${res.statusCode}).');
  }
}
