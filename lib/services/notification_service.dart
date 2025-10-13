// services/notification_service.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static StreamController<Map<String, dynamic>> _messageStream =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStream.stream;

  // Inicializar notificaciones
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Configurar notificaciones locales
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Solicitar permisos
    await _requestPermissions();

    // Configurar manejo de mensajes
    await _setupInteractedMessage();

    // Obtener token
    await _getToken();
  }

  // Solicitar permisos
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permisos de notificación: ${settings.authorizationStatus}');
  }

  // Configurar manejo de mensajes
  static Future<void> _setupInteractedMessage() async {
    // Mensaje cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Mensaje cuando la app está en segundo plano o cerrada
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Mensaje cuando la app está totalmente cerrada
    FirebaseMessaging.instance.getInitialMessage().then(
      _handleBackgroundMessage,
    );
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'inmobiliaria_channel',
            'Notificaciones Inmobiliaria',
            channelDescription: 'Canal para notificaciones de la inmobiliaria',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        notification.title,
        notification.body,
        details,
        payload: data.toString(),
      );

      // Emitir al stream
      _messageStream.add({
        'title': notification.title,
        'body': notification.body,
        'data': data,
      });
    }
  }

  // Manejar mensaje en segundo plano
  static void _handleBackgroundMessage(RemoteMessage? message) {
    if (message != null) {
      _messageStream.add({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    }
  }

  // Obtener token del dispositivo
  static Future<String?> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Guardar token en tu backend
      if (token != null) {
        await _saveTokenToBackend(token);
      }

      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);

      return token;
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  // Guardar token en tu backend
  static Future<void> _saveTokenToBackend(String token) async {
    try {
      // Aquí debes implementar la llamada a tu API para guardar el token
      print('Guardando token en backend: $token');

      // Ejemplo:
      // await http.post(
      //   Uri.parse('${Config.baseUrl}/usuarios/token'),
      //   headers: {'Authorization': 'Token ...'},
      //   body: jsonEncode({'token': token}),
      // );
    } catch (e) {
      print('Error guardando token: $e');
    }
  }

  // Suscribirse a temas
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Suscrito al tema: $topic');
  }

  // Cancelar suscripción a temas
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Cancelada suscripción al tema: $topic');
  }

  // Eliminar token (al cerrar sesión)
  static Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    print('Token eliminado');
  }
}
