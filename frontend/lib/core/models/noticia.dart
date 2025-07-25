import 'package:flutter/material.dart';
import 'usuario.dart';

class Noticia {
  final int id;
  final String titulo;
  final String resumen;
  final String contenido;
  final String? imagenUrl;
  final DateTime fechaPublicacion;
  final int creadoPor;
  final Usuario? autor;
  final bool estaDestacada;
  final int vistas;
  final Map<String, dynamic>? categoria;
  final bool estaPublicada;

  Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    this.imagenUrl,
    required this.fechaPublicacion,
    required this.creadoPor,
    this.autor,
    required this.estaDestacada,
    required this.vistas,
    this.categoria,
    required this.estaPublicada,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 FLUTTER: Parseando noticia: ${json['title']}');
      print('   - ID: ${json['id']}');
      print('   - Publicada: ${json['is_published']}');
      print('   - Destacada: ${json['is_featured']}');
      print('   - Imagen URL: ${json['image_url']}');
      print('   - Autor: ${json['author']}');

      return Noticia(
        id: _parseId(json['id']),
        titulo: _parseString(json['title'], 'Sin título'),
        resumen: _parseString(json['summary'], ''),
        contenido: _parseString(json['content'], ''),
        imagenUrl: _parseImageUrl(json['image_url']),
        fechaPublicacion: _parseDateTime(json['publication_date']),
        creadoPor: _parseId(json['author']?['id']),
        autor: _parseAuthor(json['author']),
        estaDestacada: _parseBool(json['is_featured']),
        vistas: _parseId(json['views_count']),
        categoria: _parseCategory(json['category']),
        estaPublicada: _parseBool(json['is_published'], defaultValue: true),
      );
    } catch (e, stackTrace) {
      print('❌ FLUTTER: Error parseando noticia: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Métodos auxiliares para parsing seguro con manejo de null
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

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    if (value is double) return value == 1.0;
    return defaultValue;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      if (value.isEmpty) return DateTime.now();
      final parsed = DateTime.tryParse(value);
      return parsed ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String? _parseImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      // Si ya es una URL completa, devolverla tal como está
      if (value.startsWith('http')) return value;
      // Si es una ruta relativa, construir URL completa
      return 'http://127.0.0.1:8000$value';
    }
    return null;
  }

  static Usuario? _parseAuthor(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Map<String, dynamic>) {
        return Usuario.fromJson(value);
      }
      return null;
    } catch (e) {
      print('❌ FLUTTER: Error parseando autor: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _parseCategory(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  String get fechaFormateada {
    try {
      final meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${fechaPublicacion.day} de ${meses[fechaPublicacion.month - 1]} ${fechaPublicacion.year}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  String get categoriaTexto {
    try {
      return categoria?['name']?.toString() ?? 'General';
    } catch (e) {
      return 'General';
    }
  }

  Color get categoriaColor {
    try {
      final colorHex = categoria?['color']?.toString() ?? '#3B82F6';
      if (colorHex.isEmpty) return const Color(0xFF3B82F6);
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }
}