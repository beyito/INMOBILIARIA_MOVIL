// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../../models/contacto/chat_model.dart';
// import '../../models/contacto/mensaje_model.dart';
// import '../../models/usuario/usuario_model.dart';
// import '../../services/contacto/chat_service.dart';

// class ChatProvider extends ChangeNotifier {
//   UsuarioModel? currentUser;
//   String? wsUrl;

//   ChatProvider({this.currentUser, this.wsUrl}) {
//     _init();
//   }

//   List<ChatModel> _chats = [];
//   List<ChatModel> get chats => _chats;

//   int? selectedChatId;
//   WebSocketChannel? _channel;

//   // Inicializar
//   Future<void> _init() async {
//     await _loadChats();
//     _connectWebSocket();
//     wsUrl = 'ws://192.168.100.12:8000/ws/user/${currentUser?.id}/';
//   }

//   // Cargar chats y mensajes históricos
//   Future<void> _loadChats() async {
//     try {
//       final chatsData = await ChatService().getChats();

//       // Para cada chat, obtener mensajes
//       final List<ChatModel> loadedChats = [];
//       for (var chat in chatsData) {
//         final mensajes = await ChatService().getMensajes(chat.id);
//         chat.mensajes = mensajes;
//         loadedChats.add(chat);
//       }

//       _chats = loadedChats;
//       notifyListeners();
//     } catch (e) {
//       print('Error cargando chats: $e');
//     }
//   }

//   // Conectar WebSocket
//   void _connectWebSocket() {
//     wsUrl = 'ws://192.168.100.12:8000/ws/user/2/';
//     _channel = WebSocketChannel.connect(Uri.parse(wsUrl ?? ""));

//     _channel!.stream.listen(
//       (event) {
//         final data = json.decode(event);
//         final msg = MensajeModel(
//           id: data['id'] ?? 0,
//           chatId: data['chat_id'] ?? 0,
//           usuario:
//               currentUser ??
//               UsuarioModel(), // Provide a default UsuarioModel if null
//           mensaje: data['mensaje'] ?? '',
//           fechaEnvio: data['fecha_envio'] ?? DateTime.now().toIso8601String(),
//           leido: false,
//         );

//         // Actualizar estado de chats
//         final chatIndex = _chats.indexWhere((c) => c.id == msg.chatId);
//         if (chatIndex >= 0) {
//           final chat = _chats[chatIndex];
//           final isCurrentChat = selectedChatId == chat.id;
//           chat.mensajes.add(msg);
//           notifyListeners();
//         }
//       },
//       onError: (err) {
//         print('WS error: $err');
//       },
//       onDone: () {
//         print('WS cerrado');
//       },
//     );
//   }

//   // Enviar mensaje
//   void enviarMensaje(int chatId, String mensaje) {
//     if (_channel != null) {
//       final payload = json.encode({'chat_id': chatId, 'mensaje': mensaje});
//       _channel!.sink.add(payload);
//     }
//   }

//   // Marcar mensajes leídos
//   void marcarMensajesLeidos(int chatId, List<int> mensajeIds) {
//     final chatIndex = _chats.indexWhere((c) => c.id == chatId);
//     if (chatIndex < 0) return;

//     final chat = _chats[chatIndex];
//     for (var msg in chat.mensajes) {
//       if (mensajeIds.contains(msg.id)) {
//         msg.leido = true;
//       }
//     }

//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _channel?.sink.close();
//     super.dispose();
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../models/contacto/chat_model.dart';
// import '../models/contacto/mensaje_model.dart';
// import '../models/usuario/usuario_model.dart';
// import '../services/contacto/chat_service.dart';

// class ChatProvider extends ChangeNotifier {
//   UsuarioModel? currentUser;
//   String? wsUrl;
//   bool connected = false;

//   List<ChatModel> chats = [];
//   int? selectedChatId;

//   WebSocketChannel? _channel;

//   ChatProvider();

//   void setUser(UsuarioModel user, String wsUrl) {
//     currentUser = user;
//     this.wsUrl = wsUrl;
//     _connectWebSocket();
//     notifyListeners();
//   }

//   void _connectWebSocket() {
//     if (wsUrl == null) return;

//     _channel = WebSocketChannel.connect(Uri.parse(wsUrl!));

//     _channel!.stream.listen(
//       (event) {
//         final Map<String, dynamic> msg = jsonDecode(event);

//         // Buscar el chat correspondiente
//         final chatIndex = chats.indexWhere((c) => c.id == msg['chat_id']);

//         if (chatIndex != -1) {
//           // ⚡ Agregar mensaje al chat y actualizar la UI
//           chats[chatIndex].mensajes.add(MensajeModel.fromJson(msg));
//           notifyListeners(); // Esto dispara la actualización de la vista
//         }
//       },
//       onError: (err) => print("WS error: $err"),
//       onDone: () => print("WS cerrado"),
//     );

