class SolicitudAgente {
  final int idSolicitud;
  final String nombre;
  final String correo;
  final String telefono;
  final String numeroLicencia;
  final int experiencia;
  final String ci;
  final String estado;
  final String fechaSolicitud;

  SolicitudAgente({
    required this.idSolicitud,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.numeroLicencia,
    required this.experiencia,
    required this.ci,
    required this.estado,
    required this.fechaSolicitud,
  });

  factory SolicitudAgente.fromJson(Map<String, dynamic> json) =>
      SolicitudAgente(
        idSolicitud: json['idSolicitud'],
        nombre: json['nombre'],
        correo: json['correo'],
        telefono: json['telefono'],
        numeroLicencia: json['numero_licencia'],
        experiencia: json['experiencia'],
        ci: json['ci'],
        estado: json['estado'],
        fechaSolicitud: json['fecha_solicitud'],
      );

  Map<String, dynamic> toJson() => {
    "idSolicitud": idSolicitud,
    "nombre": nombre,
    "correo": correo,
    "telefono": telefono,
    "numero_licencia": numeroLicencia,
    "experiencia": experiencia,
    "ci": ci,
    "estado": estado,
    "fecha_solicitud": fechaSolicitud,
  };
}
