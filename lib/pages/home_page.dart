import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:movil_inmobiliaria/config/config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Vistas
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
  // 1. Variables de estado para controlar la UI
  bool isLoading = true;
  String? errorMessage;

  int currentIndex = 0;
  List<BottomNavigationBarItem> items = [];
  List<Widget> viewRoutes = [];
  List<String> rutas = [];
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.pageIndex;
    _cargarDatosYConstruirUI();
    _setupFirebaseMessaging();
  }

  // 2. Función centralizada para cargar datos y preparar la UI
  Future<void> _cargarDatosYConstruirUI() async {
    try {
      final privilegios = await PrivilegioService().getPrivilegios();

      // Usamos listas temporales para construir la UI
      final newItems = <BottomNavigationBarItem>[];
      final newViewRoutes = <Widget>[];
      final newRutas = <String>[];

      void agregarRuta(IconData icon, String label, Widget view) {
        newItems.add(BottomNavigationBarItem(icon: Icon(icon), label: label));
        newViewRoutes.add(view);
        newRutas.add('/home/${newItems.length - 1}');
      }

      // --- Lógica para construir los menús ---

      agregarRuta(Icons.home_max, 'Inicio', InmuebleView());

      if (privilegios.any((p) => p.componente == 'inmueble' && p.puedeCrear)) {
        agregarRuta(Icons.add_business, 'Registrar', RegistrarInmuebleView());
      }
      if (privilegios.any((p) => p.componente == 'chat' && p.puedeLeer)) {
        agregarRuta(Icons.chat_bubble_outline, 'Chat', const ChatListView());
      }
      if (privilegios.any((p) => p.componente == 'usuario' && p.puedeLeer)) {
        agregarRuta(Icons.people, 'Agentes', AgenteView());
      }
      if (privilegios.any((p) => p.componente == 'inmueble' && p.puedeLeer)) {
        agregarRuta(Icons.house_siding, 'Mis Inmuebles', MisInmueblesView());
      }
      if (privilegios.any((p) => p.componente == 'anuncio' && p.puedeLeer)) {
        agregarRuta(Icons.favorite_outline, 'Favoritos',
            const Center(child: Text('FAVORITOS')));
      }
      if (privilegios.any((p) => p.componente == 'contrato' && p.puedeLeer)) {
        agregarRuta(Icons.receipt_long, 'Contratos', ContratoView());
      }
      if (privilegios.any((p) => p.componente == 'cita' && p.puedeLeer)) {
        agregarRuta(
            Icons.calendar_month_outlined, 'Agenda', const AgendaView());
      }

      newItems.add(const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz), label: 'Más'));
      newViewRoutes.add(ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Mi Desempeño'),
            onTap: () => context.push('/desempeno'),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Mis Comisiones'),
            onTap: () => context.push('/comisiones'),
          ),
          if (privilegios
              .any((p) => p.componente == 'tipoinmueble' && p.puedeCrear))
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Gestionar Tipos de Inmueble'),
              onTap: () => context.push('/tipos-inmueble'),
            ),
        ],
      ));
      newRutas.add('/home/${newItems.length - 1}');

      items = newItems;
      viewRoutes = newViewRoutes;
      rutas = newRutas;
    } catch (e) {
      print("🚨🚨🚨 ERROR CAPTURADO EN HOMEPAGE: $e");

      if (e.toString().contains('Token inválido') && mounted) {
        context.go('/login');
        return;
      }
      errorMessage = 'Error al cargar privilegios';
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        currentIndex =
            widget.pageIndex.clamp(0, items.isEmpty ? 0 : items.length - 1);
      });
    }
  }

  // Tu función de Firebase con manejo de errores
  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      String? tokenMensaje = await messaging.getToken();

      if (tokenMensaje != null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token") ?? "";
        await http.post(
          Uri.parse("${Config.baseUrl}/usuario/registrar-token/"),
          headers: {
            "Authorization": "Token $token",
            "Content-Type": "application/json"
          },
          body: '{"token": "$tokenMensaje", "plataforma": "android"}',
        );
        print("✅ Token FCM registrado en el backend.");
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {/* ... */});
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {/* ... */});
    } catch (e) {
      print("❌ Error en _setupFirebaseMessaging: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _cargarDatosYConstruirUI();
                },
                child: const Text('Reintentar'),
              )
            ]),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          context.pop();
          return;
        }
        if (currentIndex != 0) {
          setState(() => currentIndex = 0);
          context.go('/home/0');
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pulsa atrás otra vez para salir')),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
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
      ),
    );
  }
}
