class Privilegio {
  final String componente;
  final bool puedeCrear;
  final bool puedeActualizar;
  final bool puedeEliminar;
  final bool puedeLeer;
  final bool puedeActivar;

  Privilegio({
    required this.componente,
    required this.puedeCrear,
    required this.puedeActualizar,
    required this.puedeEliminar,
    required this.puedeLeer,
    required this.puedeActivar,
  });

  factory Privilegio.fromJson(Map<String, dynamic> json) {
    return Privilegio(
      componente: json['componente'] ?? '',
      puedeCrear: json['puede_crear'] ?? false,
      puedeActualizar: json['puede_actualizar'] ?? false,
      puedeEliminar: json['puede_eliminar'] ?? false,
      puedeLeer: json['puede_leer'] ?? false,
      puedeActivar: json['puede_activar'] ?? false,
    );
  }
}
