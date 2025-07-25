import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../auth/LoginScreen.dart';
import 'EditProfileScreen.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final apiClient = sl<ApiClient>();
      final profileResponse = await apiClient.getProfile();

      setState(() {
        _userData = profileResponse['usuario'];
        _profileData = profileResponse['perfil'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.logout();

      // Limpiar datos de sesión
      final prefs = sl<SharedPreferences>();
      await prefs.clear();

      // Navegar al login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('Error en logout: $e');
      // Aún así limpiar datos locales y navegar
      final prefs = sl<SharedPreferences>();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
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

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'estudiante':
        return 'Estudiante Activo';
      case 'docente':
        return 'Docente';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(
        child: Text('Error cargando perfil'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildPersonalInfo(context),
          const SizedBox(height: 20),
          _buildAchievements(),
          const SizedBox(height: 20),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final userName = _userData!['nombre_completo'] ?? 'Usuario';
    final userRole = _userData!['rol'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _getInitials(userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      onPressed: () {
                        // Handle photo upload
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de cambio de foto en desarrollo'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleDisplayName(userRole),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'title': 'Cursos\nMatriculados', 'value': '2', 'icon': Icons.school, 'color': Colors.blue},
      {'title': 'Tareas\nCompletadas', 'value': '15', 'icon': Icons.assignment_turned_in, 'color': Colors.green},
      {'title': 'Asistencia\nPromedio', 'value': '92%', 'icon': Icons.check_circle, 'color': Colors.purple},
      {'title': 'Calificación\nPromedio', 'value': '8.5', 'icon': Icons.grade, 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: (stat['color'] as Color).withOpacity(0.1),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    final infoItems = [
      {'label': 'Nombre Completo', 'value': _userData!['nombre_completo'] ?? '', 'icon': Icons.person},
      {'label': 'Correo Electrónico', 'value': _userData!['correo'] ?? '', 'icon': Icons.email},
      {'label': 'Teléfono', 'value': _userData!['telefono'] ?? 'No especificado', 'icon': Icons.phone},
      {'label': 'Cédula', 'value': _userData!['cedula'] ?? 'No especificada', 'icon': Icons.badge},
      {'label': 'Rol', 'value': _getRoleDisplayName(_userData!['rol'] ?? ''), 'icon': Icons.school},
    ];

    // Agregar campos específicos del perfil
    if (_profileData != null) {
      if (_userData!['rol'] == 'estudiante') {
        infoItems.addAll([
          {'label': 'Nivel de Estudio', 'value': _profileData!['nivel_estudio'] ?? '', 'icon': Icons.school},
          {'label': 'Género', 'value': _profileData!['genero'] ?? '', 'icon': Icons.person_outline},
          {'label': 'Estado Civil', 'value': _profileData!['estado_civil'] ?? '', 'icon': Icons.favorite},
        ]);
      } else if (_userData!['rol'] == 'docente') {
        infoItems.addAll([
          {'label': 'Especialización', 'value': _profileData!['especialization'] ?? '', 'icon': Icons.work},
        ]);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          userData: _userData!,
                          profileData: _profileData,
                        ),
                      ),
                    ).then((_) {
                      // Recargar datos al volver
                      _loadProfileData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...infoItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          item['value'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {
        'title': 'Perfect Attendance',
        'description': 'Asistencia perfecta por 3 meses',
        'date': '2024-01-15',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'title': 'Speaking Champion',
        'description': 'Mejor puntuación en Speaking Test',
        'date': '2024-01-10',
        'icon': Icons.mic,
        'color': Colors.blue,
      },
      {
        'title': 'Grammar Master',
        'description': 'Completó todos los ejercicios de gramática',
        'date': '2024-01-05',
        'icon': Icons.book,
        'color': Colors.green,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logros Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...achievements.map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (achievement['color'] as Color).withOpacity(0.1),
                    child: Icon(
                      achievement['icon'] as IconData,
                      color: achievement['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          achievement['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          achievement['date'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Handle settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de configuración en desarrollo'),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Configuración'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}