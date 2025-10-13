//import 'package:movil_condominio/models/usuario_model.dart';

class NoticiaModel {
  final int? id;
  final String? titulo;
  final String? descripcion;
  final String? imagenUrl;
  final String? administrador;
  final String? creadoEn;
  final String? expiraEn;

  NoticiaModel({
    this.id,
    this.titulo,
    this.descripcion,
    this.imagenUrl,
    required this.administrador,
    this.creadoEn,
    this.expiraEn = "",
  });

  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    return NoticiaModel(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'],
      administrador: json['administrador'],
      creadoEn: json['fecha_publicacion'],
      expiraEn: json['fecha_vencimiento'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'imagenUrl': imagenUrl,
    'administrador': administrador,
    'creadoEn': creadoEn,
    'expiraEn': expiraEn,
  };
}
