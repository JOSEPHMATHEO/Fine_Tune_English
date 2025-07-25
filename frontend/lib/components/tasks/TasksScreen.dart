import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import 'TaskDetailScreen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  List<String> _subjects = [];
  bool _isLoading = true;
  String? _selectedSubject;
  String _selectedStatus = 'Todas';
  String _sortBy = 'Fecha de entrega';
  late TabController _tabController;

  final List<String> _statusOptions = [
    'Todas',
    'Pendientes',
    'En curso',
    'Entregadas',
    'Vencidas'
  ];

  final List<String> _sortOptions = [
    'Fecha de entrega',
    'Fecha de creación',
    'Asignatura',
    'Prioridad'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);

      final apiClient = sl<ApiClient>();
      final tasks = await apiClient.getTareas();

      setState(() {
        _allTasks = tasks;
        _filteredTasks = List.from(_allTasks);
        _subjects = _extractSubjects(_allTasks);
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error cargando tareas: $e');
      setState(() {
        _isLoading = false;
        _loadSampleTasks();
      });
    }
  }

  void _loadSampleTasks() {
    final now = DateTime.now();
    _allTasks = [
      {
        'id': 1,
        'title': 'Grammar Exercise - Present Perfect',
        'description': 'Complete los ejercicios del capítulo 5 sobre Present Perfect. Incluye ejercicios de completar oraciones y traducción.',
        'course_group_data': {
          'course': {'name': 'Inglés Intermedio B1'},
          'name': 'Grupo A'
        },
        'due_date': now.add(const Duration(days: 3)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'task_type': 'assignment',
        'priority': 'medium',
        'max_score': 20.0,
        'has_submission': false,
        'is_overdue': false,
        'status': 'pendiente',
        'days_remaining': 3,
      },
      {
        'id': 2,
        'title': 'Speaking Practice - Job Interview',
        'description': 'Prepare una presentación de 5 minutos simulando una entrevista de trabajo en inglés.',
        'course_group_data': {
          'course': {'name': 'Inglés Intermedio B1'},
          'name': 'Grupo A'
        },
        'due_date': now.add(const Duration(days: 1)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'task_type': 'project',
        'priority': 'high',
        'max_score': 25.0,
        'has_submission': false,
        'is_overdue': false,
        'status': 'urgente',
        'days_remaining': 1,
      },
      {
        'id': 3,
        'title': 'Reading Comprehension Quiz',
        'description': 'Quiz sobre el texto "Technology in Education" - 10 preguntas de comprensión lectora.',
        'course_group_data': {
          'course': {'name': 'Inglés Avanzado C1'},
          'name': 'Grupo B'
        },
        'due_date': now.toIso8601String(),
        'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        'task_type': 'quiz',
        'priority': 'medium',
        'max_score': 15.0,
        'has_submission': false,
        'is_overdue': false,
        'status': 'vence_hoy',
        'days_remaining': 0,
      },
      {
        'id': 4,
        'title': 'Essay Writing - Environmental Issues',
        'description': 'Escribir un ensayo de 300 palabras sobre problemas ambientales actuales.',
        'course_group_data': {
          'course': {'name': 'Inglés Avanzado C1'},
          'name': 'Grupo B'
        },
        'due_date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
        'task_type': 'assignment',
        'priority': 'high',
        'max_score': 30.0,
        'has_submission': false,
        'is_overdue': true,
        'status': 'vencida',
        'days_remaining': -2,
      },
      {
        'id': 5,
        'title': 'Vocabulary Test - Unit 8',
        'description': 'Examen de vocabulario de la unidad 8. Incluye definiciones, sinónimos y uso en contexto.',
        'course_group_data': {
          'course': {'name': 'Inglés Básico A2'},
          'name': 'Grupo C'
        },
        'due_date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 12)).toIso8601String(),
        'task_type': 'quiz',
        'priority': 'medium',
        'max_score': 20.0,
        'has_submission': true,
        'is_overdue': false,
        'status': 'entregada',
        'days_remaining': -5,
        'submission': {
          'submitted_at': now.subtract(const Duration(days: 6)).toIso8601String(),
          'submission_text': 'Examen completado exitosamente.'
        }
      },
      {
        'id': 6,
        'title': 'Listening Exercise - News Report',
        'description': 'Escuchar el reporte de noticias y responder las preguntas de comprensión auditiva.',
        'course_group_data': {
          'course': {'name': 'Inglés Básico A2'},
          'name': 'Grupo C'
        },
        'due_date': now.add(const Duration(days: 7)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'task_type': 'exercise',
        'priority': 'low',
        'max_score': 15.0,
        'has_submission': false,
        'is_overdue': false,
        'status': 'pendiente',
        'days_remaining': 7,
      },
    ];

    _filteredTasks = List.from(_allTasks);
    _subjects = _extractSubjects(_allTasks);
  }

  List<String> _extractSubjects(List<Map<String, dynamic>> tasks) {
    final subjects = tasks
        .map((task) => task['course_group_data']?['course']?['name'] as String? ?? 'Sin curso')
        .toSet()
        .toList();
    subjects.sort();
    return ['Todas las materias', ...subjects];
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        // Filtro por materia
        bool matchesSubject = _selectedSubject == null ||
            _selectedSubject == 'Todas las materias' ||
            task['course_group_data']?['course']?['name'] == _selectedSubject;

        // Filtro por estado
        bool matchesStatus = _selectedStatus == 'Todas' || _getTaskStatus(task) == _selectedStatus;

        return matchesSubject && matchesStatus;
      }).toList();

      // Aplicar ordenamiento
      _sortTasks();
    });
  }

  void _sortTasks() {
    _filteredTasks.sort((a, b) {
      switch (_sortBy) {
        case 'Fecha de entrega':
          final dateA = DateTime.tryParse(a['due_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['due_date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        case 'Fecha de creación':
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        case 'Asignatura':
          final subjectA = a['course_group_data']?['course']?['name'] ?? '';
          final subjectB = b['course_group_data']?['course']?['name'] ?? '';
          return subjectA.compareTo(subjectB);
        case 'Prioridad':
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          final priorityA = priorityOrder[a['priority']] ?? 3;
          final priorityB = priorityOrder[b['priority']] ?? 3;
          return priorityA.compareTo(priorityB);
        default:
          return 0;
      }
    });
  }

  String _getTaskStatus(Map<String, dynamic> task) {
    if (task['has_submission'] == true) return 'Entregadas';
    if (task['is_overdue'] == true) return 'Vencidas';

    final status = task['status'] ?? 'pendiente';
    switch (status) {
      case 'vence_hoy':
      case 'urgente':
        return 'En curso';
      case 'pendiente':
        return 'Pendientes';
      case 'entregada':
        return 'Entregadas';
      case 'vencida':
        return 'Vencidas';
      default:
        return 'Pendientes';
    }
  }

  Future<void> _markTaskAsCompleted(Map<String, dynamic> task) async {
    try {
      // Aquí iría la lógica para marcar como completada
      setState(() {
        task['has_submission'] = true;
        task['status'] = 'entregada';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea marcada como completada'),
          backgroundColor: Colors.green,
        ),
      );

      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Mis Tareas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Todas (${_allTasks.length})'),
            Tab(text: 'Pendientes (${_allTasks.where((t) => !t['has_submission'] && !t['is_overdue']).length})'),
            Tab(text: 'Urgentes (${_allTasks.where((t) => t['status'] == 'urgente' || t['status'] == 'vence_hoy').length})'),
            Tab(text: 'Entregadas (${_allTasks.where((t) => t['has_submission']).length})'),
          ],
          isScrollable: true,
        ),
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksList(_filteredTasks),
                _buildTasksList(_filteredTasks.where((t) => !t['has_submission'] && !t['is_overdue']).toList()),
                _buildTasksList(_filteredTasks.where((t) => t['status'] == 'urgente' || t['status'] == 'vence_hoy').toList()),
                _buildTasksList(_filteredTasks.where((t) => t['has_submission']).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Materia',
                    prefixIcon: Icon(Icons.book),
                    isDense: true,
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject, style: const TextStyle(fontSize: 14)),
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
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.filter_list),
                    isDense: true,
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    prefixIcon: Icon(Icons.sort),
                    isDense: true,
                  ),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                    _selectedStatus = 'Todas';
                    _sortBy = 'Fecha de entrega';
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tareas en esta categoría',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isOverdue = task['is_overdue'] ?? false;
    final hasSubmission = task['has_submission'] ?? false;
    final status = task['status'] ?? 'pendiente';
    final daysRemaining = task['days_remaining'] ?? 0;
    final dueDate = DateTime.tryParse(task['due_date'] ?? '');
    final priority = task['priority'] ?? 'medium';

    // Determinar color y urgencia
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    bool isUrgent = false;

    if (hasSubmission) {
      borderColor = Colors.green;
      cardColor = Colors.green[50]!;
    } else if (isOverdue) {
      borderColor = Colors.red;
      cardColor = Colors.red[50]!;
      isUrgent = true;
    } else if (status == 'vence_hoy' || daysRemaining <= 1) {
      borderColor = Colors.orange;
      cardColor = Colors.orange[50]!;
      isUrgent = true;
    } else if (status == 'urgente' || priority == 'high') {
      borderColor = Colors.amber;
      cardColor = Colors.amber[50]!;
      isUrgent = true;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: cardColor,
        elevation: isUrgent ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(taskData: task),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] ?? 'Tarea sin título',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasSubmission ? Colors.green[700] : Colors.black87,
                              decoration: hasSubmission ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['course_group_data']?['course']?['name'] ?? 'Curso',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _buildStatusChip(status, isOverdue, hasSubmission),
                        if (priority == 'high' && !hasSubmission) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ALTA PRIORIDAD',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Descripción
                if (task['description'] != null) ...[
                  Text(
                    task['description'],
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Información de fecha y puntuación
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${dueDate != null ? _formatDate(dueDate) : 'No especificada'}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (task['max_score'] != null) ...[
                      Icon(Icons.grade, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${task['max_score']} pts',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Tiempo restante
                _buildTimeRemaining(daysRemaining, isOverdue, hasSubmission),

                // Botones de acción
                if (!hasSubmission) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _markTaskAsCompleted(task),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Marcar como completada'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(taskData: task),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Entregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isOverdue, bool hasSubmission) {
    String text;
    Color color;
    IconData icon;

    if (hasSubmission) {
      text = 'Entregada';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (isOverdue) {
      text = 'Vencida';
      color = Colors.red;
      icon = Icons.warning;
    } else {
      switch (status) {
        case 'vence_hoy':
          text = 'Vence hoy';
          color = Colors.orange;
          icon = Icons.today;
          break;
        case 'urgente':
          text = 'Urgente';
          color = Colors.red;
          icon = Icons.priority_high;
          break;
        case 'pendiente':
          text = 'Pendiente';
          color = Colors.blue;
          icon = Icons.schedule;
          break;
        default:
          text = status;
          color = Colors.grey;
          icon = Icons.help;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining(int daysRemaining, bool isOverdue, bool hasSubmission) {
    if (hasSubmission) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 14),
            const SizedBox(width: 4),
            Text(
              'Tarea completada',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    String text;
    Color color;
    IconData icon;

    if (isOverdue) {
      text = 'Vencida hace ${(-daysRemaining)} día${(-daysRemaining) != 1 ? 's' : ''}';
      color = Colors.red;
      icon = Icons.warning;
    } else if (daysRemaining == 0) {
      text = 'Vence hoy';
      color = Colors.orange;
      icon = Icons.today;
    } else if (daysRemaining == 1) {
      text = 'Vence mañana';
      color = Colors.orange;
      icon = Icons.schedule;
    } else if (daysRemaining <= 3) {
      text = 'Vence en $daysRemaining días';
      color = Colors.amber;
      icon = Icons.schedule;
    } else {
      text = 'Vence en $daysRemaining días';
      color = Colors.blue;
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}