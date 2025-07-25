
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class Services extends StatelessWidget {
  const Services({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Servicios Disponibles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Accede a nuestros servicios educativos complementarios',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: _getUserRole(),
              builder: (context, snapshot) {
                final userRole = snapshot.data ?? 'estudiante';
                final services = _getServicesForRole(userRole);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _buildServiceCard(context, service);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getUserRole() async {
    try {
      final apiClient = sl<ApiClient>();
      final profileData = await apiClient.getProfile();
      return profileData['usuario']['rol'] ?? 'estudiante';
    } catch (e) {
      return 'estudiante';
    }
  }

  List<Map<String, dynamic>> _getServicesForRole(String role) {
    final commonServices = [
      {
        'title': 'Fine Online',
        'description': 'Accede a clases virtuales en vivo con Zoom',
        'icon': Icons.video_call,
        'color': AppTheme.primaryColor,
        'available': true,
        'action': 'zoom',
        'url': 'https://zoom.us/j/1234567890',
        'roles': ['estudiante', 'docente', 'admin'],
      },
      {
        'title': 'Biblioteca Digital',
        'description': 'Acceso a recursos educativos y material complementario',
        'icon': Icons.library_books,
        'color': AppTheme.secondaryColor,
        'available': true,
        'action': 'library',
        'roles': ['estudiante', 'docente', 'admin'],
      },
    ];

    final studentServices = [
      {
        'title': 'Certificados Online',
        'description': 'Genera tu certificado de aprobación de curso al instante',
        'icon': Icons.card_membership,
        'color': AppTheme.successColor,
        'available': true,
        'action': 'certificate',
        'roles': ['estudiante'],
      },
      {
        'title': 'Tutorías Personalizadas',
        'description': 'Sesiones individuales con profesores especializados',
        'icon': Icons.person_pin,
        'color': AppTheme.warningColor,
        'available': true,
        'action': 'tutoring',
        'roles': ['estudiante'],
      },
      {
        'title': 'Evaluaciones Online',
        'description': 'Exámenes de nivelación y progreso disponibles 24/7',
        'icon': Icons.quiz,
        'color': AppTheme.infoColor,
        'available': false,
        'action': 'evaluation',
        'roles': ['estudiante'],
      },
    ];

    final teacherServices = [
      {
        'title': 'Gestión de Calificaciones',
        'description': 'Administra las calificaciones de tus estudiantes',
        'icon': Icons.grade,
        'color': AppTheme.successColor,
        'available': true,
        'action': 'grades_management',
        'roles': ['docente'],
      },
      {
        'title': 'Reportes Académicos',
        'description': 'Genera reportes de progreso y asistencia',
        'icon': Icons.analytics,
        'color': AppTheme.infoColor,
        'available': true,
        'action': 'reports',
        'roles': ['docente'],
      },
      {
        'title': 'Material Didáctico',
        'description': 'Sube y gestiona material educativo',
        'icon': Icons.upload_file,
        'color': AppTheme.warningColor,
        'available': false,
        'action': 'materials',
        'roles': ['docente'],
      },
    ];

    final adminServices = [
      {
        'title': 'Gestión de Usuarios',
        'description': 'Administra estudiantes, docentes y permisos',
        'icon': Icons.people,
        'color': AppTheme.primaryColor,
        'available': true,
        'action': 'user_management',
        'roles': ['admin'],
      },
      {
        'title': 'Configuración del Sistema',
        'description': 'Ajustes generales y configuraciones avanzadas',
        'icon': Icons.settings,
        'color': AppTheme.secondaryColor,
        'available': true,
        'action': 'system_config',
        'roles': ['admin'],
      },
      {
        'title': 'Respaldos y Seguridad',
        'description': 'Gestiona respaldos y configuraciones de seguridad',
        'icon': Icons.security,
        'color': AppTheme.errorColor,
        'available': false,
        'action': 'security',
        'roles': ['admin'],
      },
    ];

    List<Map<String, dynamic>> availableServices = [...commonServices];

    switch (role) {
      case 'estudiante':
        availableServices.addAll(studentServices);
        break;
      case 'docente':
        availableServices.addAll(teacherServices);
        break;
      case 'admin':
        availableServices.addAll(adminServices);
        break;
    }

    return availableServices.where((service) {
      final roles = service['roles'] as List<String>;
      return roles.contains(role);
    }).toList();
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: service['available'] ? () => _handleServiceTap(context, service) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: service['available']
                    ? (service['color'] as Color).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                child: Icon(
                  service['icon'] as IconData,
                  size: 30,
                  color: service['available']
                      ? service['color'] as Color
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                service['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: service['available'] ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                service['description'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: service['available'] ? Colors.grey[600] : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (!service['available'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Próximamente',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleServiceTap(BuildContext context, Map<String, dynamic> service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tap en: ${service['title']}')),
    );
  }
}
