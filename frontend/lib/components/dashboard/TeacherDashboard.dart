import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../teacher/CreateTaskScreen.dart';
import '../teacher/AttendanceScreen.dart';
import '../teacher/TeacherTasksScreen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Map<String, dynamic> teacherStats = {};
  List<Map<String, dynamic>> recentTasks = [];
  List<Map<String, dynamic>> courseGroups = [];
  Map<String, dynamic> attendanceStats = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final apiClient = sl<ApiClient>();

      // Cargar datos específicos del docente
      final results = await Future.wait([
        apiClient.getTeacherCourseGroups().catchError((e) => <Map<String, dynamic>>[]),
        apiClient.getTeacherTasks().catchError((e) => <Map<String, dynamic>>[]),
        apiClient.getTeacherAttendanceStats().catchError((e) => <String, dynamic>{}),
      ]);

      setState(() {
        courseGroups = results[0] as List<Map<String, dynamic>>;
        recentTasks = (results[1] as List<Map<String, dynamic>>).take(5).toList();
        attendanceStats = results[2] as Map<String, dynamic>;
        _calculateTeacherStats();
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

  void _calculateTeacherStats() {
    int totalStudents = 0;
    for (var group in courseGroups) {
      totalStudents += (group['enrolled_students'] ?? 0) as int;
    }

    int pendingSubmissions = 0;
    for (var task in recentTasks) {
      pendingSubmissions += (task['pending_count'] ?? 0) as int;
    }

    teacherStats = {
      'total_groups': courseGroups.length,
      'total_students': totalStudents,
      'total_tasks': recentTasks.length,
      'pending_submissions': pendingSubmissions,
      'attendance_average': attendanceStats['average_attendance'] ?? 0.0,
    };
  }

  void _loadSampleData() {
    courseGroups = [
      {
        'id': 1,
        'name': 'Grupo A',
        'course': {'name': 'Inglés Intermedio B1'},
        'enrolled_students': 25,
        'attendance_rate': 92.5,
      },
      {
        'id': 2,
        'name': 'Grupo B',
        'course': {'name': 'Inglés Avanzado C1'},
        'enrolled_students': 18,
        'attendance_rate': 88.3,
      },
    ];

    recentTasks = [
      {
        'id': 1,
        'title': 'Grammar Exercise - Present Perfect',
        'course_group_data': {'course': {'name': 'Inglés Intermedio B1'}},
        'total_students': 25,
        'submitted_count': 18,
        'pending_count': 7,
        'due_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Speaking Practice - Job Interview',
        'course_group_data': {'course': {'name': 'Inglés Avanzado C1'}},
        'total_students': 18,
        'submitted_count': 12,
        'pending_count': 6,
        'due_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      },
    ];

    attendanceStats = {
      'average_attendance': 90.4,
      'total_sessions': 45,
      'students_present_today': 38,
      'total_students_today': 43,
    };

    _calculateTeacherStats();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildAttendanceChart(),
            const SizedBox(height: 20),
            _buildRecentTasks(),
            const SizedBox(height: 20),
            _buildCourseGroups(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.secondaryGradientDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido, Profesor!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Panel de Control Docente',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Grupos', '${teacherStats['total_groups'] ?? 0}', Icons.groups),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Estudiantes', '${teacherStats['total_students'] ?? 0}', Icons.people),
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

  Widget _buildStatsGrid() {
    final stats = [
      {'title': 'Tareas\nCreadas', 'value': '${teacherStats['total_tasks'] ?? 0}', 'icon': Icons.assignment, 'color': Colors.blue},
      {'title': 'Entregas\nPendientes', 'value': '${teacherStats['pending_submissions'] ?? 0}', 'icon': Icons.pending_actions, 'color': Colors.orange},
      {'title': 'Asistencia\nPromedio', 'value': '${(teacherStats['attendance_average'] ?? 0.0).toStringAsFixed(1)}%', 'icon': Icons.check_circle, 'color': Colors.green},
      {'title': 'Sesiones\nHoy', 'value': '${attendanceStats['total_sessions_today'] ?? 0}', 'icon': Icons.today, 'color': Colors.purple},
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
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acciones Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Crear Tarea',
                'Nueva asignación',
                Icons.add_task,
                Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTaskScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Asistencia',
                'Marcar presente',
                Icons.how_to_reg,
                Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
              ),
            ),
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
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asistencia por Grupo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < courseGroups.length) {
                            return Text(
                              courseGroups[value.toInt()]['name'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            );
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
                  borderData: FlBorderData(show: false),
                  barGroups: courseGroups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    final attendanceRate = group['attendance_rate'] ?? 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: attendanceRate.toDouble(),
                          color: _getAttendanceColor(attendanceRate),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecentTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tareas Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherTasksScreen())),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTasks.length,
          itemBuilder: (context, index) {
            final task = recentTasks[index];
            final submittedCount = task['submitted_count'] ?? 0;
            final totalStudents = task['total_students'] ?? 0;
            final percentage = totalStudents > 0 ? (submittedCount / totalStudents * 100) : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.assignment, color: Colors.blue),
                ),
                title: Text(task['title'] ?? 'Tarea sin título'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task['course_group_data']?['course']?['name'] ?? 'Curso'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(_getSubmissionColor(percentage)),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$submittedCount/$totalStudents', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getSubmissionColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCourseGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mis Grupos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courseGroups.length,
          itemBuilder: (context, index) {
            final group = courseGroups[index];
            final attendanceRate = group['attendance_rate'] ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.groups, color: Colors.green),
                ),
                title: Text('${group['course']?['name']} - ${group['name']}'),
                subtitle: Text('${group['enrolled_students']} estudiantes'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${attendanceRate.toStringAsFixed(1)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getAttendanceColor(attendanceRate))),
                    const Text('Asistencia', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}