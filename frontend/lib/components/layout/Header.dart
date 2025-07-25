import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../notifications/NotificationBell.dart';
import 'dart:convert';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  String _userName = 'Usuario';
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final apiClient = sl<ApiClient>();
      final profileData = await apiClient.getProfile();

      setState(() {
        _userName = profileData['usuario']['nombre_completo'] ?? 'Usuario';
        _userRole = _getRoleDisplayName(profileData['usuario']['rol'] ?? '');
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      // Fallback a datos locales si hay error
      final prefs = sl<SharedPreferences>();
      final userData = prefs.getString(AppConfig.userDataKey);
      if (userData != null) {
        try {
          final userMap = json.decode(userData);
          setState(() {
            _userName = userMap['nombre_completo'] ?? 'Usuario';
            _userRole = _getRoleDisplayName(userMap['rol'] ?? '');
            _isLoading = false;
          });
        } catch (e) {
          print('Error parseando datos locales: $e');
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'estudiante':
        return 'Estudiante';
      case 'docente':
        return 'Docente';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: _isLoading
          ? const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cargando...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Usuario',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _getInitials(_userName),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${_getFirstName(_userName)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                _userRole,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        const NotificationBell(),
        const SizedBox(width: 8),
      ],
      backgroundColor: AppTheme.institutionalWhite,
      foregroundColor: AppTheme.institutionalBlue,
    );
  }
}