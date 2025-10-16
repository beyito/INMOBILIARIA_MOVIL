import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Views simuladas por ahora
import 'package:movil_inmobiliaria/pages/home_page.dart';
import 'package:movil_inmobiliaria/views/login/login_page.dart';
import 'package:movil_inmobiliaria/views/usuario/registerCliente_view.dart';
import 'package:movil_inmobiliaria/views/usuario/registerAgente_view.dart';
import 'package:movil_inmobiliaria/views/usuario/recuperacionPassword_view.dart';
import 'package:movil_inmobiliaria/views/usuario/perfil_view.dart';
import 'package:movil_inmobiliaria/views/contrato/contrato_view.dart';

// Función para verificar si hay token
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return token != null && token.isNotEmpty;
}

final appRouter = GoRouter(
  initialLocation: '/home/0',
  routes: [
    GoRoute(
      path: '/home/:page',
      builder: (context, state) {
        final pageIndex =
            int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;
        return HomePage(pageIndex: pageIndex);
      },
      routes: [
        // Sub-rutas desde HomePage (ej: perfil)
        GoRoute(
          path: 'perfil',
          builder: (context, state) => const PerfilView(),
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterClienteView(),
    ),
    GoRoute(
      path: '/agente',
      builder: (context, state) => const RegisterAgenteView(),
    ),
    GoRoute(
      path: '/recuperar-password',
      builder: (context, state) => const RecuperacionPasswordView(),
    ),
    GoRoute(
      path: '/contrato',
      builder: (context, state) => const ContratoView(),
    ),
  ],
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final loggedIn = token != null && token.isNotEmpty;

    final loggingIn = state.location == '/login';
    final registering =
        state.location == '/register' || state.location == '/agente';
    final recovering = state.location == '/recuperar-password';

    if (!loggedIn && !(loggingIn || registering || recovering)) return '/login';
    if (loggedIn && (loggingIn || registering || recovering)) return '/home/0';

    return null;
  },
);
