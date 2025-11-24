// models/foto_model.dart
class FotoModel {
  final int id;
  final String url;
  final String? descripcion;
  final String fechaCreacion;
  final bool isActive;

  FotoModel({
    required this.id,
    required this.url,
    this.descripcion,
    required this.fechaCreacion,
    required this.isActive,
  });

  factory FotoModel.fromJson(Map<String, dynamic> json) => FotoModel(
    id: json['id'] ?? 0,
    url: json['url'] ?? '',
    descripcion: json['descripcion'], // Este puede ser null porque es String?
    fechaCreacion: json['fecha_creacion'] ?? '',
    isActive: json['is_active'] ?? false,
  );
}

// models/tipo_inmueble_model.dart
class TipoInmuebleModel {
  final int id;
  final String nombre;
  final String descripcion;
  final bool isActive;

  TipoInmuebleModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.isActive,
  });

  factory TipoInmuebleModel.fromJson(Map<String, dynamic> json) =>
      TipoInmuebleModel(
        id: json['id'] ?? 0,
        nombre: json['nombre']?.toString() ?? 'Sin categoría',
        descripcion: json['descripcion']?.toString() ?? '',
        isActive: json['is_active'] ?? false,
      );
}

class InmuebleModel {
  final int id;
  final List<FotoModel>? fotos;
  final TipoInmuebleModel tipoInmueble;
  final String titulo;
  final String descripcion;
  final String direccion;
  final String ciudad;
  final String zona;
  final String superficie;
  final int dormitorios;
  final int banos;
  final String precio;
  final String tipoOperacion;
  final String estado;
  final double latitud;
  final double longitud;
  final bool isActive;
  final int agente;
  final int cliente;

  InmuebleModel({
    required this.id,
    this.fotos,
    required this.tipoInmueble,
    required this.titulo,
    required this.descripcion,
    required this.direccion,
    required this.ciudad,
    required this.zona,
    required this.superficie,
    required this.dormitorios,
    required this.banos,
    required this.precio,
    required this.tipoOperacion,
    required this.estado,
    required this.latitud,
    required this.longitud,
    required this.isActive,
    required this.agente,
    required this.cliente,
  });

  factory InmuebleModel.fromJson(Map<String, dynamic> json) {
    // 🛡️ HELPERS DE SEGURIDAD 🛡️
    // Estas funciones locales evitan que la app se cierre si falta un dato

    // Convierte cualquier cosa a String. Si es null, devuelve cadena vacía.
    String parseString(dynamic val) => val?.toString() ?? '';

    // Convierte a int de forma segura.
    int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;

    // Convierte a double de forma segura (para coordenadas).
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return InmuebleModel(
      id: json['id'] ?? 0,
      
      fotos: (json['fotos'] as List?)
          ?.map((f) => FotoModel.fromJson(f))
          .toList() ?? [],

      // Si 'tipo_inmueble' es null, creamos uno genérico para no romper la app
      tipoInmueble: json['tipo_inmueble'] != null
          ? TipoInmuebleModel.fromJson(json['tipo_inmueble'])
          : TipoInmuebleModel(id: 0, nombre: 'N/A', descripcion: '', isActive: false),

      // Usamos el helper parseString para todos los textos obligatorios
      titulo: parseString(json['titulo']),
      descripcion: parseString(json['descripcion']),
      direccion: parseString(json['direccion']),
      ciudad: parseString(json['ciudad']),
      zona: parseString(json['zona']),
      superficie: parseString(json['superficie']),
      
      dormitorios: parseInt(json['dormitorios']),
      // Intenta leer 'baños' (con ñ) y si no existe, busca 'banos' (sin ñ)
      banos: parseInt(json['baños'] ?? json['banos']),
      
      precio: parseString(json['precio']),
      tipoOperacion: parseString(json['tipo_operacion']),
      estado: parseString(json['estado']),
      
      // Parseo seguro de coordenadas
      latitud: parseDouble(json['latitud']),
      longitud: parseDouble(json['longitud']),
      
      isActive: json['is_active'] ?? false,
      agente: parseInt(json['agente']),
      cliente: parseInt(json['cliente']),
    );
  }
}