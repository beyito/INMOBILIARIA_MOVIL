// lib/models/contacto/chat_model.dart
import '../usuario/usuario_model.dart';
import 'mensaje_model.dart';

class ChatModel {
  final int id;
  final DateTime fechaCreacion;
  final UsuarioModel cliente;
  final UsuarioModel agente;
  List<MensajeModel> mensajes;

  ChatModel({
    required this.id,
    required this.fechaCreacion,
    required this.cliente,
    required this.agente,
    required this.mensajes,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      cliente: UsuarioModel.fromJson(json['cliente']),
      agente: UsuarioModel.fromJson(json['agente']),
      mensajes: json['mensajes'] != null
          ? List<MensajeModel>.from(
              json['mensajes'].map((x) => MensajeModel.fromJson(x)),
            )
          : [],
    );
  }
}
