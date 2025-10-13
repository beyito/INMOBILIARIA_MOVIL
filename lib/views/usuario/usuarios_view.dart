// class UsuariosView extends StatefulWidget {
//   static const name = 'usuarios-screen';

//   const UsuariosView({super.key});

//   @override
//   _UsuariosViewState createState() => _UsuariosViewState();
// }

// class _UsuariosViewState extends State<UsuariosView> {
//   final UsuarioService usuarioService = UsuarioService();
//   List<UsuarioModel> usuarios = [];
//   bool loading = true;
//   String? error;

//   @override
//   void initState() {
//     super.initState();
//     cargarUsuarios();
//   }

//   void cargarUsuarios() async {
//     try {
//       final data = await usuarioService.mostrarUsuarios();
//       setState(() {
//         usuarios = data;
//         loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//         loading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // return Scaffold(
//     //   appBar: AppBar(
//     //     title: Text('Usuarios'),
//     //   ),
//     //   body: Center(
//     //     child: Text('Hola desde UsuariosView'),
//     //   ),
//     // );
//     if (loading) return CircularProgressIndicator();
//     if (error != null) return Text(error!);

//     return ListView.builder(
//       itemCount: usuarios.length,
//       itemBuilder: (context, index) {
//         final usuario = usuarios[index];
//         return Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: ListTile(
//             title: Text(usuario.nombre ?? ""),
//             subtitle: Text(usuario.email ?? ""),
//           ),
//         );
//       },
//     );
//   }
// }
