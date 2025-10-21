// lib/models/desempeno/desempeno_model.dart

class DesempenoModel {
  final int agenteId;
  final TotalesModel totales;
  final EstadosModel estados;
  final KpisModel kpis;

  DesempenoModel({
    required this.agenteId,
    required this.totales,
    required this.estados,
    required this.kpis,
  });

  factory DesempenoModel.fromJson(Map<String, dynamic> json) => DesempenoModel(
        agenteId: json['agente_id'] ?? 0,
        totales: TotalesModel.fromJson(json['totales'] ?? {}),
        estados: EstadosModel.fromJson(json['estados'] ?? {}),
        kpis: KpisModel.fromJson(json['kpis'] ?? {}),
      );
}

class TotalesModel {
  final int publicaciones;
  final int publicacionesConAnuncio;
  final int anuncios;

  TotalesModel({
    required this.publicaciones,
    required this.publicacionesConAnuncio,
    required this.anuncios,
  });

  factory TotalesModel.fromJson(Map<String, dynamic> json) => TotalesModel(
        publicaciones: json['publicaciones'] ?? 0,
        publicacionesConAnuncio: json['publicaciones_con_anuncio'] ?? 0,
        anuncios: json['anuncios'] ?? 0,
      );
}

class EstadosModel {
  final EstadoDetalleModel vendido;
  final EstadoDetalleModel anticretico;
  final EstadoDetalleModel alquilado;
  final EstadoDetalleModel otros;

  EstadosModel({
    required this.vendido,
    required this.anticretico,
    required this.alquilado,
    required this.otros,
  });

  factory EstadosModel.fromJson(Map<String, dynamic> json) => EstadosModel(
        vendido: EstadoDetalleModel.fromJson(json['vendido'] ?? {}),
        anticretico: EstadoDetalleModel.fromJson(json['anticretico'] ?? {}),
        alquilado: EstadoDetalleModel.fromJson(json['alquilado'] ?? {}),
        otros: EstadoDetalleModel.fromJson(json['otros'] ?? {}),
      );

  // ✅ MÉTODO AÑADIDO
  Map<String, dynamic> toJson() => {
        'vendido': vendido.toJson(),
        'anticretico': anticretico.toJson(),
        'alquilado': alquilado.toJson(),
        'otros': otros.toJson(),
      };
}

class EstadoDetalleModel {
  final int count;
  final double pct;

  EstadoDetalleModel({required this.count, required this.pct});

  factory EstadoDetalleModel.fromJson(Map<String, dynamic> json) =>
      EstadoDetalleModel(
        count: json['count'] ?? 0,
        pct: (json['pct'] ?? 0.0).toDouble(),
      );

  // ✅ MÉTODO AÑADIDO
  Map<String, dynamic> toJson() => {
        'count': count,
        'pct': pct,
      };
}

class KpisModel {
  final double desempeno;
  final double tasaPublicacion;
  final String nota;

  KpisModel({
    required this.desempeno,
    required this.tasaPublicacion,
    required this.nota,
  });

  factory KpisModel.fromJson(Map<String, dynamic> json) => KpisModel(
        desempeno: (json['desempeno'] ?? 0.0).toDouble(),
        tasaPublicacion: (json['tasa_publicacion'] ?? 0.0).toDouble(),
        nota: json['nota'] ?? 'N/A',
      );
}