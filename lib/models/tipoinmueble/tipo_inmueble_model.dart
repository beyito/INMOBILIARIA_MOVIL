// lib/models/tipo_inmueble_model.dart

import 'dart:convert';


class TipoInmueble {
  final int id;
  final String nombre;
  final String? descripcion; // Puede ser nulo
  final bool isActive;

  TipoInmueble({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.isActive,
  });

  // Fábrica para crear una instancia desde un mapa JSON
  factory TipoInmueble.fromJson(Map<String, dynamic> json) {
    return TipoInmueble(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      isActive: json['is_active'],
    );
  }

  // Método para convertir una instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}