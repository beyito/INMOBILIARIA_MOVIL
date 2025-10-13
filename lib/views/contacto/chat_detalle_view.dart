// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import '../../models/usuario/usuario_model.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;
//   final UsuarioModel currentUser;
//   final String wsUrl; // Ej: 'ws://192.168.100.12:8000/ws/user/3/'

//   const ChatDetalleView({
//     super.key,
//     required this.chat,
//     required this.currentUser,
//     required this.wsUrl,
//   });

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   late WebSocketChannel channel;
//   final TextEditingController _controller = TextEditingController();
//   final List<MensajeModel> mensajes = [];

//   @override
//   void initState() {
//     super.initState();
//     channel = WebSocketChannel.connect(Uri.parse(widget.wsUrl));

//     // Escuchar mensajes entrantes
//     channel.stream.listen(
//       (data) {
//         final payload = json.decode(data);
//         if (!mounted) return;

//         final msg = MensajeModel(
//           id: payload['id'] ?? 0,
//           chatId: payload['chat_id'],
//           usuario: widget.currentUser.id == payload['usuario_id']
//  ? widget.currentUser
//               : widget.chat.agente, // o cliente según corresponda
//           mensaje: payload['mensaje'],
//           fechaEnvio: payload['fecha_envio'],
//           leido: false,
//         );

//         setState(() {
//           mensajes.add(msg);
//         });
//       },
//       onError: (err) {
//         print("WebSocket error: $err");
//       },
//       onDone: () {
//         print("WebSocket cerrado");
//       },
//     );
//   }

//   @override
//   void dispose() {
//     channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }

//   void enviarMensaje() {
//     final texto = _controller.text.trim();
//     if (texto.isEmpty) return;

//     final msg = json.encode({"chat_id": widget.chat.id, "mensaje": texto});

//     channel.sink.add(msg);
//     _controller.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Chat #${widget.chat.id}')),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: mensajes.length,
//               itemBuilder: (context, index) {
//                 final msg = mensajes[index];
//                 final esYo = msg.usuario.id == widget.currentUser.id;
//                 return ListTile(
//                   title: Align(
//                     alignment: esYo
//                         ? Alignment.centerRight
//                         : Alignment.centerLeft,
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: esYo ? Colors.blue : Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         msg.mensaje,
//                         style: TextStyle(
//                           color: esYo ? Colors.white : Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                   subtitle: Align(
//                     alignment: esYo
//                         ? Alignment.centerRight
//                         : Alignment.centerLeft,
//                     child: Text(
//                       msg.fechaEnvio,
//                       style: const TextStyle(fontSize: 10),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Escribe un mensaje...',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: enviarMensaje,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import '../../models/usuario/usuario_model.dart';
// import '../../services/contacto/chat_service.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;
//   final UsuarioModel currentUser;
//   final String wsUrl; // URL del WebSocket

//   const ChatDetalleView({
//     super.key,
//     required this.chat,
//     required this.currentUser,
//     required this.wsUrl,
//   });

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   final TextEditingController _controller = TextEditingController();
//   late WebSocketChannel _channel;
//   bool _connected = false;

