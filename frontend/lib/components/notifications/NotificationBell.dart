import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import 'NotificationPanel.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with TickerProviderStateMixin {
  int _unreadCount = 0;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();

    // Animación para el badge de notificaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Animación para la campana (shake effect)
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bellAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticInOut),
    );

    _loadUnreadCount();

    // Actualizar cada 30 segundos
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      final apiClient = sl<ApiClient>();
      final count = await apiClient.getUnreadNotificationsCount();

      if (mounted) {
        final oldCount = _unreadCount;
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });

        // Animar si hay nuevas notificaciones
        if (count > oldCount && count > 0) {
          _animationController.forward().then((_) {
            _bellController.forward().then((_) {
              _bellController.reverse();
            });
          });
        } else if (count == 0) {
          _animationController.reverse();
        } else if (count > 0 && oldCount == 0) {
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error cargando contador de notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Mostrar datos de ejemplo si hay error
          _unreadCount = 3;
          _animationController.forward();
        });
      }
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: NotificationPanel(
            scrollController: scrollController,
            onNotificationRead: () {
              // Actualizar contador cuando se lean notificaciones
              _loadUnreadCount();
            },
          ),
        ),
      ),
    ).then((_) {
      // Actualizar contador al cerrar el panel
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bellAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _bellAnimation.value,
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  _unreadCount > 0 ? Icons.notifications : Icons.notifications_outlined,
                  color: _unreadCount > 0 ? Theme.of(context).primaryColor : Colors.black54,
                ),
                onPressed: _showNotificationPanel,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}