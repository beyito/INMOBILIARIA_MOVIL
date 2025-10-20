// lib/services/desempeno_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/desempeno/desempeno_model.dart';
import 'package:movil_inmobiliaria/config/config.dart';

class DesempenoService {
  Future<DesempenoModel> getDesempenoAgente(int agenteId) async {
    // ... tu función existente no cambia ...
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('${Config.baseUrl}/api/desempeno/anuncios/agente/$agenteId/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DesempenoModel.fromJson(data);
    } else {
      throw Exception('Error al cargar el reporte de desempeño');
    }
  }

  // V--- AÑADE ESTA NUEVA FUNCIÓN ---V
  Future<String> getReporteIA(DesempenoModel desempenoData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse('${Config.baseUrl}/api/desempeno/reporte_ia_gemini/');

    // Construimos el payload tal como lo hace el frontend web
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
      final data = jsonDecode(response.body);
      // Replicamos la lógica web para encontrar el texto del reporte
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