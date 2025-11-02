class Config {
  // --- CONFIGURACIÓN DE PRODUCCIÓN (PARA EL BACKEND DESPLEGADO) ---
  
  // La URL principal de tu API en la nube (usa https)
  static const String baseUrl = 'https://inmobiliaria-backend-qqwv.onrender.com';
  
  // La URL para WebSockets debe usar el mismo dominio pero con 'wss' (WebSocket Seguro)
  static const String wsBaseUrl = 'wss://inmobiliaria-backend-qqwv.onrender.com/ws';

  // --- CONFIGURACIÓN DE DESARROLLO (CUANDO PRUEBAS EN TU PC) ---
  // Las dejamos comentadas por si las necesitas en el futuro
  // static const String baseUrl = 'http://192.168.100.148:8000';
  // static const String wsBaseUrl = 'ws://192.168.100.148:8000/ws';

  // API KEY DEL MAPTILER
  static const String mapTilerApiKey = 'B8Miw1FDCjUZycbqqzUP'; // 🔑 tu clave
}