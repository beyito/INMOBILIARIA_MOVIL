import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:movil_inmobiliaria/views/inmueble/inmueble_view.dart';
import 'package:movil_inmobiliaria/views/usuario/agente_view.dart';
import '../shared/custom_appbar.dart';
import '../services/privilegio_service.dart';
import '../models/privilegio_model.dart';
import '../views/contacto/chat_list_view.dart';
import '../views/inmueble/registrar_inmueble_view.dart';
import '../views/inmueble/mis_inmuebles_view.dart';
import '../views/contrato/contrato_view.dart';
import 'package:movil_inmobiliaria/views/cita/agenda_view.dart';

// Instancia global del plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  final int pageIndex;
  const HomePage({super.key, required this.pageIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Privilegio>> futurePrivilegios;
  int currentIndex = 0;
  List<BottomNavigationBarItem> items = [];
  List<Widget> viewRoutes = [];
  List<String> rutas = [];

  @override
  void initState() {
    super.initState();
    futurePrivilegios = PrivilegioService().getPrivilegios();
    currentIndex = widget.pageIndex;
    _setupFirebaseMessaging();
  }

  // -------------------------------
  // 🔹 Configurar Firebase Messaging
  // -------------------------------
  // Pedir permisos en iOS
  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos (iOS)
    await messaging.requestPermission();

    // Inicializar flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Obtener token FCM
    String? tokenMensaje = await messaging.getToken();
    print("Token FCM: $tokenMensaje");

    // Guardar token en backend
    if (tokenMensaje != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      print("Token: $token");
      await http.post(
        Uri.parse("${Config.baseUrl}/usuario/registrar-token/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: '{"token": "$tokenMensaje", "plataforma": "android"}',
      );
    }

    // 🔹 Foreground: mostrar notificación en barra
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        "📩 Notificación recibida en foreground: ${message.notification?.title}",
      );

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_general', // ID del canal
              'Canal General', // nombre
              channelDescription: 'Notificaciones generales',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Cuando el usuario abre la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("👉 Notificación abierta por el usuario: ${message.data}");
    });

    // App abierta desde notificación cerrada
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print("🔔 App abierta desde notificación: ${message.data}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Privilegio>>(
      future: futurePrivilegios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Error al cargar privilegios')),
          );
        }

        final privilegios = snapshot.data!;

        // Solo llenar listas si están vacías
        if (items.isEmpty) {
          // 🔹 Inicio (sin restricción)
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_max),
              label: 'Inicio',
            ),
          );
          viewRoutes.add(InmuebleView());
          rutas.add('/home/0');
          if (privilegios.any(
            (p) => p.componente == 'inmueble' && p.puedeCrear,
          )) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_max),
                label: 'Registrar Inmueble',
              ),
            );
            viewRoutes.add(RegistrarInmuebleView());
            rutas.add('/home/1');
          }

          // 🔹 Chat (si tiene privilegio)
          if (privilegios.any((p) => p.componente == 'chat' && p.puedeLeer)) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
            );
            viewRoutes.add(ChatListView());
            rutas.add('/home/2');
          }
          // 🔹 Agentes (si tiene privilegio)
          if (privilegios.any(
            (p) => p.componente == 'usuario' && p.puedeLeer,
          )) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Agentes',
              ),
            );
            viewRoutes.add(AgenteView());
            rutas.add('/home/3');
          }
          // Mis Inmuebles (si tiene privilegio)
          if (privilegios.any(
            (p) => p.componente == 'inmueble' && p.puedeLeer,
          )) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.house_siding),
                label: 'Mis Inmuebles',
              ),
            );
            viewRoutes.add(MisInmueblesView());
            rutas.add('/home/4');
          }
          // 🔹 Favoritos (si tiene privilegio)
          if (privilegios.any(
            (p) => p.componente == 'anuncio' && p.puedeLeer,
          )) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                label: 'Favoritos',
              ),
            );
            viewRoutes.add(const Center(child: Text('FAVORITOS')));
            rutas.add('/home/5');
          }
          // 🔹 Contrato (si tiene privilegio)
          if (privilegios.any(
            (p) => p.componente == 'contrato' && p.puedeLeer,
          )) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Contratos',
              ),
            );
            viewRoutes.add(ContratoView());
            rutas.add('/home/7');
          }
          // 🔹 Agenda (si tiene privilegio 'cita' leer)
          if (privilegios.any((p) => p.componente == 'cita' && p.puedeLeer)) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Agenda',
              ),
            );
            viewRoutes.add(const AgendaView());
            rutas.add('/home/8');
          }

          // 🔹 Más (sin restricción)
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Más',
            ),
          );
          viewRoutes.add(const Center(child: Text('MÁS')));
          rutas.add('/home/6');

          // Ajustar índice actual si pageIndex fuera mayor al máximo
          currentIndex = widget.pageIndex.clamp(0, items.length - 1);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const CustomAppbar(),
          body: IndexedStack(index: currentIndex, children: viewRoutes),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() => currentIndex = index);
              context.go(rutas[index]);
            },
            items: items,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
        );
      },
    );
  }
}
