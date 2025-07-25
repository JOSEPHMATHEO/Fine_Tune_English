import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _maxScoreController = TextEditingController();

  List<Map<String, dynamic>> _courseGroups = [];
  int? _selectedCourseGroupId;
  String _selectedTaskType = 'assignment';
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  bool _isLoading = false;

  final List<Map<String, String>> _taskTypes = [
    {'value': 'assignment', 'label': 'Tarea'},
    {'value': 'quiz', 'label': 'Quiz'},
    {'value': 'project', 'label': 'Proyecto'},
    {'value': 'reading', 'label': 'Lectura'},
    {'value': 'exercise', 'label': 'Ejercicio'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Baja'},
    {'value': 'medium', 'label': 'Media'},
    {'value': 'high', 'label': 'Alta'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCourseGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseGroups() async {
    try {
      final apiClient = sl<ApiClient>();
      final courseGroups = await apiClient.getTeacherCourseGroups();
      setState(() {
        _courseGroups = courseGroups;
        if (_courseGroups.isNotEmpty) {
          _selectedCourseGroupId = _courseGroups.first['id'];
        }
      });
    } catch (e) {
      print('Error cargando grupos de curso: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando grupos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de entrega'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedCourseGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un grupo de curso'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();

      // Preparar datos de la tarea
      final taskData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'task_type': _selectedTaskType,
        'course_group': _selectedCourseGroupId,
        'due_date': _dueDate!.toIso8601String(),
        'priority': _selectedPriority,
        'is_active': true,
      };

      // Agregar campos opcionales
      if (_instructionsController.text.trim().isNotEmpty) {
        taskData['instructions'] = _instructionsController.text.trim();
      }

      if (_maxScoreController.text.trim().isNotEmpty) {
        final maxScore = double.tryParse(_maxScoreController.text.trim());
        if (maxScore != null && maxScore > 0) {
          taskData['max_score'] = maxScore;
        }
      }

      print('📤 Enviando datos de tarea: $taskData');

      final result = await apiClient.createTask(taskData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      print('❌ Error creando tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        title: const Text('Crear Tarea'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTask,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Crear'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  hintText: 'Ej: Grammar Exercise - Present Perfect',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe la tarea que deben realizar los estudiantes',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instrucciones (opcional)',
                  hintText: 'Instrucciones detalladas para completar la tarea',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              if (_courseGroups.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedCourseGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Grupo de curso',
                  ),
                  items: _courseGroups.map((group) {
                    final courseName = group['course']?['name'] ?? 'Curso';
                    final groupName = group['name'] ?? 'Grupo';
                    return DropdownMenuItem<int>(
                      value: group['id'],
                      child: Text('$courseName - $groupName'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseGroupId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona un grupo';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedTaskType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de tarea',
                ),
                items: _taskTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTaskType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority['value'],
                    child: Text(priority['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _maxScoreController,
                decoration: const InputDecoration(
                  labelText: 'Puntuación máxima (opcional)',
                  hintText: 'Ej: 20',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final score = double.tryParse(value.trim());
                    if (score == null || score <= 0) {
                      return 'Ingresa un número válido mayor a 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                    );
                    if (time != null) {
                      setState(() {
                        _dueDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora de entrega',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                          : '',
                    ),
                    validator: (value) {
                      if (_dueDate == null) {
                        return 'Por favor selecciona una fecha de entrega';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_courseGroups.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'No tienes grupos de curso asignados',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contacta al administrador para que te asigne grupos de curso.',
                        style: TextStyle(color: Colors.orange[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}