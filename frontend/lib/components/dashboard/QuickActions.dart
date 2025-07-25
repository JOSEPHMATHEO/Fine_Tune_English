import 'package:flutter/material.dart';
import '../../core/models/matricula.dart';
import '../classes/Classes.dart';
import '../calendar/Calendar.dart';
import '../attendance/AttendanceHistory.dart';
import '../tasks/TaskDetailScreen.dart';

class QuickActions extends StatelessWidget {
  final List<Matricula> matriculas;
  final List<Map<String, dynamic>> tareas;

  const QuickActions({
    super.key,
    required this.matriculas,
    required this.tareas,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular próxima clase
    String proximaClase = 'No hay clases';
    String horaClase = '';

    if (matriculas.isNotEmpty) {
      proximaClase = matriculas.first.clase?.componente?.nombre ?? 'Clase disponible';
      horaClase = '10:00 AM'; // Esto debería venir de los horarios
    }

    // Calcular tareas pendientes
    final tareasPendientes = tareas.where((t) => !(t['has_submission'] ?? false)).length;
    String tareasTexto = tareasPendientes == 0 ? 'Sin tareas' : '$tareasPendientes pendientes';
    String tareasTime = tareasPendientes > 0 ? 'Revisar' : 'Al día';

    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Próxima Clase',
        'subtitle': proximaClase,
        'time': horaClase,
        'icon': Icons.schedule,
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Classes()),
          );
        },
      },
      {
        'title': 'Tareas Pendientes',
        'subtitle': tareasTexto,
        'time': tareasTime,
        'icon': Icons.assignment,
        'color': Colors.orange,
        'onTap': () {
          if (tareas.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(taskData: tareas.first),
              ),
            );
          }
        },
      },
      {
        'title': 'Calificaciones',
        'subtitle': 'Ver notas',
        'time': 'Actualizado',
        'icon': Icons.grade,
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Classes()),
          );
        },
      },
      {
        'title': 'Asistencia',
        'subtitle': '92% presente',
        'time': 'Este mes',
        'icon': Icons.check_circle,
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceHistory()),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: action['onTap'],
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            backgroundColor: action['color'].withOpacity(0.1),
                            radius: 20,
                            child: Icon(
                              action['icon'],
                              color: action['color'],
                              size: 20,
                            ),
                          ),
                          Text(
                            action['time'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action['subtitle'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}