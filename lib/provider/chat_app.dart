import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario/usuario_model.dart';
import 'chat_provider.dart';
import '../views/contacto/chat_list_view.dart';

class ChatApp extends StatelessWidget {
  final UsuarioModel currentUser;
  final String wsUrl;

  const ChatApp({super.key, required this.currentUser, required this.wsUrl});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider()..initializeUser(currentUser, wsUrl),
      child: _ChatAppContent(),
    );
  }
}

class _ChatAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    // Mostrar loading mientras se inicializa
    if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando chat...'),
            ],
          ),
        ),
      );
    }

    return ChatListView();
  }
}
