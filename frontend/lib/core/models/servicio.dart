class Servicio {
  final int id;
  final String nombre;
  final String descripcion;
  final String? enlace;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.enlace,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      enlace: json['enlace'],
    );
  }

  bool get tieneEnlace => enlace != null && enlace!.isNotEmpty;
}