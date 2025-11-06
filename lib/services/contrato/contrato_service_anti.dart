import 'dart:convert';
import 'dart:typed_data'; // Importante para los bytes del PDF
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ContratoService {
  // --- Helper de Autenticación ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) throw Exception('Token inválido');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  // --- Helper para manejar respuestas JSON ---
  dynamic _handleJsonResponse(http.Response response) {
    dynamic data;
    String rawBody = utf8.decode(response.bodyBytes);
    try {
      data = jsonDecode(rawBody);
    } catch (e) {
      throw Exception("Error del servidor (No-JSON): $rawBody");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        throw Exception(data['error']);
      }
      throw Exception(data.toString());
    }
  }

  // --- Implementación de Endpoints ---

  Future<List<dynamic>> getListaContratosAnticretico() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/listar-anticretico/');
    final response = await http.get(url, headers: headers);
    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> getContratoDetalle(int contratoId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/detalle/$contratoId/');
    final response = await http.get(url, headers: headers);
    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> aprobarContrato(int contratoId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/aprobar/$contratoId/');
    final response = await http.patch(url, headers: headers);
    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> finalizarContrato(int contratoId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/finalizar/$contratoId/');
    final response = await http.patch(url, headers: headers);
    return _handleJsonResponse(response);
  }
  
  Future<Map<String, dynamic>> crearContratoAnticretico(Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/crear-contrato-anticretico/');
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    return _handleJsonResponse(response);
  }

  // --- Endpoints para el formulario ---
  Future<List<dynamic>> getInmueblesDisponibles() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/inmueble/listar_anuncios_disponibles');
    final response = await http.get(url, headers: headers);
    final data = _handleJsonResponse(response);
    // Tu API devuelve { values: { inmueble: [...] } }
    return data['values']?['inmueble'] as List<dynamic>? ?? [];
  }
  
  Future<List<dynamic>> getAgentes() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/usuario/listar-agentes');
    final response = await http.get(url, headers: headers);
    final data = _handleJsonResponse(response);
     // Tu API devuelve { values: [...] }
    return data['values'] as List<dynamic>? ?? [];
  }

  // --- ✅ FUNCIÓN ESPECIAL PARA PDF ---
  Future<Uint8List> descargarContratoPDF(int contratoId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${Config.baseUrl}/contrato/descargar-pdf/$contratoId/');
    
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // Devuelve los bytes crudos del archivo
        return response.bodyBytes;
      } else {
        // Si hay un error (ej. 404), intenta decodificar el error
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['message'] ?? 'Error al descargar el PDF');
      }
    } catch (e) {
      print("Error en descargarContratoPDF: $e");
      rethrow;
    }
  }
}