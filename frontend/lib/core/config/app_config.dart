import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'dart:io' show Platform; // Solo se usa si no es Web

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // URL para entorno web
      return 'http://127.0.0.1:8000/api'; // ← Cambia esto por la URL de producción web
    } else if (Platform.isAndroid) {
      // Dirección IP especial para emulador Android
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      // Default para desktop o fallback
      return 'http://localhost:8000';
    }
  }



// Configuración alternativa para diferentes entornos
  static const String baseUrlLocalhost = 'http://localhost:8000/api';
  static const String baseUrl127 = 'http://127.0.0.1:8000/api';

  static const String appName = 'Fine Tune English';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Timeouts para conexiones
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;

  // Cache Duration
  static const Duration cacheExpiration = Duration(hours: 1);

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}