import 'clase.dart';

class Asistencia {
  final int id;
  final int estudianteId;
  final int claseId;
  final DateTime fecha;
  final bool presente;
  final Clase? clase;

  Asistencia({
    required this.id,
    required this.estudianteId,
    required this.claseId,
    required this.fecha,
    required this.presente,
    this.clase,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      estudianteId: json['estudiante_id'],
      claseId: json['clase_id'],
      fecha: DateTime.parse(json['fecha']),
      presente: json['presente'],
      clase: json['clase'] != null ? Clase.fromJson(json['clase']) : null,
    );
  }

  String get estadoTexto => presente ? 'Presente' : 'Ausente';
}