//   @override
//   void initState() {
//     super.initState();
//     _initChat();
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _initChat() async {
//     // Cargar mensajes iniciales desde API
//     final mensajes = await ChatService().getMensajes(widget.chat.id);
//     setState(() => widget.chat.mensajes = mensajes);

//     // Conectar WebSocket
//     _channel = WebSocketChannel.connect(Uri.parse(widget.wsUrl));

//     _channel.stream.listen(
//       (data) {
//         final decoded = jsonDecode(data);
//         final msg = MensajeModel(
//           id: decoded['id'] ?? DateTime.now().millisecondsSinceEpoch,
//           chatId: decoded['chat_id'] ?? widget.chat.id,
//           usuario: widget.currentUser,
//           mensaje: decoded['mensaje'],
//           fechaEnvio:
//               decoded['fecha_envio'] ?? DateTime.now().toIso8601String(),
//           leido: true,
//         );

//         setState(() {
//           widget.chat.mensajes.add(msg);
//         });
//       },
//       onDone: () {
//         setState(() => _connected = false);
//         print('WebSocket cerrado');
//       },
//       onError: (err) {
//         setState(() => _connected = false);
//         print('WebSocket error: $err');
//       },
//     );

//     setState(() => _connected = true);
//   }

//   void _sendMensaje() {
//     final texto = _controller.text.trim();
//     if (texto.isEmpty) return;

//     final payload = jsonEncode({'chat_id': widget.chat.id, 'mensaje': texto});

//     _channel.sink.add(payload);
//     _controller.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Chat #${widget.chat.id}'),
//             Text(
//               _connected ? 'Conectado' : 'Desconectado',
//               style: TextStyle(fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: widget.chat.mensajes.length,
//               itemBuilder: (context, index) {
//                 final msg = widget.chat.mensajes[index];
//                 final isMe = msg.usuario.id == widget.currentUser.id;
//                 return Align(
//                   alignment: isMe
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     margin: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isMe ? Colors.blue : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: isMe
//                           ? CrossAxisAlignment.end
//                           : CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           msg.usuario.nombre ?? '',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: isMe ? Colors.white : Colors.black,
//                           ),
//                         ),
//                         Text(
//                           msg.mensaje,
//                           style: TextStyle(
//                             color: isMe ? Colors.white : Colors.black,
//                           ),
//                         ),
//                         Text(
//                           msg.fechaEnvio,
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: isMe ? Colors.white70 : Colors.black54,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Escribe un mensaje...',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMensaje,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import '../../models/usuario/usuario_model.dart';
// import '../../provider/chat_provider.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;

//   const ChatDetalleView({super.key, required this.chat});

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   final TextEditingController _controller = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     final chatProvider = context.read<ChatProvider>();
//     chatProvider.setSelectedChat(widget.chat.id);
//   }

//   void _sendMessage(ChatProvider chatProvider) {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//     chatProvider.enviarMensaje(widget.chat.id, text);
//     _controller.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, chatProvider, _) {
//         final chat = chatProvider.chats.firstWhere(
//           (c) => c.id == widget.chat.id,
//           orElse: () => widget.chat,
//         );

//         return Scaffold(
//           appBar: AppBar(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Chat #${chat.id}'),
//                 Text(
//                   chatProvider.connected ? 'Conectado' : 'Desconectado',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           body: Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: chat.mensajes.length,
//                   itemBuilder: (context, index) {
//                     final msg = chat.mensajes[index];
//                     final isMe = msg.usuario.id == chatProvider.currentUser?.id;
//                     return ListTile(
//                       title: Align(
//                         alignment: isMe
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: isMe ? Colors.blue[200] : Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(msg.mensaje),
//                         ),
//                       ),
//                       subtitle: Align(
//                         alignment: isMe
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Text(msg.fechaEnvio),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         decoration: const InputDecoration(
//                           hintText: 'Escribe un mensaje...',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.send),
//                       onPressed: () {
//                         final texto = _controller.text.trim();
//                         if (texto.isEmpty) return;

//                         final chatProvider = context.read<ChatProvider>();
//                         chatProvider.enviarMensaje(widget.chat.id, texto);

//                         _controller.clear();
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import '../../provider/chat_provider.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;

//   const ChatDetalleView({super.key, required this.chat});

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final chatProvider = context.read<ChatProvider>();
//       chatProvider.setSelectedChat(widget.chat.id);

//       // ⚡ Cargar chats si aún no se han cargado
//       if (chatProvider.chats.isEmpty) {
//         await chatProvider.loadChats();
//       }
//     });
//   }

//   void _sendMessage(ChatProvider chatProvider) {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     chatProvider.enviarMensaje(widget.chat.id, text);
//     _controller.clear();

//     // Scroll al último mensaje
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, chatProvider, _) {
//         // Obtener el chat actualizado desde el provider
//         final chat = chatProvider.chats.firstWhere(
//           (c) => c.id == widget.chat.id,
//           orElse: () => ChatModel(
//             id: widget.chat.id,
//             cliente: widget.chat.cliente,
//             agente: widget.chat.agente,
//             mensajes: [],
//             fechaCreacion: DateTime.now(),
//           ), // fallback vacío
//         );
//         // Scroll automático al construir la lista
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_scrollController.hasClients) {
//             _scrollController.jumpTo(
//               _scrollController.position.maxScrollExtent,
//             );
//           }
//         });

//         return Scaffold(
//           appBar: AppBar(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Chat #${chat.id}'),
//                 Text(
//                   chatProvider.connected ? 'Conectado' : 'Desconectado',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           body: Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   itemCount: chat.mensajes.length,
//                   itemBuilder: (context, index) {
//                     final msg = chat.mensajes[index];
//                     final isMe = msg.usuario.id == chatProvider.currentUser?.id;

//                     return Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       child: Align(
//                         alignment: isMe
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Column(
//                           crossAxisAlignment: isMe
//                               ? CrossAxisAlignment.end
//                               : CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: isMe
//                                     ? Colors.blue[200]
//                                     : Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(msg.mensaje),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               msg.fechaEnvio,
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         decoration: const InputDecoration(
//                           hintText: 'Escribe un mensaje...',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.send),
//                       onPressed: () => _sendMessage(chatProvider),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../provider/chat_provider.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;

//   const ChatDetalleView({super.key, required this.chat});

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final chatProvider = context.read<ChatProvider>();
//       chatProvider.setSelectedChat(widget.chat.id);
//       if (chatProvider.chats.isEmpty) {
//         chatProvider.loadChats();
//       }
//     });
//   }

//   void _sendMessage(ChatProvider chatProvider) {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     chatProvider.enviarMensaje(widget.chat.id, text);
//     _controller.clear();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, chatProvider, _) {
//         final chat = chatProvider.chats.firstWhere(
//           (c) => c.id == widget.chat.id,
//           orElse: () => widget.chat,
//         );

//         // Scroll automático solo si hay nuevos mensajes
//         _scrollToBottom();

//         return Scaffold(
//           appBar: AppBar(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Chat #${chat.id}'),
//                 Text(
//                   chatProvider.connected ? 'Conectado' : 'Desconectado',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           body: Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   itemCount: chat.mensajes.length,
//                   itemBuilder: (context, index) {
//                     final msg = chat.mensajes[index];
//                     final isMe = msg.usuario.id == chatProvider.currentUser?.id;

//                     return Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       child: Align(
//                         alignment: isMe
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Column(
//                           crossAxisAlignment: isMe
//                               ? CrossAxisAlignment.end
//                               : CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: isMe
//                                     ? Colors.blue[200]
//                                     : Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(msg.mensaje),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               msg.fechaEnvio,
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         decoration: const InputDecoration(
//                           hintText: 'Escribe un mensaje...',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.send),
//                       onPressed: () {
//                         final chatProvider = context.read<ChatProvider>();
//                         _sendMessage(chatProvider);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../provider/chat_provider.dart';

// class ChatDetalleView extends StatefulWidget {
//   final ChatModel chat;

//   const ChatDetalleView({super.key, required this.chat});

//   @override
//   State<ChatDetalleView> createState() => _ChatDetalleViewState();
// }

// class _ChatDetalleViewState extends State<ChatDetalleView> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeChat();
//   }

//   void _initializeChat() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final chatProvider = context.read<ChatProvider>();

//       // Verificar si el usuario está configurado
//       if (chatProvider.currentUser == null) {
//         print("ERROR: Usuario no configurado en ChatProvider");
//         return;
//       }

//       chatProvider.setSelectedChat(widget.chat.id);

//       // Forzar recarga de chats si está vacío
//       if (chatProvider.chats.isEmpty) {
//         chatProvider.loadChats().then((_) {
//           if (mounted) {
//             setState(() {
//               _isInitialized = true;
//             });
//             _scrollToBottom();
//           }
//         });
//       } else {
//         setState(() {
//           _isInitialized = true;
//         });
//         _scrollToBottom();
//       }
//     });
//   }

//   void _sendMessage(ChatProvider chatProvider) {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     chatProvider.enviarMensaje(widget.chat.id, text);
//     _controller.clear();
//     _scrollToBottom();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   ChatModel _getCurrentChat(ChatProvider chatProvider) {
//     try {
//       return chatProvider.chats.firstWhere((c) => c.id == widget.chat.id);
//     } catch (e) {
//       // Fallback al chat original si no se encuentra
//       return widget.chat;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, chatProvider, _) {
//         if (chatProvider.isLoading && !_isInitialized) {
//           return Scaffold(
//             appBar: AppBar(title: Text('Chat #${widget.chat.id}')),
//             body: const Center(child: CircularProgressIndicator()),
//           );
//         }

//         final chat = _getCurrentChat(chatProvider);

//         return Scaffold(
//           appBar: AppBar(
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Chat #${chat.id}'),
//                 Row(
//                   children: [
//                     Icon(
//                       chatProvider.connected
//                           ? Icons.circle
//                           : Icons.circle_outlined,
//                       size: 12,
//                       color: chatProvider.connected ? Colors.green : Colors.red,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       chatProvider.connected ? 'Conectado' : 'Desconectado',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: chatProvider.connected
//                             ? Colors.green
//                             : Colors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           body: Column(
//             children: [
//               Expanded(
//                 child: chat.mensajes.isEmpty
//                     ? const Center(child: Text('No hay mensajes aún'))
//                     : ListView.builder(
//                         controller: _scrollController,
//                         itemCount: chat.mensajes.length,
//                         itemBuilder: (context, index) {
//                           final msg = chat.mensajes[index];
//                           final isMe =
//                               msg.usuario.id == chatProvider.currentUser?.id;

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             child: Align(
//                               alignment: isMe
//                                   ? Alignment.centerRight
//                                   : Alignment.centerLeft,
//                               child: Column(
//                                 crossAxisAlignment: isMe
//                                     ? CrossAxisAlignment.end
//                                     : CrossAxisAlignment.start,
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: isMe
//                                           ? Colors.blue[200]
//                                           : Colors.grey[300],
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Text(msg.mensaje),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     msg.fechaEnvio,
//                                     style: const TextStyle(fontSize: 10),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         decoration: const InputDecoration(
//                           hintText: 'Escribe un mensaje...',
//                           border: OutlineInputBorder(),
//                         ),
//                         onSubmitted: (value) => _sendMessage(chatProvider),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.send),
//                       onPressed: () => _sendMessage(chatProvider),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contacto/chat_model.dart';
import '../../models/contacto/mensaje_model.dart';
import '../../provider/chat_provider.dart';
import '../../models/usuario/usuario_model.dart';

class ChatDetalleView extends StatefulWidget {
  final ChatModel chat;

  const ChatDetalleView({super.key, required this.chat});

  @override
  State<ChatDetalleView> createState() => _ChatDetalleViewState();
}

class _ChatDetalleViewState extends State<ChatDetalleView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeChat();
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();

      if (chatProvider.currentUser == null) {
        print("❌ ERROR: Usuario no configurado en ChatProvider");
        return;
      }

      chatProvider.setSelectedChat(widget.chat.id);

      // Forzar recarga si no hay chats
      if (chatProvider.chats.isEmpty) {
        print("🔄 No hay chats cargados, forzando recarga...");
        chatProvider.loadChats().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _scrollToBottom();
          }
        });
      } else {
        setState(() {
          _isInitialized = true;
        });
        _scrollToBottom();
      }

      // Marcar todos los mensajes como leídos al abrir el chat
      chatProvider.marcarTodosComoLeidos(widget.chat.id);
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.marcarTodosComoLeidos(widget.chat.id);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.enviarMensaje(widget.chat.id, text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatModel _getCurrentChat(ChatProvider chatProvider) {
    try {
      // Buscar el chat actualizado en la lista del provider
      final currentChat = chatProvider.chats.firstWhere(
        (c) => c.id == widget.chat.id,
      );
      print(
        "✅ Chat encontrado en provider: ${currentChat.id} con ${currentChat.mensajes.length} mensajes",
      );
      return currentChat;
    } catch (e) {
      // Fallback al chat original si no se encuentra
      print(
        "⚠️ Chat ${widget.chat.id} no encontrado en provider, usando chat original con ${widget.chat.mensajes.length} mensajes",
      );
      return widget.chat;
    }
  }

  UsuarioModel? _getOtherUser(ChatModel chat, ChatProvider chatProvider) {
    final currentUserId = chatProvider.currentUser?.id;
    if (currentUserId == null) return null;

    // Asumiendo que tu ChatModel tiene cliente y agente
    if (chat.cliente?.id == currentUserId) {
      return chat.agente;
    } else {
      return chat.cliente;
    }
  }

  Widget _buildMessageItem(MensajeModel msg, ChatProvider chatProvider) {
    final isMe = chatProvider.isMyMessage(msg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.usuario.nombre ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  Text(
                    msg.mensaje,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.fechaEnvio),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  if (isMe && msg.leido)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.done_all, size: 12, color: Colors.blue),
                    ),
                  if (isMe && !msg.leido)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.done, size: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        // Mostrar loading si no está inicializado o si está cargando
        if (!_isInitialized || chatProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Chat #${widget.chat.id}')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando chat...'),
                ],
              ),
            ),
          );
        }

        if (chatProvider.currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Chat #${widget.chat.id}')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: Usuario no configurado'),
                  Text(
                    'Vuelve a la lista de chats',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final chat = _getCurrentChat(chatProvider);
        final otherUser = _getOtherUser(chat, chatProvider);
        final hasMessages = chat.mensajes.isNotEmpty;

        print(
          "🎯 Construyendo UI para chat ${chat.id} con ${chat.mensajes.length} mensajes",
        );

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherUser?.nombre ?? 'Chat #${chat.id}'),
                Row(
                  children: [
                    Icon(
                      chatProvider.connected
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 12,
                      color: chatProvider.connected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatProvider.connected ? 'Conectado' : 'Desconectado',
                      style: TextStyle(
                        fontSize: 12,
                        color: chatProvider.connected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: !hasMessages
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
                              'No hay mensajes aún',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '¡Sé el primero en enviar un mensaje!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: chat.mensajes.length,
                        itemBuilder: (context, index) {
                          final msg = chat.mensajes[index];
                          print("📝 Mostrando mensaje $index: ${msg.mensaje}");
                          return _buildMessageItem(msg, chatProvider);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
