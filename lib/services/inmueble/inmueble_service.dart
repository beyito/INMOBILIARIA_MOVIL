// services/inmueble_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/inmueble/inmueble_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'dart:io';

// services/inmueble_service.dart - AGREGAR estas clases y métodos

class ProgresoSubida {
  final int total;
  final int completadas;
  final String estado; // 'subiendo', 'procesando', 'completado'

  ProgresoSubida({
    required this.total,
    required this.completadas,
    required this.estado,
  });

  double get porcentaje => total > 0 ? completadas / total : 0;
}

class InmuebleService {
  final String baseUrl = '${Config.baseUrl}/inmueble';
  final String baseUrlContacto =
      '${Config.baseUrl}/contacto'; // Cambia por tu URL real
  final String cloudName = 'dlawwnr7o'; // 👈 pon tu cloud name
  final String uploadPreset = 'inmobiliaria_preset'; // 👈 tu preset unsigned

  Future<List<InmuebleModel>> listarDisponibles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/listar_anuncios_disponibles'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final inmueblesJson = data['values']['inmueble'] as List;
      return inmueblesJson.map((i) => InmuebleModel.fromJson(i)).toList();
    } else {
      throw Exception('Error al cargar los inmuebles');
    }
  }

  // 🔹 Obtener lista de clientes desde chats
  Future<List<Map<String, dynamic>>> obtenerClientesChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrlContacto/chats/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final chats = body['values'] as List;

      // Extraemos solo el cliente de cada chat
      final clientesMap = chats.map<Map<String, dynamic>>((chat) {
        final cliente = chat['cliente'] as Map<String, dynamic>;
        return {
          'id': cliente['id'],
          'nombre': cliente['nombre'],
          'username': cliente['username'],
          'grupo_nombre': cliente['grupo_nombre'],
        };
      }).toList();

      // 🔹 Eliminamos duplicados por id
      final ids = <int>{};
      final clientesUnicos = <Map<String, dynamic>>[];
      for (var c in clientesMap) {
        if (!ids.contains(c['id'])) {
          ids.add(c['id']);
          clientesUnicos.add(c);
        }
      }

      return clientesUnicos;
    } else {
      throw Exception('Error al obtener clientes desde chats');
    }
  }

  // Obtener tipos de inmueble
  Future<List<Map<String, dynamic>>> obtenerTiposInmueble() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/listar_tipo_inmuebles'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tiposJson = data['values']['tipo_inmueble'] as List;
      return tiposJson
          .map<Map<String, dynamic>>((t) => t as Map<String, dynamic>)
          .toList();
    } else {
      throw Exception('Error al cargar los tipos de inmueble');
    }
  }

  // 🔹 Subir una imagen a Cloudinary
  Future<String> subirImagen(File imagen) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final uploadRequest = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imagen.path));

    final response = await uploadRequest.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data['secure_url']; // ✅ URL pública de la imagen
    } else {
      throw Exception('Error al subir la imagen: ${response.statusCode}');
    }
  }

  // 🔹 Registrar inmueble (después de subir fotos)
  Future<void> registrarInmueble({
    required Map<String, dynamic> data,
    required List<File> fotosLocales,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // 1️⃣ Subir fotos a Cloudinary
    List<String> fotosUrls = [];
    for (var foto in fotosLocales) {
      final url = await subirImagen(foto);
      fotosUrls.add(url);
    }

    // 2️⃣ Agregar URLs al payload
    data['fotos_urls'] = fotosUrls;

    // 3️⃣ Enviar inmueble al backend
    final response = await http.post(
      Uri.parse('$baseUrl/agente_registrar_inmueble'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);
    print(body);
    if (response.statusCode != 200 || body['status'] != 1) {
      throw Exception(body['message'] ?? 'Error al registrar el inmueble');
    }
  }

  Future<void> registrarInmuebleConProgreso({
    required Map<String, dynamic> data,
    required List<File> fotosLocales,
    required Function(ProgresoSubida) onProgreso,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // 1️⃣ Notificar inicio de subida
    onProgreso(
      ProgresoSubida(
        total: fotosLocales.length,
        completadas: 0,
        estado: 'Subiendo imágenes...',
      ),
    );

    // 2️⃣ Subir fotos con progreso
    List<String> fotosUrls = [];
    for (int i = 0; i < fotosLocales.length; i++) {
      try {
        onProgreso(
          ProgresoSubida(
            total: fotosLocales.length,
            completadas: i,
            estado: 'Subiendo imagen ${i + 1} de ${fotosLocales.length}',
          ),
        );

        final url = await subirImagen(fotosLocales[i]);
        fotosUrls.add(url);

        onProgreso(
          ProgresoSubida(
            total: fotosLocales.length,
            completadas: i + 1,
            estado: 'Imagen ${i + 1} completada',
          ),
        );

        // Pequeña pausa para que se vea el progreso
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        throw Exception('Error subiendo imagen ${i + 1}: $e');
      }
    }

    // 3️⃣ Notificar procesamiento de datos
    onProgreso(
      ProgresoSubida(
        total: fotosLocales.length,
        completadas: fotosLocales.length,
        estado: 'Procesando datos del inmueble...',
      ),
    );

    // 4️⃣ Agregar URLs al payload
    data['fotos_urls'] = fotosUrls;

    // 5️⃣ Enviar inmueble al backend
    final response = await http.post(
      Uri.parse('$baseUrl/agente_registrar_inmueble'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);
    print('Respuesta del servidor: $body');

    if (response.statusCode != 200 || body['status'] != 1) {
      throw Exception(body['message'] ?? 'Error al registrar el inmueble');
    }

    // 6️⃣ Notificar completado
    onProgreso(
      ProgresoSubida(
        total: fotosLocales.length,
        completadas: fotosLocales.length,
        estado: '¡Inmueble registrado exitosamente!',
      ),
    );
  }

  // APARTADO DE MIS INMUEBLES
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///
  // services/inmueble/mis_inmuebles_service.dart
  Future<List<InmuebleModel>> obtenerMisInmuebles({String? estado}) async {
    print('🔹 Filtrando inmuebles por estado: $estado');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Construir URL con query parameters
      final uri = Uri.parse('$baseUrl/todos-mis-inmuebles').replace(
        queryParameters: estado != null && estado != 'todos'
            ? {'estado': estado}
            : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔹 Status Code: ${response.statusCode}');
      print('🔹 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Verificar estructura de la respuesta
        if (body['status'] == 1 && body['values'] != null) {
          final inmueblesJson = body['values']['inmuebles'] as List;
          print('🔹 Inmuebles encontrados: ${inmueblesJson.length}');

          // Mapear con manejo de errores individuales
          final inmuebles = <InmuebleModel>[];
          for (var i = 0; i < inmueblesJson.length; i++) {
            try {
              final inmueble = InmuebleModel.fromJson(inmueblesJson[i]);
              inmuebles.add(inmueble);
            } catch (e) {
              print('❌ Error parseando inmueble $i: $e');
              print('❌ JSON problemático: ${inmueblesJson[i]}');
            }
          }

          return inmuebles;
        } else {
          throw Exception(
            'Error en respuesta del servidor: ${body['message']}',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado - Token inválido');
      } else if (response.statusCode == 403) {
        throw Exception('No tiene permisos para ver inmuebles');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerMisInmuebles: $e');
      rethrow;
    }
  }

  // services/inmueble/inmueble_service.dart

  // 🔹 PUBLICAR INMUEBLE - Siempre crea anuncio con estado 'disponible' y active=true
  Future<bool> publicarInmueble(int inmuebleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/anuncio/crear/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inmueble': inmuebleId, 'estado': 'disponible'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['status'] == 1;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        body['message'] ?? 'Error al publicar inmueble: ${response.statusCode}',
      );
    }
  }

  // 🔹 CAMBIAR ESTADO DEL ANUNCIO - Solo cambia el estado comercial
  Future<bool> cambiarEstadoAnuncio(int inmuebleId, String nuevoEstado) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Primero necesitamos obtener el ID del anuncio
    final anuncioId = await _obtenerAnuncioIdDeInmueble(inmuebleId);

    if (anuncioId == null) {
      throw Exception('No se encontró el anuncio para este inmueble');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/anuncio/$anuncioId/actualizar/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': nuevoEstado}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['status'] == 1;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        body['message'] ?? 'Error al cambiar estado: ${response.statusCode}',
      );
    }
  }

  // 🔹 QUITAR PUBLICACIÓN - Solo pone is_active = false
  Future<bool> quitarPublicacion(int inmuebleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Primero necesitamos obtener el ID del anuncio
    final anuncioId = await _obtenerAnuncioIdDeInmueble(inmuebleId);

    if (anuncioId == null) {
      throw Exception('No se encontró el anuncio para este inmueble');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/anuncio/$anuncioId/actualizar/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_active': false}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['status'] == 1;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        body['message'] ??
            'Error al quitar publicación: ${response.statusCode}',
      );
    }
  }

  Future<bool> activarPublicacion(int inmuebleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Primero necesitamos obtener el ID del anuncio
    final anuncioId = await _obtenerAnuncioIdDeInmueble(inmuebleId);

    if (anuncioId == null) {
      throw Exception('No se encontró el anuncio para este inmueble');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/anuncio/$anuncioId/actualizar/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_active': true}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['status'] == 1;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        body['message'] ??
            'Error al activar la publicación: ${response.statusCode}',
      );
    }
  }

  // 🔹 MÉTODO PRIVADO: Obtener ID del anuncio desde el inmueble
  // 🔹 MÉTODO PRIVADO: Obtener ID del anuncio desde el inmueble
  Future<int?> _obtenerAnuncioIdDeInmueble(int inmuebleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      // Opción 1: Si tienes un endpoint específico
      final response = await http.get(
        Uri.parse('$baseUrl/anuncio/$inmuebleId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 1 && body['values'] != null) {
          return body['values']['id'];
        }
      }

      // Opción 2: Si no hay endpoint específico, podrías obtenerlo de la lista de mis inmuebles
      // Los inmuebles publicados ya deberían tener información del anuncio
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> obtenerEstadoAnuncioDeInmueble(int inmuebleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      // Opción 1: Si tienes un endpoint específico
      final response = await http.get(
        Uri.parse('$baseUrl/anuncio/$inmuebleId/estado_anuncio_id_inmueble/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 1 &&
            body['values'] != null &&
            body['values']['tiene_anuncio'] == true &&
            body['values']['anuncio']['is_active'] == false) {
          print("El anuncio está eliminado");
          return "eliminado"; // Valor por defecto si no hay anuncio
        }
        if (body['status'] == 1 &&
            body['values'] != null &&
            body['values']['tiene_anuncio'] == true &&
            body['values']['anuncio']['is_active'] == true) {
          print("El anuncio está disponible");
          return body['values']['anuncio']['estado'];
        }
      }

      // Opción 2: Si no hay endpoint específico, podrías obtenerlo de la lista de mis inmuebles
      // Los inmuebles publicados ya deberían tener información del anuncio
      return "";
    } catch (e) {
      return "";
    }
  }

  // Métodos auxiliares para la UI
  List<String> obtenerEstadosDisponibles() {
    return ['todos', 'pendiente', 'aprobado', 'publicados', 'rechazado'];
  }

  String obtenerTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobados';
      case 'publicados':
        return 'Publicados';
      case 'rechazado':
        return 'Rechazados';
      default:
        return 'Todos';
    }
  }

  String obtenerDescripcionEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'En espera de aprobación';
      case 'aprobado':
        return 'Aprobados sin publicar';
      case 'publicados':
        return 'Publicados y disponibles';
      case 'rechazado':
        return 'Rechazados por administración';
      default:
        return 'Todos mis inmuebles';
    }
  }

  Color obtenerColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobado':
        return Colors.green;
      case 'publicados':
        return Colors.blue;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'aprobado':
        return Icons.check_circle;
      case 'publicados':
        return Icons.public;
      case 'rechazado':
        return Icons.cancel;
      default:
        return Icons.all_inbox;
    }
  }

  // 🔹 Determinar si un inmueble puede ser publicado
  bool puedePublicar(InmuebleModel inmueble) {
    return inmueble.estado == 'aprobado';
  }

  // 🔹 Determinar si un inmueble está publicado
  bool estaPublicado(InmuebleModel inmueble) {
    // Según tu lógica del backend, los publicados tienen estado 'aprobado'
    // y un anuncio activo con estado 'disponible'
    // Esto lo determinaremos por el filtro que uses
    return false; // Se determinará por contexto
  }

  // 🔹 NUEVO: Estados disponibles para anuncios publicados
  List<String> obtenerEstadosAnuncio() {
    return ['disponible', 'alquilado', 'vendido', 'anticretico'];
  }

  String obtenerTextoEstadoAnuncio(String estado) {
    switch (estado) {
      case 'disponible':
        return 'Disponible';
      case 'alquilado':
        return 'Alquilado';
      case 'vendido':
        return 'Vendido';
      case 'anticretico':
        return 'Anticrético';
      default:
        return estado;
    }
  }

  // 🔹 NUEVO: Tipos de operación para filtros
  List<String> obtenerTiposOperacion() {
    return ['todos', 'venta', 'alquiler', 'anticretico'];
  }

  String obtenerTextoTipoOperacion(String tipo) {
    switch (tipo) {
      case 'venta':
        return 'Venta';
      case 'alquiler':
        return 'Alquiler';
      case 'anticretico':
        return 'Anticrético';
      default:
        return 'Todos';
    }
  }
}
