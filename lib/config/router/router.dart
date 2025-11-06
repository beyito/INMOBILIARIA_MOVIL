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
import 'package:movil_inmobiliaria/views/desempeno/desempeno_view.dart';
import 'package:movil_inmobiliaria/views/inmueble/tipos_inmueble_view.dart';
import 'package:movil_inmobiliaria/views/comisiones/dashboard_comisiones_agente.dart';

import 'package:movil_inmobiliaria/views/reportes/reportes_page.dart';
import 'package:movil_inmobiliaria/views/contrato_anticretico/contrato_anticretico_list_page.dart';
import 'package:movil_inmobiliaria/views/contrato_anticretico/contrato_anticretico_detail_page.dart';
import 'package:movil_inmobiliaria/views/contrato_anticretico/crear_contrato_page.dart';
import 'package:movil_inmobiliaria/views/contrato_alquiler/contrato_alquiler_list_page.dart';
import 'package:movil_inmobiliaria/views/contrato_alquiler/contrato_alquiler_form_page.dart';
import 'package:movil_inmobiliaria/views/contrato_alquiler/contrato_alquiler_detail_page.dart';
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
    GoRoute(
      path: '/desempeno',
      builder: (context, state) => const DesempenoView(),
    ),
    GoRoute(
      path: '/reportes',
      builder: (context, state) => const ReportesPage(),
    ),
    GoRoute(
      path: '/tipos-inmueble',
      builder: (context, state) => const TiposInmuebleView(),
    ),
    GoRoute(
      path: '/comision',
      builder: (context, state) => const DashboardComisionesAgente(),
    ),
    GoRoute(
      path: '/contratos-anticretico', // La nueva lista
      builder: (context, state) => const ContratoAnticreticoListPage(),
    ),
    GoRoute(
      path: '/contrato-anticretico-detalle/:id', // El detalle
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return ContratoAnticreticoDetailPage(contratoId: id);
      },
    ),
    GoRoute(
      path: '/crear-contrato-anticretico', // El formulario
      builder: (context, state) => const CrearContratoPage(),
    ),
    GoRoute(
  path: '/contratos-alquiler',
  builder: (context, state) => const ContratoAlquilerListPage(),
),
GoRoute(
  path: '/contratos-alquiler/nuevo',
  builder: (context, state) => const ContratoAlquilerFormPage(),
),
GoRoute(
  path: '/contratos-alquiler/:id',
  builder: (context, state) {
    final idStr = state.pathParameters['id'] ?? '0';
    final id = int.tryParse(idStr) ?? 0;
    return ContratoAlquilerDetailPage(contratoId: id);
  },
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
