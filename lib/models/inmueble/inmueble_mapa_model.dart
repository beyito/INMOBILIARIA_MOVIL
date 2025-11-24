class InmuebleMapaModel {
  final int id;
  final double latitud;
  final double longitud;
  final String titulo;
  final String precio;
  final String tipoOperacion;
  final String? imagen; // Puede venir null si no hay fotos

  InmuebleMapaModel({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.titulo,
    required this.precio,
    required this.tipoOperacion,
    this.imagen,
  });

  factory InmuebleMapaModel.fromJson(Map<String, dynamic> json) {
    return InmuebleMapaModel(
      id: json['id'],
      // Parseo seguro de coordenadas (pueden venir como String o Double)
      latitud: json['latitud'] is String 
          ? double.parse(json['latitud']) 
          : (json['latitud'] as num).toDouble(),
      longitud: json['longitud'] is String 
          ? double.parse(json['longitud']) 
          : (json['longitud'] as num).toDouble(),
      titulo: json['titulo'] ?? 'Sin Título',
      precio: json['precio'].toString(),
      tipoOperacion: json['tipo_operacion'] ?? 'Venta',
      // Aquí tomamos el campo calculado que agregamos en Django
      imagen: json['imagen_principal'], 
    );
  }
}