//     connected = true;
//     notifyListeners();
//   }

//   Future<void> loadChats() async {
//     if (currentUser == null) return;
//     try {
//       chats = await ChatService().getChats(); // tu llamada a la API
//       notifyListeners();
//     } catch (e) {
//       print('Error cargando chats: $e');
//     }
//   }

//   void _addMensaje(Map<String, dynamic> msg) {
//     final chatIndex = chats.indexWhere((c) => c.id == msg['chat_id']);
//     if (chatIndex != -1) {
//       chats[chatIndex].mensajes.add(MensajeModel.fromJson(msg));
//     }
//   }

//   void setSelectedChat(int chatId) {
//     selectedChatId = chatId;
//     // notifyListeners();
//   }

//   void enviarMensaje(int chatId, String mensaje) {
//     if (_channel != null && _channel!.sink != null && currentUser != null) {
//       _channel!.sink.add(jsonEncode({'chat_id': chatId, 'mensaje': mensaje}));
//       notifyListeners();
//     } else {
//       print("WebSocket no conectado o usuario no definido");
//     }
//   }

//   @override
//   void dispose() {
//     _channel?.sink.close();
//     super.dispose();
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/contacto/chat_model.dart';
import '../models/contacto/mensaje_model.dart';
import '../models/usuario/usuario_model.dart';
import '../services/contacto/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  UsuarioModel? currentUser;
  String? wsUrl;
  bool connected = false;
  bool isLoading = false;
  late SharedPreferences prefs;
  List<ChatModel> chats = [];
  int? selectedChatId;

  WebSocketChannel? _channel;

  ChatProvider() {
    _initializePrefs();
  }

  // Inicializar SharedPreferences en el constructor
  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> initializeUser(UsuarioModel user, String wsUrl) async {
    print("✅ ChatProvider inicializado con usuario: ${user.id} - ${user.nombre}");
    currentUser = user;
    this.wsUrl = wsUrl;
    await _initializeChats();
  }

  void setUser(UsuarioModel user, String wsUrl) {
    currentUser = user;
    this.wsUrl = wsUrl;
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    await loadChats();
    _connectWebSocket();
  }

  void _connectWebSocket() {
  // 1. Si ya estamos conectados, no hacemos nada para evitar duplicados.
  if (_channel != null && connected) {
    print("♻️ WebSocket ya está conectado.");
    return;
  }

  // 2. Si faltan datos esenciales, cancelamos la conexión.
  if (wsUrl == null || currentUser == null) {
    print("❌ No se puede conectar a WS, falta URL o usuario.");
    return;
  }

  print("🔌 Intentando conectar a WebSocket...");
  try {
    // Tu código para construir la URL ya estaba bien, lo dejamos igual.
    String finalUrl;
    if (wsUrl!.contains('/ws/')) {
      finalUrl = wsUrl!.replaceFirst('http://', 'ws://');
    } else {
      String baseUrl = wsUrl!.replaceFirst('http://', 'ws://');
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      finalUrl = '$baseUrl/ws/user/${currentUser!.id}/?token=${prefs.getString('token')}';
    }

    print("🔗 Conectando a WebSocket: $finalUrl");
    _channel = WebSocketChannel.connect(Uri.parse(finalUrl));

    // 3. Nos ponemos a escuchar mensajes.
    _channel!.stream.listen(
      (event) {
        print("[WS] Mensaje recibido: $event");
        final Map<String, dynamic> data = jsonDecode(event);
        // La lógica para leer el "payload" que hicimos antes sigue aquí.
        if (data.containsKey('payload')) {
          final Map<String, dynamic> msg = data['payload'];
          _handleIncomingMessage(msg);
        }
      },
      onError: (err) {
        print("WS error: $err");
        connected = false;
        notifyListeners();
      },
      onDone: () {
        print("WS cerrado");
        connected = false;
        notifyListeners();
      },
    );

    // 4. Marcamos la conexión como exitosa.
    connected = true;
    notifyListeners();
    print("✅ WebSocket conectado exitosamente.");

  } catch (e) {
    print("❌ Error conectando WebSocket: $e");
    connected = false;
    notifyListeners();
  }
}

  void _handleIncomingMessage(Map<String, dynamic> msg) {
    try {
      print("[DEBUG] Mensaje recibido: $msg");

      // Manejar mensajes de chat
      if (msg['chat_id'] != null && msg['mensaje'] != null) {
        _handleChatMessage(msg);
      }
    } catch (e) {
      print("❌ Error procesando mensaje: $e");
    }
  }

  void _handleChatMessage(Map<String, dynamic> msg) {
    final chatId = msg['chat_id'];
    final usuarioId = msg['usuario_id'];

    if (usuarioId == currentUser?.id) {
      print("🔄 Mensaje propio, ignorando...");
      return;
    }

    final mensaje = MensajeModel(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: chatId,
      mensaje: msg['mensaje'],
      fechaEnvio: msg['fecha_envio'] ?? DateTime.now().toIso8601String(),
      leido: false,
      usuario: UsuarioModel(id: usuarioId, nombre: msg['usuario_nombre']),
    );

    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      chats[chatIndex].mensajes.add(mensaje);
      notifyListeners();
      print("✅ Mensaje agregado al chat $chatId");
    }
  }

  void enviarMensaje(int chatId, String texto) {
  // 1. Verificamos si la conexión está caída.
  if (_channel == null || !connected) {
    print("🔌 Conexión WS perdida. Intentando reconectar...");
    // Si no hay conexión, intentamos reconectar y detenemos el envío por ahora.
    // El usuario puede reintentar enviar el mensaje en un segundo.
    _connectWebSocket(); 
    return;
  }

  // 2. Si la conexión está activa, procedemos a enviar el mensaje.
  try {
    if (currentUser == null) return;

    final mensajeParaEnviar = {
      'chat_id': chatId,
      'mensaje': texto,
      'usuario_id': currentUser!.id,
      'usuario_nombre': currentUser!.nombre,
      'fecha_envio': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(mensajeParaEnviar));
    print("📤 Mensaje enviado COMPLEto: $mensajeParaEnviar");

    // Lógica para agregar el mensaje localmente al instante (UI Optimista)
    final mensajeLocal = MensajeModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: chatId,
      mensaje: texto,
      fechaEnvio: DateTime.now().toIso8601String(),
      leido: true,
      usuario: currentUser!,
    );

    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      chats[chatIndex].mensajes.add(mensajeLocal);
      notifyListeners();
      print("✅ Mensaje local agregado al chat $chatId");
    }
  } catch (e) {
    print("❌ Error enviando mensaje: $e");
  }
}

  Future<void> loadChats() async {
    if (currentUser == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      // Agregar un timeout para evitar que se quede pillado
      final chatsData = await ChatService().getChats().timeout(
        const Duration(seconds: 200),
        onTimeout: () {
          throw TimeoutException('La carga de chats tardó demasiado');
        },
      );

      chats = chatsData;
      isLoading = false;
      notifyListeners();
      print("✅ Chats cargados correctamente: ${chats.length} chats");
    } on TimeoutException catch (e) {
      print("❌ Timeout cargando chats: $e");
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("❌ Error cargando chats: $e");
      isLoading = false;
      notifyListeners();
      // Opcional: mantener chats existentes en caso de error
      // chats = [];
    }
  }

  // ✅ MÉTODOS UTILES

  bool isMyMessage(MensajeModel mensaje) {
    return mensaje.usuario.id == currentUser?.id;
  }

  void marcarTodosComoLeidos(int chatId) {
    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      bool cambios = false;

      for (var mensaje in chats[chatIndex].mensajes) {
        if (!mensaje.leido && mensaje.usuario.id != currentUser?.id) {
          mensaje.leido = true;
          cambios = true;
        }
      }

      if (cambios) {
        notifyListeners();
        print("✅ Todos los mensajes del chat $chatId marcados como leídos");
      }
    }
  }

  void marcarMensajeComoLeido(int chatId, int mensajeId) {
    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      final mensajeIndex = chats[chatIndex].mensajes.indexWhere(
        (m) => m.id == mensajeId,
      );
      if (mensajeIndex != -1 &&
          !chats[chatIndex].mensajes[mensajeIndex].leido) {
        chats[chatIndex].mensajes[mensajeIndex].leido = true;
        notifyListeners();
      }
    }
  }

  void setSelectedChat(int chatId) {
    selectedChatId = chatId;
    notifyListeners();
    print("✅ Chat seleccionado: $chatId");
  }

  int contarTotalMensajesNoLeidos() {
    int total = 0;
    for (var chat in chats) {
      total += chat.mensajes
          .where(
            (mensaje) =>
                !mensaje.leido && mensaje.usuario.id != currentUser?.id,
          )
          .length;
    }
    return total;
  }

  int contarMensajesNoLeidos(int chatId) {
    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      return chats[chatIndex].mensajes
          .where(
            (mensaje) =>
                !mensaje.leido && mensaje.usuario.id != currentUser?.id,
          )
          .length;
    }
    return 0;
  }

  ChatModel? getChatById(int chatId) {
    try {
      return chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  int getCantidadMensajesNoLeidos(int chatId) {
    return contarMensajesNoLeidos(chatId);
  }

  ChatModel? get selectedChat {
    if (selectedChatId == null) return null;
    return getChatById(selectedChatId!);
  }

  // Método para forzar la actualización
  void refreshChats() {
    loadChats();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
