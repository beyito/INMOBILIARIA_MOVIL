// services/comisiones/comisiones_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/comisiones/comisiones_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ComisionesService {
  final String baseUrl = '${Config.baseUrl}/contrato';

  Future<ComisionesAgente?> getDetalleComisionesAgente({
    required int agenteId,
    String? fechaInicio,
    String? fechaFin,
    String? tipoContrato,
    bool incluirServicios = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Construir parámetros
      final params = <String, String>{};
      if (fechaInicio != null && fechaInicio.isNotEmpty) {
        params['fecha_inicio'] = fechaInicio;
      }
      if (fechaFin != null && fechaFin.isNotEmpty) {
        params['fecha_fin'] = fechaFin;
      }
      if (tipoContrato != null && tipoContrato != 'todos') {
        params['tipo_contrato'] = tipoContrato;
      }
      params['incluir_servicios'] = incluirServicios.toString();

      final queryString = Uri(queryParameters: params).query;
      final url = '$baseUrl/comisiones/agente/$agenteId?$queryString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ComisionesAgente.fromJson(data['values']);
      } else {
        throw Exception('Error al cargar comisiones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
