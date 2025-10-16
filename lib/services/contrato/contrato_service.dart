import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/contrato/contrato_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class ContratoService {
  final String baseUrl = '${Config.baseUrl}/usuario';

  // ✅ VERSIÓN SIMPLE - Sin Uint8List
  Future<File?> generarContratoServicios(ContratoServicios contrato) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/generarContratoDeServiciosPdf'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(contrato.toJson()),
      );

      if (response.statusCode == 200) {
        // Guardar directamente como archivo
        final directory = await getTemporaryDirectory();
        final fileName =
            'contrato_${contrato.clienteNombre}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        print('✅ PDF generado - Tamaño: ${response.bodyBytes.length} bytes');
        print('📁 PDF guardado en: ${file.path}');

        return file;
      } else if (response.statusCode == 403) {
        throw Exception('No tiene permisos para generar contratos');
      } else {
        throw Exception('Error al generar contrato: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
