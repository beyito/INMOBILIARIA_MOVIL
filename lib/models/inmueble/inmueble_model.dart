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
    id: json['id'],
    url: json['url'],
    descripcion: json['descripcion'],
    fechaCreacion: json['fecha_creacion'],
    isActive: json['is_active'],
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
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        isActive: json['is_active'],
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

  factory InmuebleModel.fromJson(Map<String, dynamic> json) => InmuebleModel(
    id: json['id'],
    fotos:
        (json['fotos'] as List?)?.map((f) => FotoModel.fromJson(f)).toList() ??
        [],
    tipoInmueble: TipoInmuebleModel.fromJson(json['tipo_inmueble']),
    titulo: json['titulo'],
    descripcion: json['descripcion'],
    direccion: json['direccion'],
    ciudad: json['ciudad'],
    zona: json['zona'],
    superficie: json['superficie'],
    dormitorios: json['dormitorios'],
    banos: json['baños'],
    precio: json['precio'],
    tipoOperacion: json['tipo_operacion'],
    estado: json['estado'],
    latitud: double.parse(json['latitud']),
    longitud: double.parse(json['longitud']),
    isActive: json['is_active'],
    agente: json['agente'],
    cliente: json['cliente'],
  );
}
