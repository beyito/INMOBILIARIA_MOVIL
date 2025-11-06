class Config {
  // --- CONFIGURACIÓN DE PRODUCCIÓN (PARA EL BACKEND DESPLEGADO) ---
  // Comentamos la versión de producción
  // static const String baseUrl = 'https://inmobiliaria-backend-qqwv.onrender.com';
  // static const String wsBaseUrl = 'wss://inmobiliaria-backend-qqwv.onrender.com/ws';

  // --- CONFIGURACIÓN DE DESARROLLO (CUANDO PRUEBAS EN TU PC) ---
  // Descomentamos la versión de desarrollo
  static const String baseUrl = 'http://192.168.100.148:8000';
  static const String wsBaseUrl = 'ws://192.168.100.148:8000/ws';

  // API KEY DEL MAPTILER
  static const String mapTilerApiKey = 'B8Miw1FDCjUZycbqqzUP'; // 🔑 tu clave
}