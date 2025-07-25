import 'package:flutter/material.dart';
import '../tasks/TaskDetailScreen.dart';

class TasksList extends StatelessWidget {
  final List<Map<String, dynamic>> tareas;

  const TasksList({super.key, required this.tareas});

  @override
  Widget build(BuildContext context) {
    if (tareas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tareas Pendientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay tareas pendientes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                Text(
                  '¡Estás al día!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tareas Pendientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tareas.length > 5 ? 5 : tareas.length, // Mostrar máximo 5
          itemBuilder: (context, index) {
            final tarea = tareas[index];
            final isOverdue = tarea['is_overdue'] ?? false;
            final hasSubmission = tarea['has_submission'] ?? false;
            final status = tarea['status'] ?? 'pendiente';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status, isOverdue, hasSubmission),
                  child: Icon(
                    _getStatusIcon(status, hasSubmission),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  tarea['title'] ?? 'Tarea sin título',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tarea['course_group_data']?['course']?['name'] ?? 'Curso'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(status, tarea['days_remaining'], hasSubmission),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskData: tarea),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(taskData: tarea),
                    ),
                  );
                },
              ),
            );
          },
        ),
        if (tareas.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navegar a la lista completa de tareas
                },
                child: Text('Ver todas las tareas (${tareas.length})'),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status, bool isOverdue, bool hasSubmission) {
    if (hasSubmission) return Colors.green;
    if (isOverdue) return Colors.red;

    switch (status) {
      case 'urgente':
        return Colors.orange;
      case 'vence_hoy':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status, bool hasSubmission) {
    if (hasSubmission) return Icons.check_circle;

    switch (status) {
      case 'vencida':
        return Icons.warning;
      case 'urgente':
      case 'vence_hoy':
        return Icons.schedule;
      default:
        return Icons.assignment;
    }
  }

  String _getStatusText(String status, int? daysRemaining, bool hasSubmission) {
    if (hasSubmission) return 'Entregada';

    switch (status) {
      case 'vencida':
        return 'Vencida';
      case 'vence_hoy':
        return 'Vence hoy';
      case 'urgente':
        return 'Urgente - ${daysRemaining ?? 0} días';
      case 'pendiente':
        return 'Vence en ${daysRemaining ?? 0} días';
      default:
        return status;
    }
  }
}