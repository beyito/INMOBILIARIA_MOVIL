// import 'package:flutter/material.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../services/contacto/chat_service.dart';
// import 'chat_detalle_view.dart';
// import '../../services/auth_service.dart';

// class ChatListView extends StatefulWidget {
//   const ChatListView({super.key});

//   @override
//   State<ChatListView> createState() => _ChatListPageView();
// }

// class _ChatListPageView extends State<ChatListView> {
//   late Future<List<ChatModel>> _futureChats;

//   @override
//   void initState() {
//     super.initState();
//     _futureChats = ChatService().getChats();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Mis Chats')),
//       body: FutureBuilder<List<ChatModel>>(
//         future: _futureChats,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final chats = snapshot.data ?? [];

//           return ListView.builder(
//             itemCount: chats.length,
//             itemBuilder: (context, index) {
//               final chat = chats[index];
//               return ListTile(
//                 title: Text('Chat #${chat.id}'),
//                 subtitle: Text('Agente: ${chat.agente.nombre}'),
//                 onTap: () async {
//                   final currentUser = await AuthService().getUsuario();
//                   if (currentUser != null) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ChatDetalleView(
//                           chat: chat,
//                           currentUser: currentUser,
//                           wsUrl:
//                               'ws://192.168.100.12:8000/ws/user/${currentUser.id}/Token:',
//                         ),
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Usuario no encontrado')),
//                     );
//                   }
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../provider/chat_provider.dart';
// import 'chat_detalle_view.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/usuario/usuario_model.dart';
// import '../../services/auth_service.dart';

// class ChatListView extends StatelessWidget {
//   const ChatListView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final chatProvider = context.watch<ChatProvider>();
//     final chats = chatProvider.chats;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Mis Chats')),
//       body: ListView.builder(
//         itemCount: chats.length,
//         itemBuilder: (context, index) {
//           final chat = chats[index];
//           final lastMsg = chat.mensajes.isNotEmpty
//               ? chat.mensajes.last.mensaje
//               : '';

//           return ListTile(
//             title: Text('Chat #${chat.id}'),
//             subtitle: Text('Último mensaje: $lastMsg'),
//             onTap: () {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 chatProvider.setSelectedChat(chat.id);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChatDetalleView(chat: chat),
//                   ),
//                 );
//               });
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/chat_provider.dart';
import '../../models/contacto/chat_model.dart';
import 'chat_detalle_view.dart';
import '../../models/usuario/usuario_model.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final chats = chatProvider.chats;

        // Mostrar loading mientras carga
        if (chatProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mis Chats')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Chats'),
            actions: [
              // Mostrar contador total de mensajes no leídos
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Badge(
                  label: Text(
                    '${chatProvider.contarTotalMensajesNoLeidos()}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  isLabelVisible:
                      chatProvider.contarTotalMensajesNoLeidos() > 0,
                  child: const Icon(Icons.chat, color: Colors.white),
                ),
              ),
            ],
          ),
          body: chats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay chats disponibles',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Inicia una conversación',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => chatProvider.loadChats(),
                  child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];

                      // Obtener información del otro usuario
                      final otherUser = _getOtherUser(
                        chat,
                        chatProvider.currentUser?.id,
                      );
                      final lastMessage = chat.mensajes.isNotEmpty
                          ? chat.mensajes.last
                          : null;
                      final mensajesNoLeidos = chatProvider
                          .contarMensajesNoLeidos(chat.id);
                      final hasUnreadMessages = mensajesNoLeidos > 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: hasUnreadMessages
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            child: Text(
                              _getInitials(otherUser?.nombre ?? '?'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUser?.nombre ?? 'Usuario',
                                  style: TextStyle(
                                    fontWeight: hasUnreadMessages
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasUnreadMessages) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$mensajesNoLeidos',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMessage?.mensaje ?? 'Sin mensajes',
                                style: TextStyle(
                                  color: hasUnreadMessages
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: hasUnreadMessages
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (lastMessage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(lastMessage.fechaEnvio),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: hasUnreadMessages
                              ? const Icon(
                                  Icons.mark_chat_unread,
                                  color: Colors.red,
                                  size: 20,
                                )
                              : const Icon(
                                  Icons.mark_chat_read,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                          onTap: () {
                            chatProvider.setSelectedChat(chat.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetalleView(chat: chat),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  UsuarioModel? _getOtherUser(ChatModel chat, int? currentUserId) {
    if (currentUserId == null) return null;
    // Asumiendo que tu ChatModel tiene cliente y agente
    if (chat.cliente?.id == currentUserId) {
      return chat.agente;
    } else {
      return chat.cliente;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return 'Hoy ${_formatTime(date)}';
      } else if (messageDate == yesterday) {
        return 'Ayer ${_formatTime(date)}';
      } else {
        return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
