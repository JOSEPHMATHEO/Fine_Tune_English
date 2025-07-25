import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/injection_container.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'components/auth/LoginScreen.dart';
import 'components/layout/Layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias
  await initializeDependencies();

  runApp(const FineTuneEnglishApp());
}

class FineTuneEnglishApp extends StatelessWidget {
  const FineTuneEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('🔍 Verificando estado de autenticación...');
    final prefs = sl<SharedPreferences>();
    final token = prefs.getString(AppConfig.accessTokenKey);

    if (token != null) {
      print('✅ Token encontrado: ${token.substring(0, 50)}...');
    } else {
      print('❌ No hay token guardado');
    }

    setState(() {
      _isAuthenticated = token != null;
      _isLoading = false;
    });

    print('🔐 Estado de autenticación: ${_isAuthenticated ? "Autenticado" : "No autenticado"}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const Layout() : const LoginScreen();
  }
}