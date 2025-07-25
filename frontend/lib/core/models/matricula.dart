import 'clase.dart';
import 'estudiante.dart';

class Matricula {
  final int id;
  final int estudianteId;
  final int claseId;
  final DateTime fechaInscripcion;
  final String usuarioInscribe;
  final String? motivoRetiro;
  final Clase? clase;
  final Estudiante? estudiante;

  Matricula({
    required this.id,
    required this.estudianteId,
    required this.claseId,
    required this.fechaInscripcion,
    required this.usuarioInscribe,
    this.motivoRetiro,
    this.clase,
    this.estudiante,
  });

  factory Matricula.fromJson(Map<String, dynamic> json) {
    return Matricula(
      id: json['id'],
      estudianteId: json['estudiante_id'],
      claseId: json['clase_id'],
      fechaInscripcion: DateTime.parse(json['fecha_inscripcion']),
      usuarioInscribe: json['usuario_inscribe'],
      motivoRetiro: json['motivo_retiro'],
      clase: json['clase'] != null ? Clase.fromJson(json['clase']) : null,
      estudiante: json['estudiante'] != null ? Estudiante.fromJson(json['estudiante']) : null,
    );
  }

  bool get estaActiva => motivoRetiro == null;
}