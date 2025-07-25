class Usuario {
  final int id;
  final String nombreCompleto;
  final String cedula;
  final String correo;
  final String? telefono;
  final String rol; // estudiante, docente, admin

  Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.cedula,
    required this.correo,
    this.telefono,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        id: _parseId(json['id']),
        nombreCompleto: _parseString(json['nombre_completo'], 'Usuario'),
        cedula: _parseString(json['cedula'], ''),
        correo: _parseString(json['correo'], ''),
        telefono: _parseNullableString(json['telefono']),
        rol: _parseString(json['rol'], 'estudiante'),
      );
    } catch (e) {
      print('❌ FLUTTER: Error parseando usuario: $e');
      print('   JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'cedula': cedula,
      'correo': correo,
      'telefono': telefono,
      'rol': rol,
    };
  }

  // Métodos auxiliares para parsing seguro
  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      return value;
    }
    return value.toString();
  }

  String get primerNombre {
    try {
      return nombreCompleto.split(' ').first;
    } catch (e) {
      return nombreCompleto;
    }
  }

  bool get esEstudiante => rol == 'estudiante';
  bool get esDocente => rol == 'docente';
  bool get esAdmin => rol == 'admin';
}