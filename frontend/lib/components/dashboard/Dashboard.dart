import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import 'StudentDashboard.dart';
import 'TeacherDashboard.dart';
import 'AdminDashboard.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final apiClient = sl<ApiClient>();
      final profileData = await apiClient.getProfile();
      setState(() {
        _userRole = profileData['usuario']['rol'] ?? '';
        _isLoading = false;
      });
      print('✅ Rol de usuario cargado para dashboard: $_userRole');
    } catch (e) {
      print('❌ Error cargando rol del usuario: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando dashboard...'),
          ],
        ),
      );
    }

    // Retornar dashboard específico según el rol
    switch (_userRole) {
      case 'admin':
        return const AdminDashboard();
      case 'docente':
        return const TeacherDashboard();
      case 'estudiante':
      default:
        return const StudentDashboard();
    }
  }
}