import 'package:flutter/material.dart';
import '../services/privilegio_service.dart';
import '../models/privilegio_model.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentBottomIndex;

  const CustomBottomNavigation({super.key, required this.currentBottomIndex});

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  late Future<List<Privilegio>> futurePrivilegios;

  @override
  void initState() {
    super.initState();
    futurePrivilegios = PrivilegioService().getPrivilegios();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Privilegio>>(
      future: futurePrivilegios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error al cargar privilegios');
        }

        final privilegios = snapshot.data!;

        // Privilegios condicionales
        final puedeVerChat = privilegios.any(
          (p) => p.componente == 'chat' && p.puedeLeer,
        );
        final puedeVerFavoritos = privilegios.any(
          (p) => p.componente == 'anuncio' && p.puedeLeer,
        );

        final puedeVerMisInmuebles = privilegios.any(
          (p) => p.componente == 'inmueble' && p.puedeLeer,
        );
        final puedeRegistrarInmueble = privilegios.any(
          (p) => p.componente == 'inmueble' && p.puedeCrear,
        );
        final puedeVerAgentes = privilegios.any(
          (p) => p.componente == 'usuario' && p.puedeLeer,
        );
        // Ítems base (no restringidos)
        final items = <BottomNavigationBarItem>[];
        final rutas = <String>[];

        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_max),
            label: 'Inicio',
          ),
        );
        rutas.add('/inicio');

        if (puedeRegistrarInmueble) {
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Registrar Inmueble',
            ),
          );
          rutas.add('/registrar_inmueble');
        }
        if (puedeVerChat) {
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
          );
          rutas.add('/chat');
        }
        if (puedeVerAgentes) {
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Agentes Inmobiliarios',
            ),
          );
          rutas.add('/agentes_inmobiliarios');
        }
        if (puedeVerMisInmuebles) {
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.house_siding),
              label: 'Mis Inmuebles',
            ),
          );
          rutas.add('/mis_inmuebles');
        }
        if (puedeVerFavoritos) {
          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              label: 'Favoritos',
            ),
          );
          rutas.add('/favoritos');
        }

        // Ruta sin restricción
        items.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        );
        rutas.add('/mas');

        return BottomNavigationBar(
          currentIndex: widget.currentBottomIndex >= items.length
              ? 0
              : widget.currentBottomIndex,
          onTap: (index) {
            if (items.isNotEmpty) {
              context.go(rutas[index]);
            }
          },
          items: items.isEmpty
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_max),
                    label: 'Cargando...',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz),
                    label: '',
                  ),
                ]
              : items,
          backgroundColor: Colors.white, // Fondo sólido
          selectedItemColor: Colors.blue, // Color del item seleccionado
          unselectedItemColor: Colors.grey, // Color de items no seleccionados
          type: BottomNavigationBarType
              .fixed, // Para mostrar más de 3 items correctamente
          elevation: 8, // Sombra para que se note sobre el contenido
        );
      },
    );
  }
}
