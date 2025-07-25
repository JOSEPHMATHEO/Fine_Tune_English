import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../dashboard/Dashboard.dart';
import '../tasks/TasksScreen.dart';
import '../services/Services.dart';
import '../calendar/Calendar.dart';
import '../profile/Profile.dart';
import '../admin/AdminPanel.dart';
import '../teacher/TeacherPanel.dart';
import 'Header.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _currentIndex = 0;
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
      print('✅ Rol de usuario cargado: $_userRole');
    } catch (e) {
      print('❌ Error cargando rol del usuario: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Widget> _getPages() {
    final commonPages = [
      const Dashboard(),
      const TasksScreen(),
      const Services(),
      const Calendar(),
    ];

    switch (_userRole) {
      case 'admin':
        return [
          ...commonPages,
          const AdminPanel(),
          const Profile(),
        ];
      case 'docente':
        return [
          ...commonPages,
          const TeacherPanel(),
          const Profile(),
        ];
      default: // estudiante
        return [
          ...commonPages,
          const Profile(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final commonItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'Tareas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.business_center),
        label: 'Servicios',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Agenda',
      ),
    ];

    switch (_userRole) {
      case 'admin':
        return [
          ...commonItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ];
      case 'docente':
        return [
          ...commonItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Docente',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ];
      default: // estudiante
        return [
          ...commonItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando perfil...'),
            ],
          ),
        ),
      );
    }

    final pages = _getPages();
    final navItems = _getNavItems();

    return Scaffold(
      appBar: const Header(),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppTheme.institutionalWhite,
        selectedItemColor: AppTheme.institutionalBlue,
        unselectedItemColor: AppTheme.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}