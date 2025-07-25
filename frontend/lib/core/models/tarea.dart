import 'clase.dart';

class Tarea {
  final int id;
  final int claseId;
  final String descripcion;
  final DateTime fechaEntrega;
  final Clase? clase;

  Tarea({
    required this.id,
    required this.claseId,
    required this.descripcion,
    required this.fechaEntrega,
    this.clase,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'],
      claseId: json['clase_id'],
      descripcion: json['descripcion'],
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      clase: json['clase'] != null ? Clase.fromJson(json['clase']) : null,
    );
  }

  bool get estaVencida => DateTime.now().isAfter(fechaEntrega);

  int get diasRestantes {
    final diferencia = fechaEntrega.difference(DateTime.now());
    return diferencia.inDays;
  }

  String get estadoTexto {
    if (estaVencida) return 'Vencida';
    if (diasRestantes == 0) return 'Vence hoy';
    if (diasRestantes == 1) return 'Vence mañana';
    return 'Vence en $diasRestantes días';
  }
}