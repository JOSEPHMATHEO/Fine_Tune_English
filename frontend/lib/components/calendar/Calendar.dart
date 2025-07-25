import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../attendance/AttendanceHistory.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<Map<String, dynamic>> _attendanceRecords = [];
  Map<String, dynamic> _attendanceSummary = {};
  Map<DateTime, Map<String, dynamic>> _attendanceData = {};
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      setState(() => _isLoading = true);

      final apiClient = sl<ApiClient>();

      // Obtener rol del usuario
      final profileData = await apiClient.getProfile();
      _userRole = profileData['usuario']['rol'];

      // Cargar datos de asistencia
      final attendanceHistory = await apiClient.getAttendanceHistory();
      final attendanceSummary = await apiClient.getAttendanceSummary();

      // Procesar datos para el calendario
      final Map<DateTime, Map<String, dynamic>> processedData = {};
      for (var record in attendanceHistory) {
        try {
          final date = DateTime.parse(record['session']?['date'] ?? record['date'] ?? '');
          final dateKey = DateTime(date.year, date.month, date.day);

          processedData[dateKey] = {
            'status': record['status'] ?? 'unknown',
            'subject': record['session']?['schedule']?['subject'] ?? record['subject'] ?? 'Clase',
            'time': '${record['session']?['start_time'] ?? '10:00'} - ${record['session']?['end_time'] ?? '12:00'}',
            'classroom': record['session']?['schedule']?['classroom']?['name'] ?? 'Aula',
            'teacher': record['session']?['course_group']?['teacher']?['user']?['nombre_completo'] ?? 'Profesor',
          };
        } catch (e) {
          print('Error procesando registro de asistencia: $e');
        }
      }

      setState(() {
        _attendanceRecords = attendanceHistory;
        _attendanceSummary = attendanceSummary;
        _attendanceData = processedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del calendario: $e');
      setState(() {
        _isLoading = false;
        _loadSampleData();
      });
    }
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _attendanceData = {
      DateTime(now.year, now.month, now.day - 7): {
        'status': 'present',
        'subject': 'Grammar Focus',
        'time': '10:00 - 12:00',
        'classroom': 'Aula 201',
        'teacher': 'Sarah Johnson',
      },
      DateTime(now.year, now.month, now.day - 5): {
        'status': 'present',
        'subject': 'Speaking Practice',
        'time': '14:00 - 16:00',
        'classroom': 'Aula 105',
        'teacher': 'Michael Brown',
      },
      DateTime(now.year, now.month, now.day - 3): {
        'status': 'absent',
        'subject': 'Writing Skills',
        'time': '10:00 - 12:00',
        'classroom': 'Aula 201',
        'teacher': 'Emma Davis',
      },
      DateTime(now.year, now.month, now.day - 1): {
        'status': 'late',
        'subject': 'Listening Practice',
        'time': '16:00 - 18:00',
        'classroom': 'Lab Audio',
        'teacher': 'Sarah Johnson',
      },
    };

    _attendanceSummary = {
      'total_sessions': 15,
      'present_count': 12,
      'absent_count': 2,
      'late_count': 1,
      'excused_count': 0,
      'attendance_percentage': 86.7,
    };
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
              Text('Cargando calendario...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCalendarData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendario y Asistencia',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildCalendar(),
              const SizedBox(height: 20),
              _buildSelectedDateInfo(),
              const SizedBox(height: 20),
              _buildAttendanceSummary(),
              const SizedBox(height: 20),
              _buildUpcomingClasses(),
              const SizedBox(height: 20),
              _buildAttendanceHistoryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                    });
                  },
                  icon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                ),
                Text(
                  '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                    });
                  },
                  icon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week
            Row(
              children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
                  .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar Grid
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayIndex = index - firstDayWeekday + 1;

        if (dayIndex < 1 || dayIndex > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(_focusedDate.year, _focusedDate.month, dayIndex);
        final attendance = _attendanceData[date];
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, _selectedDate);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : isToday
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : attendance != null
                  ? _getAttendanceColor(attendance['status'])
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayIndex.toString(),
                    style: TextStyle(
                      color: isSelected || isToday ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (attendance != null)
                    Icon(
                      _getAttendanceIcon(attendance['status']),
                      size: 12,
                      color: isSelected || isToday ? Colors.white : AppTheme.textSecondaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateInfo() {
    final attendance = _attendanceData[_selectedDate];

    if (attendance == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 48,
                color: AppTheme.textTertiaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'No hay clases programadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                _formatSelectedDate(_selectedDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final statusInfo = _getStatusInfo(attendance['status']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusInfo['color'],
                  child: Icon(
                    statusInfo['icon'],
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance['subject'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _formatSelectedDate(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusInfo['color'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, 'Horario', attendance['time']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Aula', attendance['classroom']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Profesor', attendance['teacher']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    final totalSessions = _attendanceSummary['total_sessions'] ?? 0;
    final presentCount = _attendanceSummary['present_count'] ?? 0;
    final absentCount = _attendanceSummary['absent_count'] ?? 0;
    final lateCount = _attendanceSummary['late_count'] ?? 0;
    final excusedCount = _attendanceSummary['excused_count'] ?? 0;
    final percentage = _attendanceSummary['attendance_percentage'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Asistencia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAttendanceStatCard('Presente', '$presentCount', AppTheme.successColor, Icons.check_circle)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttendanceStatCard('Tardanza', '$lateCount', AppTheme.warningColor, Icons.access_time)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttendanceStatCard('Ausente', '$absentCount', AppTheme.errorColor, Icons.cancel)),
                const SizedBox(width: 8),
                Expanded(child: _buildAttendanceStatCard('Justificada', '$excusedCount', AppTheme.infoColor, Icons.event_note)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Porcentaje de Asistencia: ${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    // Generar clases próximas basadas en el rol del usuario
    final upcomingClasses = _generateUpcomingClasses();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _userRole == 'docente' ? 'Próximas Clases a Impartir' : 'Próximas Clases',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcomingClasses.length,
          itemBuilder: (context, index) {
            final classItem = upcomingClasses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.schedule,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  classItem['class'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${classItem['date']} - ${classItem['time']}'),
                    Text(classItem['room'] as String),
                    if (_userRole == 'docente' && classItem['students'] != null)
                      Text('${classItem['students']} estudiantes'),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Próxima',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateUpcomingClasses() {
    final now = DateTime.now();
    final baseClasses = [
      {
        'class': 'Grammar Focus',
        'date': _formatDate(now.add(const Duration(days: 1))),
        'time': '10:00 - 12:00',
        'room': 'Aula 201',
        'students': 25,
      },
      {
        'class': 'Speaking Practice',
        'date': _formatDate(now.add(const Duration(days: 2))),
        'time': '14:00 - 16:00',
        'room': 'Aula 105',
        'students': 18,
      },
      {
        'class': 'Writing Skills',
        'date': _formatDate(now.add(const Duration(days: 3))),
        'time': '16:00 - 18:00',
        'room': 'Lab Audio',
        'students': 22,
      },
    ];

    return baseClasses;
  }

  Widget _buildAttendanceHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceHistory(),
            ),
          );
        },
        icon: const Icon(Icons.history),
        label: const Text('Ver Historial Completo de Asistencia'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getAttendanceColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.successColor.withOpacity(0.3);
      case 'absent':
        return AppTheme.errorColor.withOpacity(0.3);
      case 'late':
        return AppTheme.warningColor.withOpacity(0.3);
      case 'excused':
        return AppTheme.infoColor.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  IconData _getAttendanceIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_note;
      default:
        return Icons.help;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return {
          'text': 'Presente',
          'color': AppTheme.successColor,
          'icon': Icons.check_circle,
        };
      case 'absent':
        return {
          'text': 'Ausente',
          'color': AppTheme.errorColor,
          'icon': Icons.cancel,
        };
      case 'late':
        return {
          'text': 'Tardanza',
          'color': AppTheme.warningColor,
          'icon': Icons.access_time,
        };
      case 'excused':
        return {
          'text': 'Justificada',
          'color': AppTheme.infoColor,
          'icon': Icons.event_note,
        };
      default:
        return {
          'text': 'Desconocido',
          'color': Colors.grey,
          'icon': Icons.help,
        };
    }
  }
}