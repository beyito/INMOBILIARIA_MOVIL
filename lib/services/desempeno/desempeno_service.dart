// lib/services/desempeno_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/desempeno/desempeno_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class DesempenoService {

  Future<DesempenoModel> getDesempenoAgente(int agenteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('${Config.baseUrl}/api/desempeno/anuncios/agente/$agenteId/');
    
    print("▶️ Realizando petición GET a: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      // --- LÍNEA DE DEPURACIÓN MÁS IMPORTANTE ---
      print("StatusCode: ${response.statusCode}");
      print("✅ Respuesta CRUDA de la API: ${response.body}");
      // -----------------------------------------

      if (response.statusCode == 200) {
        // Usamos utf8.decode para manejar correctamente tildes y caracteres especiales
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return DesempenoModel.fromJson(data);
      } else {
        print("❌ La API respondió con un error. Body: ${response.body}");
        throw Exception('Error al cargar el reporte de desempeño. Código: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error CATASTRÓFICO en el servicio: $e");
      // Re-lanza el error para que la UI sepa que algo falló
      throw Exception('Fallo en la llamada de red: $e');
    }
  }

  // V--- TU FUNCIÓN DE IA NO CAMBIA ---V
  Future<String> getReporteIA(DesempenoModel desempenoData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('${Config.baseUrl}/api/desempeno/reporte_ia_gemini/');

    final payload = {
      "kpis": {
        "publicaciones": desempenoData.totales.publicaciones,
        "publicaciones_con_anuncio": desempenoData.totales.publicacionesConAnuncio,
        "anuncios": desempenoData.totales.anuncios,
        "vendido": desempenoData.estados.vendido.count,
        "anticretico": desempenoData.estados.anticretico.count,
        "alquilado": desempenoData.estados.alquilado.count,
        "otros": desempenoData.estados.otros.count,
        "desempeno": desempenoData.kpis.desempeno,
        "tasa_publicacion": desempenoData.kpis.tasaPublicacion,
      },
      "notas": "Agente ${desempenoData.agenteId} • Datos generados desde la app móvil."
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final texto = data['reporte'] ??
          data['reporte_ia'] ??
          data['values']?['reporte'] ??
          data['values']?['reporte_ia'] ??
          data['text'] ??
          '';
      return texto;
    } else {
      throw Exception('Error al generar el reporte de IA');
    }
  }
}