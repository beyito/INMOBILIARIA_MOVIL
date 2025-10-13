class UsuarioModel {
  final int? id;
  final String? username;
  final String? nombre;
  final String? correo;
  final String? telefono;
  final int? grupo_id;
  final String? grupo_nombre;
  final String? ci;
  final String? fecha_nacimiento;
  final String? ubicacion;

  UsuarioModel({
    this.id,
    this.username,
    this.nombre,
    this.correo,
    this.telefono,
    this.grupo_id,
    this.grupo_nombre,
    this.ci,
    this.fecha_nacimiento,
    this.ubicacion,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] ?? json;
    return UsuarioModel(
      id: usuario['id'] ?? 0,
      username: usuario['username'] ?? "",
      nombre: usuario['nombre'] ?? "",
      correo: usuario['correo'] ?? "",
      telefono: usuario['telefono'] ?? "",
      grupo_id: usuario['grupo_id'] ?? 0,
      grupo_nombre: usuario['grupo_nombre'] ?? "",
      ci: usuario['ci'] ?? "",
      fecha_nacimiento: usuario['fecha_nacimiento'] ?? "",
      ubicacion: usuario['ubicacion'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nombre': nombre,
    'correo': correo,
    'grupo_id': grupo_id,
    'grupo_nombre': grupo_nombre,
    'telefono': telefono,
    'ci': ci,
    'fecha_nacimiento': fecha_nacimiento,
    'ubicacion': ubicacion,
  };
}
