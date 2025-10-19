class CitaModel {
  final int id;
  final String titulo;
  final String? descripcion;

  final int agente;
  final int cliente;
  final String? agenteNombre;
  final String? clienteNombre;

  final int? inmuebleId;
  final String? ubicacion;

  final String fechaCita; // YYYY-MM-DD
  final String horaInicio; // HH:MM:SS
  final String horaFin; // HH:MM:SS

  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  CitaModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.agente,
    required this.cliente,
    this.agenteNombre,
    this.clienteNombre,
    this.inmuebleId,
    this.ubicacion,
    required this.fechaCita,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory CitaModel.fromJson(Map<String, dynamic> m) {
    int asInt(dynamic v, {int def = 0}) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    String asStr(dynamic v, {String def = ""}) {
      if (v == null) return def;
      return v.toString();
    }

    DateTime asDt(dynamic v, {DateTime? def}) {
      if (v == null) return def ?? DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return def ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return CitaModel(
      id: asInt(m["id"], def: 0),
      titulo: asStr(m["titulo"], def: "Sin título"),
      descripcion: m["descripcion"]?.toString(),

      agente: asInt(m["agente"], def: 0),
      cliente: asInt(m["cliente"], def: 0),
      agenteNombre: m["agente_nombre"]?.toString(),
      clienteNombre: m["cliente_nombre"]?.toString(),

      inmuebleId: (m["inmueble_id"] == null) ? null : asInt(m["inmueble_id"]),
      ubicacion: m["ubicacion"]?.toString(),

      fechaCita: asStr(m["fecha_cita"], def: "1970-01-01"),
      horaInicio: asStr(m["hora_inicio"], def: "00:00:00"),
      horaFin: asStr(m["hora_fin"], def: "00:00:00"),

      estado: asStr(m["estado"], def: "PENDIENTE"),
      creadoEn: asDt(m["creado_en"]),
      actualizadoEn: (m["actualizado_en"] != null)
          ? asDt(m["actualizado_en"])
          : null,
    );
  }
}
