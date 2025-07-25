import 'usuario.dart';

class Estudiante {
  final int id;
  final int usuarioId;
  final String nivelEstudio;
  final DateTime fechaNacimiento;
  final String genero;
  final String estadoCivil;
  final String parroquia;
  final String origenIngresos;
  final Usuario? usuario;

  Estudiante({
    required this.id,
    required this.usuarioId,
    required this.nivelEstudio,
    required this.fechaNacimiento,
    required this.genero,
    required this.estadoCivil,
    required this.parroquia,
    required this.origenIngresos,
    this.usuario,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'],
      usuarioId: json['usuario_id'],
      nivelEstudio: json['nivel_estudio'],
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      genero: json['genero'],
      estadoCivil: json['estado_civil'],
      parroquia: json['parroquia'],
      origenIngresos: json['origen_ingresos'],
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nivel_estudio': nivelEstudio,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'genero': genero,
      'estado_civil': estadoCivil,
      'parroquia': parroquia,
      'origen_ingresos': origenIngresos,
    };
  }

  int get edad {
    final now = DateTime.now();
    int age = now.year - fechaNacimiento.year;
    if (now.month < fechaNacimiento.month ||
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      age--;
    }
    return age;
  }
}