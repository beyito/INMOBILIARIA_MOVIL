import '../usuario/usuario_model.dart';

class MensajeModel {
  final int id;
  final int chatId;
  final UsuarioModel usuario;
  final String mensaje;
  final String fechaEnvio;
  bool leido;
  MensajeModel({
    required this.id,
    required this.chatId,
    required this.usuario,
    required this.mensaje,
    required this.fechaEnvio,
    required this.leido,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'],
      chatId: json['chat'],
      usuario: UsuarioModel.fromJson(json['usuario']),
      mensaje: json['mensaje'],
      fechaEnvio: json['fecha_envio'],
      leido: json['leido'],
    );
  }
}
