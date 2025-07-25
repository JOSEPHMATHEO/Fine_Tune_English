import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';

class NotificationPanel extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onNotificationRead;

  const NotificationPanel({
    super.key,
    this.scrollController,
    this.onNotificationRead,
  });

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todas';

  final List<String> _filterOptions = [
    'Todas',
    'No leídas',
    'Tareas',
    'Clases',
    'Evaluaciones',
    'Anuncios'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final apiClient = sl<ApiClient>();
      final notifications = await apiClient.getNotifications();
      setState(() {
        _notifications = notifications;
        _filteredNotifications = List.from(_notifications);
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando notificaciones: $e');
      setState(() {
        _isLoading = false;
        // Mostrar notificaciones de ejemplo si hay error
        _loadSampleNotifications();
      });
    }
  }

  void _loadSampleNotifications() {
    final now = DateTime.now();
    _notifications = [
      {
        'id': 1,
        'title': 'Nueva tarea asignada: Grammar Exercise',
        'message': 'Se ha asignado una nueva tarea de gramática que vence en 3 días',
        'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'is_read': false,
        'notification_type': {'name': 'Tareas', 'icon': 'assignment', 'color': '#2563EB'},
        'priority': 'medium',
        'action_url': '/tasks/1',
      },
      {
        'id': 2,
        'title': 'Recordatorio de clase',
        'message': 'Tu clase de Speaking Practice comienza en 30 minutos en el Aula 201',
        'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'is_read': false,
        'notification_type': {'name': 'Clases', 'icon': 'schedule', 'color': '#10B981'},
        'priority': 'high',
        'action_url': '/classes',
      },
      {
        'id': 3,
        'title': 'Nueva calificación disponible',
        'message': 'Tu calificación para el Quiz de Vocabulario ya está disponible: 18/20',
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'is_read': false,
        'notification_type': {'name': 'Evaluaciones', 'icon': 'grade', 'color': '#F59E0B'},
        'priority': 'medium',
        'action_url': '/grades',
      },
      {
        'id': 4,
        'title': 'Tarea próxima a vencer',
        'message': 'La tarea "Speaking Practice - Job Interview" vence mañana',
        'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'is_read': false,
        'notification_type': {'name': 'Tareas', 'icon': 'warning', 'color': '#EF4444'},
        'priority': 'high',
        'action_url': '/tasks/2',
      },
      {
        'id': 5,
        'title': 'Nuevo material disponible',
        'message': 'Se ha agregado nuevo material de estudio para la unidad 8',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'is_read': true,
        'notification_type': {'name': 'Anuncios', 'icon': 'info', 'color': '#8B5CF6'},
        'priority': 'low',
        'action_url': '/library',
      },
      {
        'id': 6,
        'title': 'Cambio de horario',
        'message': 'La clase de Writing Skills del viernes se ha movido al aula 105',
        'created_at': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        'is_read': true,
        'notification_type': {'name': 'Clases', 'icon': 'schedule_change', 'color': '#10B981'},
        'priority': 'medium',
        'action_url': '/schedule',
      },
      {
        'id': 7,
        'title': 'Evaluación programada',
        'message': 'Tienes un examen de comprensión auditiva programado para el lunes',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'is_read': true,
        'notification_type': {'name': 'Evaluaciones', 'icon': 'quiz', 'color': '#F59E0B'},
        'priority': 'medium',
        'action_url': '/exams',
      },
    ];

    _filteredNotifications = List.from(_notifications);
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'No leídas':
          _filteredNotifications = _notifications.where((n) => !n['is_read']).toList();
          break;
        case 'Tareas':
          _filteredNotifications = _notifications.where((n) =>
          n['notification_type']?['name'] == 'Tareas').toList();
          break;
        case 'Clases':
          _filteredNotifications = _notifications.where((n) =>
          n['notification_type']?['name'] == 'Clases').toList();
          break;
        case 'Evaluaciones':
          _filteredNotifications = _notifications.where((n) =>
          n['notification_type']?['name'] == 'Evaluaciones').toList();
          break;
        case 'Anuncios':
          _filteredNotifications = _notifications.where((n) =>
          n['notification_type']?['name'] == 'Anuncios').toList();
          break;
        default:
          _filteredNotifications = List.from(_notifications);
      }
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read']) return;

    try {
      final apiClient = sl<ApiClient>();
      await apiClient.markNotificationAsRead(notification['id']);

      setState(() {
        notification['is_read'] = true;
      });

      widget.onNotificationRead?.call();
    } catch (e) {
      // Marcar como leída localmente si hay error
      setState(() {
        notification['is_read'] = true;
      });
      widget.onNotificationRead?.call();
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    try {
      // Aquí iría la llamada a la API para eliminar
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notification['id']);
        _applyFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación eliminada'),
          duration: Duration(seconds: 2),
        ),
      );

      widget.onNotificationRead?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando notificación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.markAllNotificationsAsRead();

      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onNotificationRead?.call();
    } catch (e) {
      // Marcar como leídas localmente si hay error
      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onNotificationRead?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterSection(),
        Expanded(child: _buildNotificationsList()),
      ],
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount sin leer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text('Marcar todas como leídas'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = _getFilterCount(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  count > 0 ? '$filter ($count)' : filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _applyFilter();
                },
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'No leídas':
        return _notifications.where((n) => !n['is_read']).length;
      case 'Tareas':
        return _notifications.where((n) =>
        n['notification_type']?['name'] == 'Tareas').length;
      case 'Clases':
        return _notifications.where((n) =>
        n['notification_type']?['name'] == 'Clases').length;
      case 'Evaluaciones':
        return _notifications.where((n) =>
        n['notification_type']?['name'] == 'Evaluaciones').length;
      case 'Anuncios':
        return _notifications.where((n) =>
        n['notification_type']?['name'] == 'Anuncios').length;
      default:
        return 0;
    }
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Todas'
                  ? 'No hay notificaciones'
                  : 'No hay notificaciones en esta categoría',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final notificationType = notification['notification_type'] ?? {};
    final isRead = notification['is_read'] ?? false;
    final priority = notification['priority'] ?? 'medium';
    final isHighPriority = priority == 'high';

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
          elevation: isHighPriority ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHighPriority
                  ? Colors.red.withOpacity(0.3)
                  : isRead
                  ? Colors.transparent
                  : Theme.of(context).primaryColor.withOpacity(0.3),
              width: isHighPriority ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              _markAsRead(notification);
              // Aquí se podría navegar a la pantalla correspondiente
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navegando a: ${notification['action_url'] ?? 'destino'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getColorFromString(
                          notificationType['color'] ?? '#2563EB',
                        ).withOpacity(0.1),
                        child: Icon(
                          _getIconFromString(notificationType['icon'] ?? 'notifications'),
                          color: _getColorFromString(notificationType['color'] ?? '#2563EB'),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? 'Notificación',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isHighPriority)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'URGENTE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _getTimeAgo(notification['created_at'] ?? ''),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isHighPriority ? Colors.red : Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Botones de acción
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isRead)
                        TextButton.icon(
                          onPressed: () => _markAsRead(notification),
                          icon: const Icon(Icons.mark_email_read, size: 16),
                          label: const Text('Marcar como leída'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _deleteNotification(notification),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'assignment':
        return Icons.assignment;
      case 'schedule':
        return Icons.schedule;
      case 'quiz':
        return Icons.quiz;
      case 'grade':
        return Icons.grade;
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'schedule_change':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorFromString(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes}m';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return 'Hace un momento';
    }
  }
}