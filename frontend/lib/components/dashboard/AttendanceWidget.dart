import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../attendance/AttendanceHistory.dart';

class AttendanceWidget extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceWidget({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    if (attendanceData.isEmpty) {
      return _buildEmptyState();
    }

    final totalSessions = attendanceData['total_sessions'] ?? 0;
    final presentCount = attendanceData['present_count'] ?? 0;
    final absentCount = attendanceData['absent_count'] ?? 0;
    final lateCount = attendanceData['late_count'] ?? 0;
    final excusedCount = attendanceData['excused_count'] ?? 0;
    final percentage = attendanceData['attendance_percentage'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mi Asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistory(),
                  ),
                );
              },
              child: const Text('Ver historial'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Porcentaje principal
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getPercentageColor(percentage).withOpacity(0.1),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getPercentageColor(percentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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

                const SizedBox(height: 20),

                // Gráfico circular
                if (totalSessions > 0) ...[
                  SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(
                            presentCount, absentCount, lateCount, excusedCount
                        ),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Estadísticas detalladas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('Presente', presentCount, Colors.green, Icons.check_circle),
                    ),
                    Expanded(
                      child: _buildStatItem('Ausente', absentCount, Colors.red, Icons.cancel),
                    ),
                    Expanded(
                      child: _buildStatItem('Tardanza', lateCount, Colors.orange, Icons.access_time),
                    ),
                    Expanded(
                      child: _buildStatItem('Justificada', excusedCount, Colors.blue, Icons.event_note),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mi Asistencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay datos de asistencia',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los datos aparecerán cuando el docente registre la asistencia',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      int present, int absent, int late, int excused
      ) {
    final sections = <PieChartSectionData>[];

    if (present > 0) {
      sections.add(PieChartSectionData(
        value: present.toDouble(),
        color: Colors.green,
        radius: 25,
        showTitle: false,
      ));
    }

    if (absent > 0) {
      sections.add(PieChartSectionData(
        value: absent.toDouble(),
        color: Colors.red,
        radius: 25,
        showTitle: false,
      ));
    }

    if (late > 0) {
      sections.add(PieChartSectionData(
        value: late.toDouble(),
        color: Colors.orange,
        radius: 25,
        showTitle: false,
      ));
    }

    if (excused > 0) {
      sections.add(PieChartSectionData(
        value: excused.toDouble(),
        color: Colors.blue,
        radius: 25,
        showTitle: false,
      ));
    }

    return sections;
  }

  Widget _buildStatItem(String title, int count, Color color, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
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
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}