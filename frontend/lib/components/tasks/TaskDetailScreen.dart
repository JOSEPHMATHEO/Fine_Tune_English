
import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskDetailScreen({super.key, required this.taskData});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _submissionController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;
  Map<String, dynamic>? _taskDetail;

  @override
  void initState() {
    super.initState();
    _taskDetail = widget.taskData;
    _isSubmitted = widget.taskData['has_submission'] ?? false;

    if (_isSubmitted && widget.taskData['submission'] != null) {
      _submissionController.text = widget.taskData['submission']['submission_text'] ?? '';
    }
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (_submissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu respuesta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();
      final taskId = widget.taskData['id'];

      await apiClient.submitTask(taskId, _submissionController.text.trim());

      setState(() {
        _isSubmitted = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea entregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskData = _taskDetail ?? widget.taskData;
    final isOverdue = taskData['is_overdue'] ?? false;
    final dueDate = DateTime.tryParse(taskData['due_date'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle de Tarea',
          style: TextStyle(
            fontFamily: 'Coolvetica',
            fontSize: 22,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white, // Corregido
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskCard(context, taskData, isOverdue, dueDate),
            const SizedBox(height: 16),
            if (_isSubmitted) _buildDeliveredBanner(),
            const SizedBox(height: 16),
            _buildSubmissionForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> taskData, bool isOverdue, DateTime? dueDate) {
    final accent = Theme.of(context).colorScheme.secondary; // Alternativa moderna

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOverdue ? Colors.red : accent,
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskData['title'] ?? 'Tarea sin título',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        taskData['course_group_data']?['course']?['name'] ?? 'Curso',
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
            const SizedBox(height: 16),
            if (taskData['description'] != null) ...[
              const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(taskData['description']),
              const SizedBox(height: 16),
            ],
            if (taskData['instructions'] != null) ...[
              const Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(taskData['instructions']),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Fecha de entrega: ${dueDate != null ? _formatDate(dueDate) : 'No especificada'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (taskData['max_score'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.grade, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Puntuación máxima: ${taskData['max_score']} puntos',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red : accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(taskData),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredBanner() {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tarea entregada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSubmitted ? 'Tu respuesta:' : 'Entrega tu tarea:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _submissionController,
              decoration: const InputDecoration(
                hintText: 'Escribe tu respuesta aquí...',
              ),
              maxLines: 8,
              enabled: !_isSubmitted,
            ),
            const SizedBox(height: 16),
            if (!_isSubmitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  )
                      : const Text('Entregar Tarea'),
                  onPressed: _isLoading ? null : _submitTask,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  String _getStatusText(Map<String, dynamic> taskData) {
    final hasSubmission = taskData['has_submission'] ?? false;
    final isOverdue = taskData['is_overdue'] ?? false;
    final status = taskData['status'] ?? 'pendiente';
    final daysRemaining = taskData['days_remaining'] ?? 0;

    if (hasSubmission) return 'Entregada';
    if (isOverdue) return 'Vencida';

    switch (status) {
      case 'vence_hoy':
        return 'Vence hoy';
      case 'urgente':
        return 'Urgente - $daysRemaining días';
      case 'pendiente':
        return 'Vence en $daysRemaining días';
      default:
        return status;
    }
  }
}
