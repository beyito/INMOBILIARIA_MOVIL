// lib/views/login/login_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha

import '../../models/usuario/usuario_model.dart';
import '../../provider/chat_provider.dart';
import '../../services/auth_service.dart';
import '../../config/config.dart';


class LoginPage extends StatefulWidget {
  static const name = 'login-screen';
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLogin = true;
  String _userType = 'cliente';
  bool _showPassword = false;
  bool _isLoading = false;
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _ciController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _numeroLicenciaController = TextEditingController();
  final _experienciaController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _ciController.dispose();
    _telefonoController.dispose();
    _ubicacionController.dispose();
    _fechaNacimientoController.dispose();
    _numeroLicenciaController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
  // 1. Validar el formulario
  if (!_formKey.currentState!.validate()) return;
  setState(() { _isLoading = true; });

  Map<String, dynamic> result;
  if (_isLogin) {
    // 2. Realizar el login
    result = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
  } else {
    // Lógica de registro (sin cambios)
    Map<String, dynamic> payload = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
      "nombre": _nombreController.text.trim(),
      "correo": _correoController.text.trim(),
      "ci": _ciController.text.trim(),
      "telefono": _telefonoController.text.trim(),
      "grupo_id": _userType == 'cliente' ? 1 : 2,
    };
    if (_userType == 'cliente') {
      payload.addAll({
        "ubicacion": _ubicacionController.text.trim(),
        "fecha_nacimiento": _fechaNacimientoController.text.trim(),
      });
    } else { 
      payload.addAll({
        "numero_licencia": _numeroLicenciaController.text.trim(),
        "experiencia": int.tryParse(_experienciaController.text.trim()) ?? 0,
      });
    }
    result = await _authService.register(payload);
  }

  // Detener la carga y verificar que el widget sigue montado
  if (!mounted) return;
  setState(() { _isLoading = false; });

  // 3. Procesar el resultado
  if (result['success'] == true) {
    // Obtenemos todo directamente del resultado del login o registro.
    // Esto asume que tu `AuthService` devuelve 'usuario' y 'token' en caso de éxito.
    final usuarioData = result['usuario'];
    final token = result['token']; // ✅ ¡Más directo y seguro!

    // Verificamos que los datos necesarios no sean nulos
    if (usuarioData != null && token != null && mounted) {
      final usuario = UsuarioModel.fromJson(usuarioData);
      
      // Construimos la URL del WebSocket con los datos frescos
      final String wsUrl = '${Config.wsBaseUrl}/user/${usuario.id}/?token=$token';

      // Inicializamos el ChatProvider y esperamos a que termine
      await context.read<ChatProvider>().initializeUser(usuario, wsUrl);
      
      // Navegamos a la pantalla principal
      context.go('/home/0');

    } else {
      // Manejar el caso improbable de que el login sea exitoso pero no devuelva usuario o token
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al procesar los datos del login.'), backgroundColor: Colors.red),
      );
    }
  } else {
    // Mostrar mensaje de error si el login/registro falló
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'] ?? 'Ocurrió un error.'), backgroundColor: Colors.red),
    );
  }
}

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _usernameController.clear(); _passwordController.clear();
      _nombreController.clear(); _correoController.clear();
      _ciController.clear(); _telefonoController.clear();
      _ubicacionController.clear(); _fechaNacimientoController.clear();
      _numeroLicenciaController.clear(); _experienciaController.clear();
    });
  }

  // MEJORA: Función para mostrar el calendario
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // Fecha inicial (hace 20 años)
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'), // Opcional: para calendario en español
    );
    if (picked != null) {
      setState(() {
        // Formateamos la fecha al formato que necesita el backend: YYYY-MM-DD
        _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.real_estate_agent_rounded, size: 60, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Bienvenido de Vuelta' : 'Crea tu Cuenta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Ingresa tus credenciales para continuar' : 'Completa el formulario para unirte',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  // MEJORA: Animación al cambiar entre Login y Registro
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _isLogin ? _buildLoginFields() : _buildRegisterFields(),
                  ),
                  
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleSubmit,
                          child: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
                    
                  ),
                  if (_isLogin) // Muestra el botón solo en la pantalla de Login
                  TextButton(
                    onPressed: _isLoading ? null : () => context.push('/recuperar-password'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para los campos de Login
  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildTextField(_usernameController, 'Nombre de Usuario', Icons.account_circle_outlined),
        _buildTextField(_passwordController, 'Contraseña', Icons.lock_outline, obscureText: !_showPassword, suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        )),
      ],
    );
  }

  // Widget para los campos de Registro
  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register'),
      children: [
        _buildUserTypeSwitch(),
        _buildTextField(_nombreController, 'Nombre Completo', Icons.person_outline),
        _buildTextField(_correoController, 'Correo Electrónico', Icons.email_outlined, keyboardType: TextInputType.emailAddress, isEmail: true),
        _buildTextField(_usernameController, 'Nombre de Usuario', Icons.account_circle_outlined),
        _buildTextField(_passwordController, 'Contraseña', Icons.lock_outline, obscureText: !_showPassword, isPassword: true, suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        )),
        _buildTextField(_ciController, 'CI', Icons.badge_outlined),
        _buildTextField(_telefonoController, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone),
        if (_userType == 'cliente') ...[
          _buildTextField(_ubicacionController, 'Ubicación', Icons.location_city_outlined),
          // MEJORA: Campo de fecha con selector de calendario
          _buildDateField(_fechaNacimientoController, 'Fecha de Nacimiento', Icons.calendar_today_outlined),
        ] else ...[ // Agente
          _buildTextField(_numeroLicenciaController, 'Número de Licencia', Icons.card_membership_outlined),
          _buildTextField(_experienciaController, 'Años de Experiencia', Icons.work_history_outlined, keyboardType: TextInputType.number),
        ]
      ],
    );
  }

  Widget _buildUserTypeSwitch() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Cliente'),
            Switch(
              value: _userType == 'agente',
              onChanged: (value) {
                setState(() { _userType = value ? 'agente' : 'cliente'; });
              },
            ),
            const Text('Agente'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon), suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: Colors.grey.shade100,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) return '$label es requerido';
          if (isEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Por favor, ingrese un correo válido';
          if (isPassword && value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true, // Evita que el usuario escriba manualmente
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: Colors.grey.shade100,
        ),
        onTap: () => _selectDate(context),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label es requerido';
          return null;
        },
      ),
    );
  }
}