import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import 'CreateTaskScreen.dart';
import 'AttendanceScreen.dart';
import 'TeacherTasksScreen.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({super.key});

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel Docente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildTeacherCard(
                    'Crear Tarea',
                    'Asignar nuevas tareas a estudiantes',
                    Icons.assignment_add,
                    Colors.blue,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTaskScreen(),
                        ),
                      );
                    },
                  ),
                  _buildTeacherCard(
                    'Mis Tareas',
                    'Ver tareas creadas y entregas',
                    Icons.assignment,
                    Colors.purple,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherTasksScreen(),
                        ),
                      );
                    },
                  ),
                  _buildTeacherCard(
                    'Control de Asistencia',
                    'Marcar asistencia de estudiantes',
                    Icons.how_to_reg,
                    Colors.green,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildTeacherCard(
                    'Mis Grupos',
                    'Ver grupos de curso asignados',
                    Icons.groups,
                    Colors.orange,
                        () {
                      // TODO: Implementar vista de grupos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                  _buildTeacherCard(
                    'Calificaciones',
                    'Gestionar calificaciones',
                    Icons.grade,
                    Colors.indigo,
                        () {
                      // TODO: Implementar gestión de calificaciones
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                  _buildTeacherCard(
                    'Reportes',
                    'Generar reportes académicos',
                    Icons.analytics,
                    Colors.teal,
                        () {
                      // TODO: Implementar reportes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}