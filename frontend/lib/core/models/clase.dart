import 'usuario.dart';

class Clase {
  final int id;
  final int componenteId;
  final int docenteId;
  final String periodo;
  final String modalidad;
  final Map<String, dynamic> horario;
  final String horaInicio;
  final String horaFin;
  final Componente? componente;
  final Docente? docente;

  Clase({
    required this.id,
    required this.componenteId,
    required this.docenteId,
    required this.periodo,
    required this.modalidad,
    required this.horario,
    required this.horaInicio,
    required this.horaFin,
    this.componente,
    this.docente,
  });

  factory Clase.fromJson(Map<String, dynamic> json) {
    return Clase(
      id: json['id'],
      componenteId: json['componente_id'],
      docenteId: json['docente_id'],
      periodo: json['periodo'],
      modalidad: json['modalidad'],
      horario: json['horario'] ?? {},
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      componente: json['componente'] != null ? Componente.fromJson(json['componente']) : null,
      docente: json['docente'] != null ? Docente.fromJson(json['docente']) : null,
    );
  }

  String get duracion {
    final inicio = DateTime.parse('2024-01-01 $horaInicio');
    final fin = DateTime.parse('2024-01-01 $horaFin');
    final diferencia = fin.difference(inicio);
    return '${diferencia.inHours}h ${diferencia.inMinutes % 60}min';
  }
}

class Componente {
  final int id;
  final String nombre;
  final String nivel;

  Componente({
    required this.id,
    required this.nombre,
    required this.nivel,
  });

  factory Componente.fromJson(Map<String, dynamic> json) {
    return Componente(
      id: json['id'],
      nombre: json['nombre'],
      nivel: json['nivel'],
    );
  }
}

class Docente {
  final int id;
  final int usuarioId;
  final Usuario? usuario;

  Docente({
    required this.id,
    required this.usuarioId,
    this.usuario,
  });

  factory Docente.fromJson(Map<String, dynamic> json) {
    return Docente(
      id: json['id'],
      usuarioId: json['usuario_id'],
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }
}