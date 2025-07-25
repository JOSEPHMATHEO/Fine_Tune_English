import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  Map<String, dynamic> _attendanceSummary = {};
  List<String> _subjects = [];
  bool _isLoading = true;
  String? _selectedSubject;
  String? _selectedMonth;

  final List<String> _months = [
    'Todos',
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    try {
      setState(() => _isLoading = true);

      final apiClient = sl<ApiClient>();

      // Cargar datos de asistencia
      final attendanceData = await apiClient.getAttendanceHistory();
      final summaryData = await apiClient.getAttendanceSummary();

      setState(() {
        _attendanceRecords = attendanceData;
        _filteredRecords = List.from(_attendanceRecords);
        _attendanceSummary = summaryData;
        _subjects = _extractSubjects(_attendanceRecords);
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando historial de asistencia: $e');
      setState(() {
        _isLoading = false;
        // Datos de ejemplo para demostración
        _loadSampleData();
      });
    }
  }

  void _loadSampleData() {
    _attendanceRecords = [
      {
        'id': 1,
        'date': '2024-01-15',
        'time': '10:00 - 12:00',
        'subject': 'Grammar Focus',
        'course': 'Inglés Intermedio B1',
        'status': 'present',
        'teacher': 'Sarah Johnson',
        'classroom': 'Aula 201'
      },
      {
        'id': 2,
        'date': '2024-01-17',
        'time': '14:00 - 16:00',
        'subject': 'Speaking Practice',
        'course': 'Inglés Intermedio B1',
        'status': 'present',
        'teacher': 'Michael Brown',
        'classroom': 'Aula 105'
      },
      {
        'id': 3,
        'date': '2024-01-19',
        'time': '10:00 - 12:00',
        'subject': 'Writing Skills',
        'course': 'Inglés Intermedio B1',
        'status': 'absent',
        'teacher': 'Emma Davis',
        'classroom': 'Aula 201'
      },
      {
        'id': 4,
        'date': '2024-01-22',
        'time': '10:00 - 12:00',
        'subject': 'Grammar Focus',
        'course': 'Inglés Intermedio B1',
        'status': 'late',
        'teacher': 'Sarah Johnson',
        'classroom': 'Aula 201'
      },
      {
        'id': 5,
        'date': '2024-01-24',
        'time': '14:00 - 16:00',
        'subject': 'Speaking Practice',
        'course': 'Inglés Intermedio B1',
        'status': 'excused',
        'teacher': 'Michael Brown',
        'classroom': 'Aula 105'
      },
      {
        'id': 6,
        'date': '2024-02-05',
        'time': '10:00 - 12:00',
        'subject': 'Listening Comprehension',
        'course': 'Inglés Intermedio B1',
        'status': 'present',
        'teacher': 'Emma Davis',
        'classroom': 'Lab Audio'
      },
      {
        'id': 7,
        'date': '2024-02-07',
        'time': '14:00 - 16:00',
        'subject': 'Conversation Practice',
        'course': 'Inglés Intermedio B1',
        'status': 'present',
        'teacher': 'Sarah Johnson',
        'classroom': 'Aula 105'
      },
      {
        'id': 8,
        'date': '2024-02-12',
        'time': '10:00 - 12:00',
        'subject': 'Grammar Focus',
        'course': 'Inglés Intermedio B1',
        'status': 'absent',
        'teacher': 'Michael Brown',
        'classroom': 'Aula 201'
      },
    ];

    _attendanceSummary = {
      'total_sessions': 8,
      'present_count': 4,
      'absent_count': 2,
      'late_count': 1,
      'excused_count': 1,
      'attendance_percentage': 75.0,
      'by_subject': {
        'Grammar Focus': {'total': 3, 'present': 2, 'percentage': 66.7},
        'Speaking Practice': {'total': 2, 'present': 2, 'percentage': 100.0},
        'Writing Skills': {'total': 1, 'present': 0, 'percentage': 0.0},
        'Listening Comprehension': {'total': 1, 'present': 1, 'percentage': 100.0},
        'Conversation Practice': {'total': 1, 'present': 1, 'percentage': 100.0},
      }
    };

    _filteredRecords = List.from(_attendanceRecords);
    _subjects = _extractSubjects(_attendanceRecords);
  }

  List<String> _extractSubjects(List<Map<String, dynamic>> records) {
    final subjects = records.map((record) => record['subject'] as String).toSet().toList();
    subjects.sort();
    return ['Todas las materias', ...subjects];
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _attendanceRecords.where((record) {
        bool matchesSubject = _selectedSubject == null ||
            _selectedSubject == 'Todas las materias' ||
            record['subject'] == _selectedSubject;

        bool matchesMonth = _selectedMonth == null ||
            _selectedMonth == 'Todos' ||
            _getMonthFromDate(record['date']) == _selectedMonth;

        return matchesSubject && matchesMonth;
      }).toList();
    });
  }

  String _getMonthFromDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _months[date.month];
    } catch (e) {
      return 'Enero';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Asistencia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 20),
              _buildAttendanceChart(),
              const SizedBox(height: 20),
              _buildSubjectBreakdown(),
              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 20),
              _buildAttendanceTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSessions = _attendanceSummary['total_sessions'] ?? 0;
    final presentCount = _attendanceSummary['present_count'] ?? 0;
    final absentCount = _attendanceSummary['absent_count'] ?? 0;
    final lateCount = _attendanceSummary['late_count'] ?? 0;
    final excusedCount = _attendanceSummary['excused_count'] ?? 0;
    final percentage = _attendanceSummary['attendance_percentage'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Tarjeta principal de porcentaje
        Card(
          color: _getPercentageColor(percentage).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getPercentageColor(percentage),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Porcentaje de Asistencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$presentCount de $totalSessions clases',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tarjetas de estadísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Presente',
                presentCount.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Ausente',
                absentCount.toString(),
                Colors.red,
                Icons.cancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Tardanza',
                lateCount.toString(),
                Colors.orange,
                Icons.access_time,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Justificada',
                excusedCount.toString(),
                Colors.blue,
                Icons.event_note,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
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
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final presentCount = _attendanceSummary['present_count'] ?? 0;
    final absentCount = _attendanceSummary['absent_count'] ?? 0;
    final lateCount = _attendanceSummary['late_count'] ?? 0;
    final excusedCount = _attendanceSummary['excused_count'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: presentCount + absentCount + lateCount + excusedCount > 0
                  ? PieChart(
                PieChartData(
                  sections: [
                    if (presentCount > 0)
                      PieChartSectionData(
                        value: presentCount.toDouble(),
                        title: 'Presente\n$presentCount',
                        color: Colors.green,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (absentCount > 0)
                      PieChartSectionData(
                        value: absentCount.toDouble(),
                        title: 'Ausente\n$absentCount',
                        color: Colors.red,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (lateCount > 0)
                      PieChartSectionData(
                        value: lateCount.toDouble(),
                        title: 'Tardanza\n$lateCount',
                        color: Colors.orange,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (excusedCount > 0)
                      PieChartSectionData(
                        value: excusedCount.toDouble(),
                        title: 'Justificada\n$excusedCount',
                        color: Colors.blue,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay datos de asistencia',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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

  Widget _buildSubjectBreakdown() {
    final bySubject = _attendanceSummary['by_subject'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asistencia por Materia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...bySubject.entries.map((entry) {
              final subject = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final total = data['total'] ?? 0;
              final present = data['present'] ?? 0;
              final percentage = data['percentage'] ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '$present/$total (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: _getPercentageColor(percentage),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: total > 0 ? present / total : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPercentageColor(percentage),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      prefixIcon: Icon(Icons.book),
                    ),
                    items: _subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    items: _months.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSubject = null;
                      _selectedMonth = null;
                      _filteredRecords = List.from(_attendanceRecords);
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_filteredRecords.length} registros encontrados',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_filteredRecords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron registros',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intenta ajustar los filtros',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = _filteredRecords[index];
                  return _buildAttendanceRow(record);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRow(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final statusInfo = _getStatusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: statusInfo['color'],
                child: Icon(
                  statusInfo['icon'],
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['subject'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      record['course'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusInfo['text'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(record['date']),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                record['time'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                record['classroom'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Prof. ${record['teacher']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return {
          'text': 'Presente',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'absent':
        return {
          'text': 'Ausente',
          'color': Colors.red,
          'icon': Icons.cancel,
        };
      case 'late':
        return {
          'text': 'Tardanza',
          'color': Colors.orange,
          'icon': Icons.access_time,
        };
      case 'excused':
        return {
          'text': 'Justificada',
          'color': Colors.blue,
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

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}