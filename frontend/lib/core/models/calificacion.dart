import 'clase.dart';

class Calificacion {
  final int id;
  final int estudianteId;
  final int claseId;
  final double notaFinal;
  final int inasistencias;
  final Clase? clase;

  Calificacion({
    required this.id,
    required this.estudianteId,
    required this.claseId,
    required this.notaFinal,
    required this.inasistencias,
    this.clase,
  });

  factory Calificacion.fromJson(Map<String, dynamic> json) {
    return Calificacion(
      id: json['id'],
      estudianteId: json['estudiante_id'],
      claseId: json['clase_id'],
      notaFinal: double.parse(json['nota_final'].toString()),
      inasistencias: json['inasistencias'],
      clase: json['clase'] != null ? Clase.fromJson(json['clase']) : null,
    );
  }

  String get estado {
    if (notaFinal >= 7.0) return 'Aprobado';
    if (notaFinal >= 5.0) return 'Recuperación';
    return 'Reprobado';
  }

  String get letra {
    if (notaFinal >= 9.0) return 'A';
    if (notaFinal >= 8.0) return 'B';
    if (notaFinal >= 7.0) return 'C';
    if (notaFinal >= 6.0) return 'D';
    return 'F';
  }
}