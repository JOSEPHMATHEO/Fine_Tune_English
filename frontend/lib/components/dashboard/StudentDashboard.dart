import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/models/noticia.dart';
import '../../core/models/matricula.dart';
import 'WelcomeCard.dart';
import 'NewsCarousel.dart';
import 'TasksList.dart';
import 'QuickActions.dart';
import 'AttendanceWidget.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<Noticia> noticias = [];
  List<Map<String, dynamic>> tareas = [];
  List<Matricula> matriculas = [];
  Map<String, dynamic> attendanceData = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('🔄 Iniciando carga de datos del dashboard estudiante...');
      setState(() {
        isLoading = true;
        error = null;
      });

      final apiClient = sl<ApiClient>();

      // Cargar datos en paralelo
      final results = await Future.wait([
        apiClient.getNoticias().catchError((e) {
          print('❌ Error cargando noticias: $e');
          return <Noticia>[];
        }),
        apiClient.getTareas().catchError((e) {
          print('❌ Error cargando tareas: $e');
          return <Map<String, dynamic>>[];
        }),
        apiClient.getMatriculas().catchError((e) {
          print('❌ Error cargando matrículas: $e');
          return <Matricula>[];
        }),
        apiClient.getAttendanceSummary().catchError((e) {
          print('❌ Error cargando asistencia: $e');
          return <String, dynamic>{};
        }),
      ]);

      setState(() {
        noticias = results[0] as List<Noticia>;
        tareas = results[1] as List<Map<String, dynamic>>;
        matriculas = results[2] as List<Matricula>;
        attendanceData = results[3] as Map<String, dynamic>;
        isLoading = false;
      });

      print('✅ Dashboard estudiante cargado exitosamente');

    } catch (e) {
      print('❌ Error cargando dashboard estudiante: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error cargando datos', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('No se pudieron cargar los datos. Verifica tu conexión.',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshData, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeCard(),
            const SizedBox(height: 20),
            QuickActions(matriculas: matriculas, tareas: tareas),
            const SizedBox(height: 20),
            AttendanceWidget(attendanceData: attendanceData),
            const SizedBox(height: 20),
            NewsCarousel(noticias: noticias),
            const SizedBox(height: 20),
            TasksList(tareas: tareas),
          ],
        ),
      ),
    );
  }
}