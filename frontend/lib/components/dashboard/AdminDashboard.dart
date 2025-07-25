import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../admin/CreateNewsScreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> systemStats = {};
  List<Map<String, dynamic>> recentActivities = [];
  Map<String, dynamic> attendanceOverview = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final apiClient = sl<ApiClient>();

      // Cargar datos específicos del administrador
      final results = await Future.wait([
        apiClient.getSystemStats().catchError((e) => <String, dynamic>{}),
        apiClient.getRecentActivities().catchError((e) => <Map<String, dynamic>>[]),
        apiClient.getGlobalAttendanceStats().catchError((e) => <String, dynamic>{}),
      ]);

      setState(() {
        systemStats = results[0] as Map<String, dynamic>;
        recentActivities = results[1] as List<Map<String, dynamic>>;
        attendanceOverview = results[2] as Map<String, dynamic>;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
        _loadSampleData();
      });
    }
  }

  void _loadSampleData() {
    systemStats = {
      'total_students': 156,
      'total_teachers': 12,
      'total_courses': 8,
      'active_enrollments': 234,
      'total_news': 15,
      'pending_tasks': 45,
      'system_health': 98.5,
    };

    recentActivities = [
      {
        'type': 'enrollment',
        'description': 'Nuevo estudiante matriculado en Inglés B2',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        'user': 'María García',
      },
      {
        'type': 'task_created',
        'description': 'Tarea creada: Grammar Exercise - Present Perfect',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'user': 'Prof. Sarah Johnson',
      },
      {
        'type': 'news_published',
        'description': 'Nueva noticia publicada: Evento Cultural English Day',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'user': 'Admin Sistema',
      },
    ];

    attendanceOverview = {
      'overall_attendance': 89.2,
      'today_sessions': 12,
      'students_present_today': 142,
      'total_students_today': 156,
      'weekly_trend': [85.5, 87.2, 89.1, 88.7, 89.2, 90.1, 89.8],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildSystemStats(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildAttendanceOverview(),
            const SizedBox(height: 20),
            _buildWeeklyTrend(),
            const SizedBox(height: 20),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.primaryGradientDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido, Administrador!',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Panel de Control del Sistema',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Estudiantes', '${systemStats['total_students'] ?? 0}', Icons.school),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Docentes', '${systemStats['total_teachers'] ?? 0}', Icons.person),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSystemStats() {
    final stats = [
      {'title': 'Cursos\nActivos', 'value': '${systemStats['total_courses'] ?? 0}', 'icon': Icons.book, 'color': Colors.blue},
      {'title': 'Matrículas\nActivas', 'value': '${systemStats['active_enrollments'] ?? 0}', 'icon': Icons.assignment_ind, 'color': Colors.green},
      {'title': 'Noticias\nPublicadas', 'value': '${systemStats['total_news'] ?? 0}', 'icon': Icons.article, 'color': Colors.orange},
      {'title': 'Salud del\nSistema', 'value': '${(systemStats['system_health'] ?? 0.0).toStringAsFixed(1)}%', 'icon': Icons.health_and_safety, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estadísticas del Sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
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
                      child: Icon(stat['icon'] as IconData, color: stat['color'] as Color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['title'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acciones Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard('Crear Noticia', 'Publicar información', Icons.add_box, Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNewsScreen()))),
            _buildActionCard('Gestionar Usuarios', 'Administrar cuentas', Icons.people, Colors.green, () {}),
            _buildActionCard('Reportes', 'Ver estadísticas', Icons.analytics, Colors.orange, () {}),
            _buildActionCard('Configuración', 'Ajustes del sistema', Icons.settings, Colors.purple, () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    final overallAttendance = attendanceOverview['overall_attendance'] ?? 0.0;
    final todaySessions = attendanceOverview['today_sessions'] ?? 0;
    final studentsPresent = attendanceOverview['students_present_today'] ?? 0;
    final totalStudents = attendanceOverview['total_students_today'] ?? 0;
    final todayPercentage = totalStudents > 0 ? (studentsPresent / totalStudents * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('${overallAttendance.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getAttendanceColor(overallAttendance))),
                      const Text('Promedio General', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${todayPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getAttendanceColor(todayPercentage))),
                      const Text('Hoy', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceInfo('Sesiones Hoy', '$todaySessions', Icons.today),
                _buildAttendanceInfo('Presentes', '$studentsPresent', Icons.check_circle),
                _buildAttendanceInfo('Total', '$totalStudents', Icons.people),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeeklyTrend() {
    final weeklyData = attendanceOverview['weekly_trend'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tendencia Semanal de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 80,
                  maxY: 95,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actividad Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentActivities.length,
          itemBuilder: (context, index) {
            final activity = recentActivities[index];
            final timestamp = DateTime.tryParse(activity['timestamp'] ?? '') ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActivityColor(activity['type']).withOpacity(0.1),
                  child: Icon(_getActivityIcon(activity['type']), color: _getActivityColor(activity['type'])),
                ),
                title: Text(activity['description'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por: ${activity['user'] ?? 'Usuario'}'),
                    Text(_formatTimestamp(timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'enrollment': return Colors.green;
      case 'task_created': return Colors.blue;
      case 'news_published': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'enrollment': return Icons.person_add;
      case 'task_created': return Icons.assignment;
      case 'news_published': return Icons.article;
      default: return Icons.info;
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    }
  }
}