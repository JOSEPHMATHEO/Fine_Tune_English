import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _courseGroups = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedCourseGroup;
  Map<String, String> _attendanceStatus = {};
  bool _isLoading = false;
  bool _isCreatingSession = false;
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadCourseGroups();
  }

  Future<void> _loadCourseGroups() async {
    try {
      setState(() => _isLoading = true);

      final apiClient = sl<ApiClient>();
      final courseGroups = await apiClient.getTeacherCourseGroups();

      setState(() {
        _courseGroups = courseGroups;
        if (_courseGroups.isNotEmpty) {
          _selectedCourseGroup = _courseGroups.first;
          _loadStudentsForGroup(_selectedCourseGroup!['id']);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando grupos de curso: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando grupos: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadStudentsForGroup(int groupId) async {
    try {
      // Simular carga de estudiantes del grupo
      // En una implementación real, esto vendría del backend
      _students = [
        {
          'id': 1,
          'name': 'Luis Morales',
          'email': 'luis.morales@student.com',
          'profile_id': 1,
        },
        {
          'id': 2,
          'name': 'María García',
          'email': 'maria.garcia@student.com',
          'profile_id': 2,
        },
        {
          'id': 3,
          'name': 'Carlos Rodríguez',
          'email': 'carlos.rodriguez@student.com',
          'profile_id': 3,
        },
        {
          'id': 4,
          'name': 'Ana López',
          'email': 'ana.lopez@student.com',
          'profile_id': 4,
        },
      ];

      // Inicializar estado de asistencia
      _attendanceStatus.clear();
      for (var student in _students) {
        _attendanceStatus[student['profile_id'].toString()] = 'present';
      }

      setState(() {});
    } catch (e) {
      print('Error cargando estudiantes: $e');
    }
  }

  Future<void> _createAttendanceSession() async {
    if (_selectedCourseGroup == null) return;

    setState(() => _isCreatingSession = true);

    try {
      final apiClient = sl<ApiClient>();
      final now = DateTime.now();

      final sessionData = {
        'course_group': _selectedCourseGroup!['id'],
        'date': now.toIso8601String().split('T')[0],
        'start_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'end_time': '${(now.hour + 2).toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'topic': 'Clase del día - ${_selectedCourseGroup!['course']['name']}',
        'notes': 'Sesión de asistencia creada desde la app móvil',
      };

      print('📊 Creando sesión de asistencia: $sessionData');

      final response = await apiClient.createAttendanceSession(sessionData);
      _currentSessionId = response['id'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sesión de asistencia creada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error creando sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingSession = false);
    }
  }

  Future<void> _submitAttendance() async {
    if (_currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Primero debes crear una sesión de asistencia'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final attendanceData = _students.map((student) {
        final status = _attendanceStatus[student['profile_id'].toString()] ?? 'present';
        return {
          'student_id': student['profile_id'],
          'status': status,
          'arrival_time': status == 'late' ? '10:15:00' : null,
          'notes': '',
        };
      }).toList();

      final requestData = {
        'session_id': _currentSessionId,
        'attendances': attendanceData,
      };

      print('📊 Enviando asistencia: $requestData');

      final apiClient = sl<ApiClient>();
      await apiClient.markAttendance(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Asistencia registrada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Limpiar sesión actual
        setState(() {
          _currentSessionId = null;
        });
      }
    } catch (e) {
      print('Error registrando asistencia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentSessionId != null)
            IconButton(
              onPressed: _isLoading ? null : _submitAttendance,
              icon: const Icon(Icons.save),
              tooltip: 'Guardar Asistencia',
            ),
        ],
      ),
      body: _isLoading && _courseGroups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Asistencia',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Selector de grupo
            _buildGroupSelector(),
            const SizedBox(height: 20),

            // Botón para crear sesión
            if (_currentSessionId == null) _buildCreateSessionButton(),

            // Lista de estudiantes
            if (_currentSessionId != null) ...[
              const SizedBox(height: 20),
              _buildSessionInfo(),
              const SizedBox(height: 20),
              Expanded(child: _buildStudentsList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Grupo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_courseGroups.isNotEmpty)
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedCourseGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo de curso',
                  prefixIcon: Icon(Icons.groups),
                ),
                items: _courseGroups.map((group) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: group,
                    child: Text('${group['course']['name']} - ${group['name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseGroup = value;
                    _currentSessionId = null; // Reset session
                  });
                  if (value != null) {
                    _loadStudentsForGroup(value['id']);
                  }
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No tienes grupos asignados. Contacta al administrador.',
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

  Widget _buildCreateSessionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCreatingSession || _selectedCourseGroup == null ? null : _createAttendanceSession,
        icon: _isCreatingSession
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.add_circle),
        label: const Text('Crear Sesión de Asistencia'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.successColor,
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesión Activa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_selectedCourseGroup!['course']['name']} - ${_selectedCourseGroup!['name']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lista de Estudiantes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '${_students.length} estudiantes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botones de acción rápida
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (var student in _students) {
                          _attendanceStatus[student['profile_id'].toString()] = 'present';
                        }
                      });
                    },
                    icon: Icon(Icons.check_circle, color: AppTheme.successColor),
                    label: const Text('Todos Presentes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: BorderSide(color: AppTheme.successColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (var student in _students) {
                          _attendanceStatus[student['profile_id'].toString()] = 'absent';
                        }
                      });
                    },
                    icon: Icon(Icons.cancel, color: AppTheme.errorColor),
                    label: const Text('Todos Ausentes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return _buildStudentAttendanceCard(student);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['profile_id'].toString();
    final currentStatus = _attendanceStatus[studentId] ?? 'present';
    final statusInfo = _getStatusInfo(currentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusInfo['color'].withOpacity(0.1),
              child: Text(
                student['name'].toString().split(' ').map((n) => n[0]).take(2).join(),
                style: TextStyle(
                  color: statusInfo['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    student['email'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: currentStatus,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: 'present',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 8),
                      const Text('Presente'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'absent',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, color: AppTheme.errorColor, size: 16),
                      const SizedBox(width: 8),
                      const Text('Ausente'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'late',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: AppTheme.warningColor, size: 16),
                      const SizedBox(width: 8),
                      const Text('Tardanza'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'excused',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note, color: AppTheme.infoColor, size: 16),
                      const SizedBox(width: 8),
                      const Text('Justificada'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _attendanceStatus[studentId] = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return {
          'color': AppTheme.successColor,
          'icon': Icons.check_circle,
          'text': 'Presente',
        };
      case 'absent':
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.cancel,
          'text': 'Ausente',
        };
      case 'late':
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.access_time,
          'text': 'Tardanza',
        };
      case 'excused':
        return {
          'color': AppTheme.infoColor,
          'icon': Icons.event_note,
          'text': 'Justificada',
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help,
          'text': 'Desconocido',
        };
    }
  }
}