import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/noticia.dart';
import '../models/matricula.dart';
import '../models/calificacion.dart';
import '../models/asistencia.dart';
import '../models/servicio.dart';

class ApiClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: AppConfig.defaultHeaders,
    ));

    _dio.interceptors.add(AuthInterceptor(_prefs));

    // Interceptor de logging para debug
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Reducir logs
      responseBody: false, // Reducir logs
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (object) => print('🌐 API: $object'),
    ));
  }

  Dio get dio => _dio;

  // Método para probar la conexión
  Future<bool> testConnection() async {
    try {
      print('🔗 Probando conexión con el backend...');
      final response = await _dio.get('/auth/test/', options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      print('✅ Conexión exitosa con el backend');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error de conexión con el backend: $e');
      return false;
    }
  }

  // Métodos de autenticación
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      print('📤 Enviando registro...');
      final response = await _dio.post('/auth/register/', data: data);
      print('✅ Registro exitoso');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('❌ Error en registro: ${e.message}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor Django esté ejecutándose en http://127.0.0.1:8000');
      } else if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
        throw Exception('Error del servidor: ${errorData.toString()}');
      } else {
        throw Exception('Error de red: ${e.message}');
      }
    } catch (e) {
      print('❌ Error inesperado en registro: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> login(String correo, String password) async {
    try {
      print('📤 Enviando login para: $correo');
      final response = await _dio.post('/auth/login/', data: {
        'correo': correo,
        'password': password,
      });
      print('✅ Login exitoso');

      // Guardar token y datos del usuario
      final responseData = _safeParseResponse(response.data);
      await _prefs.setString(AppConfig.accessTokenKey, responseData['access_token']);
      await _prefs.setString(AppConfig.refreshTokenKey, responseData['refresh_token']);

      return responseData;
    } on DioException catch (e) {
      print('❌ Error en login: ${e.message}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor Django esté ejecutándose en http://127.0.0.1:8000');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('non_field_errors')) {
          throw Exception(errorData['non_field_errors'][0]);
        }
        throw Exception('Credenciales incorrectas');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Usuario no autorizado');
      } else if (e.response != null) {
        throw Exception('Error del servidor: ${e.response?.data}');
      } else {
        throw Exception('Error de red: ${e.message}');
      }
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = _prefs.getString(AppConfig.refreshTokenKey);
      await _dio.post('/auth/logout/', data: {
        'refresh_token': refreshToken,
      });
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  // Métodos de recuperación de contraseña
  Future<Map<String, dynamic>> requestPasswordReset(String correo) async {
    try {
      final response = await _dio.post('/auth/password-reset/request/', data: {
        'correo': correo,
      });
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error solicitando recuperación: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> verifyResetToken(String token) async {
    try {
      final response = await _dio.get('/auth/password-reset/verify/', queryParameters: {
        'token': token,
      });
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error verificando token: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset(String token, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post('/auth/password-reset/confirm/', data: {
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error confirmando cambio de contraseña: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para obtener datos del usuario
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo perfil: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/auth/profile/update/', data: data);
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error actualizando perfil: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para noticias - VERSIÓN ULTRA ROBUSTA
  Future<List<Noticia>> getNoticias() async {
    try {
      print('📰 FLUTTER: Solicitando TODAS las noticias al backend...');

      // Probar conexión primero
      final isConnected = await testConnection();
      if (!isConnected) {
        print('❌ FLUTTER: No hay conexión con el backend');
        throw Exception('No se puede conectar con el servidor Django');
      }

      print('✅ FLUTTER: Conexión con backend establecida');

      final response = await _dio.get('/news/');
      print('✅ FLUTTER: Respuesta recibida del backend - Status: ${response.statusCode}');

      // Validar respuesta
      if (response.data == null) {
        print('⚠️ FLUTTER: Respuesta nula del backend');
        return [];
      }

      // Manejar tanto respuesta directa como paginada
      List<dynamic> data;
      if (response.data is Map && response.data.containsKey('results')) {
        data = response.data['results'] ?? [];
        print('📊 FLUTTER: Respuesta paginada - Total: ${response.data['count']}');
      } else if (response.data is List) {
        data = response.data;
        print('📊 FLUTTER: Respuesta directa como lista');
      } else {
        print('❌ FLUTTER: Formato de respuesta inesperado: ${response.data.runtimeType}');
        return [];
      }

      print('📊 FLUTTER: Cantidad de noticias recibidas del backend: ${data.length}');

      if (data.isEmpty) {
        print('⚠️ FLUTTER: El backend devolvió una lista vacía');
        return [];
      }

      final noticias = <Noticia>[];

      for (int i = 0; i < data.length; i++) {
        try {
          final noticiaJson = data[i];
          if (noticiaJson is Map<String, dynamic>) {
            print('🔍 FLUTTER: Procesando noticia ${i + 1}: ${noticiaJson['title']}');

            // Validar datos críticos antes del parsing
            if (_isValidNewsData(noticiaJson)) {
              final noticia = Noticia.fromJson(noticiaJson);
              noticias.add(noticia);
              print('✅ FLUTTER: Noticia ${i + 1} parseada exitosamente');
            } else {
              print('⚠️ FLUTTER: Noticia ${i + 1} tiene datos inválidos, saltando...');
            }
          } else {
            print('❌ FLUTTER: Noticia ${i + 1} no es un Map válido: $noticiaJson');
          }
        } catch (e, stackTrace) {
          print('❌ FLUTTER: Error parseando noticia ${i + 1}: $e');
          print('   JSON: ${data[i]}');
          print('   StackTrace: $stackTrace');
          // Continuar con las demás noticias
        }
      }

      print('✅ FLUTTER: Total de noticias parseadas correctamente: ${noticias.length}');
      for (int i = 0; i < noticias.length; i++) {
        final n = noticias[i];
        print('   📰 FLUTTER ${i + 1}. "${n.titulo}" (ID: ${n.id}) - Destacada: ${n.estaDestacada}');
      }

      if (noticias.isEmpty) {
        print('⚠️ FLUTTER: No se pudieron parsear noticias del backend');
      }

      return noticias;
    } on DioException catch (e) {
      print('❌ FLUTTER: Error DioException obteniendo noticias: ${e.response?.data}');
      print('❌ FLUTTER: Tipo de error: ${e.type}');
      print('❌ FLUTTER: Mensaje: ${e.message}');
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor Django esté ejecutándose');
      }
      throw Exception('Error obteniendo noticias: ${e.response?.data ?? e.message}');
    } catch (e, stackTrace) {
      print('❌ FLUTTER: Error inesperado obteniendo noticias: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error inesperado: $e');
    }
  }

  // Validar datos de noticia antes del parsing
  bool _isValidNewsData(Map<String, dynamic> data) {
    try {
      // Verificar campos críticos
      if (data['id'] == null) return false;
      if (data['title'] == null || (data['title'] is String && data['title'].isEmpty)) return false;
      if (data['is_published'] == null) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  // Método auxiliar para parsing seguro de respuestas
  Map<String, dynamic> _safeParseResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> getNewsCategories() async {
    try {
      print('📂 Solicitando categorías de noticias...');
      final response = await _dio.get('/news/categories/');
      if (response.data is List) {
        print('✅ Categorías obtenidas: ${response.data.length}');
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo categorías: ${e.response?.data}');
      throw Exception('Error obteniendo categorías: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> createNews(Map<String, dynamic> data) async {
    try {
      print('📰 Frontend: Creando noticia: $data');

      // Preparar datos con tipos correctos
      final processedData = Map<String, dynamic>.from(data);

      // Convertir booleanos a strings para FormData
      if (processedData.containsKey('is_featured')) {
        processedData['is_featured'] = processedData['is_featured'].toString();
      }
      if (processedData.containsKey('is_published')) {
        processedData['is_published'] = processedData['is_published'].toString();
      }

      dynamic requestData = processedData;

      if (data.containsKey('image_bytes') && data['image_bytes'] != null) {
        final formData = FormData.fromMap({
          ...processedData,
          'image': MultipartFile.fromBytes(
            data['image_bytes'],
            filename: data['image_name'] ?? 'image.jpg',
          ),
        });
        // Remover los bytes del mapa ya que están en el FormData
        formData.fields.removeWhere((field) => field.key == 'image_bytes' || field.key == 'image_name');
        requestData = formData;
      }

      final response = await _dio.post('/news/create/', data: requestData);
      print('✅ Frontend: Noticia creada exitosamente: ${response.data}');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('❌ Frontend: Error creando noticia: ${e.response?.data}');
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      }
      throw Exception('Error creando noticia: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para tareas
  Future<List<Map<String, dynamic>>> getTareas() async {
    try {
      print('📤 FLUTTER: Solicitando tareas del estudiante...');

      // Verificar información del usuario primero
      await _debugUserInfo();

      final response = await _dio.get('/tasks/');
      print('✅ FLUTTER: Respuesta de tareas recibida - Status: ${response.statusCode}');

      if (response.data is List) {
        final tasks = List<Map<String, dynamic>>.from(response.data);
        print('✅ FLUTTER: ${tasks.length} tareas parseadas correctamente');
        return tasks;
      } else if (response.data is Map && response.data.containsKey('message')) {
        print('ℹ️ FLUTTER: ${response.data['message']}');
        return [];
      }

      print('⚠️ FLUTTER: Formato de respuesta inesperado para tareas');
      return [];
    } on DioException catch (e) {
      print('❌ FLUTTER: Error obteniendo tareas: ${e.response?.data}');
      print('❌ FLUTTER: Status code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acceso denegado: ${e.response?.data?['error'] ?? 'Sin permisos'}');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      }
      throw Exception('Error obteniendo tareas: ${e.response?.data ?? e.message}');
    }
  }

  // Método de debug para verificar información del usuario
  Future<void> _debugUserInfo() async {
    try {
      print('🔍 FLUTTER: Verificando información del usuario...');
      final response = await _dio.get('/auth/debug/');
      final userInfo = _safeParseResponse(response.data);

      print('👤 FLUTTER: Info del usuario:');
      print('   - Correo: ${userInfo['correo']}');
      print('   - Rol: ${userInfo['rol']}');
      print('   - Activo: ${userInfo['is_active']}');
      print('   - Tiene perfil estudiante: ${userInfo['has_student_profile']}');
      print('   - Tiene perfil docente: ${userInfo['has_teacher_profile']}');
      print('   - Matrículas: ${userInfo['enrollments_count'] ?? 0}');

      if (userInfo['enrollments'] != null) {
        final enrollments = userInfo['enrollments'] as List;
        for (int i = 0; i < enrollments.length; i++) {
          final e = enrollments[i];
          print('     ${i + 1}. ${e['course_name']} - ${e['group_name']}');
        }
      }
    } catch (e) {
      print('⚠️ FLUTTER: No se pudo obtener info de debug: $e');
    }
  }

  Future<Map<String, dynamic>> getTaskDetail(int taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Error obteniendo detalle de tarea: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> submitTask(int taskId, String submissionText) async {
    try {
      final response = await _dio.post('/tasks/$taskId/submit/', data: {
        'submission_text': submissionText,
      });
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Error entregando tarea: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    try {
      print('📤 Enviando datos de tarea: $data');

      // Validar datos antes de enviar
      if (data['course_group'] == null) {
        throw Exception('course_group es requerido');
      }

      final response = await _dio.post('/tasks/create/', data: data);
      print('✅ Tarea creada exitosamente: ${response.data}');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('❌ Error creando tarea: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('details')) {
          throw Exception('Datos inválidos: ${errorData['details']}');
        }
      }

      throw Exception('Error creando tarea: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherCourseGroups() async {
    try {
      final response = await _dio.get('/tasks/teacher/course-groups/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error obteniendo grupos: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherTasks() async {
    try {
      final response = await _dio.get('/tasks/teacher/tasks/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error obteniendo tareas del docente: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para cursos
  Future<List<Matricula>> getMatriculas() async {
    try {
      print('📚 FLUTTER: Solicitando matrículas del estudiante...');

      // Verificar información del usuario primero
      await _debugUserInfo();

      final response = await _dio.get('/courses/enrollments/');
      print('✅ FLUTTER: Respuesta de matrículas recibida - Status: ${response.statusCode}');

      if (response.data is List) {
        final List<dynamic> data = response.data;
        final matriculas = data.map((json) => Matricula.fromJson(json)).toList();
        print('✅ FLUTTER: ${matriculas.length} matrículas parseadas correctamente');
        return matriculas;
      } else if (response.data is Map && response.data.containsKey('message')) {
        print('ℹ️ FLUTTER: ${response.data['message']}');
        return [];
      }

      print('⚠️ FLUTTER: Formato de respuesta inesperado para matrículas');
      return [];
    } on DioException catch (e) {
      print('❌ FLUTTER: Error obteniendo matrículas: ${e.response?.data}');
      print('❌ FLUTTER: Status code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acceso denegado: ${e.response?.data?['error'] ?? 'Sin permisos'}');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      }
      throw Exception('Error obteniendo matrículas: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> getCourseDetail(int enrollmentId) async {
    try {
      final response = await _dio.get('/courses/enrollments/$enrollmentId/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Error obteniendo detalle del curso: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Calificacion>> getCalificaciones(int enrollmentId) async {
    try {
      final response = await _dio.get('/courses/enrollments/$enrollmentId/grades/');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Calificacion.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error obteniendo calificaciones: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para asistencia
  Future<List<Asistencia>> getAsistencias() async {
    try {
      final response = await _dio.get('/attendance/');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Asistencia.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo asistencias: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      final response = await _dio.get('/attendance/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo historial de asistencia: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary() async {
    try {
      final response = await _dio.get('/attendance/summary/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo resumen de asistencia: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos específicos para docentes
  Future<Map<String, dynamic>> getTeacherAttendanceStats() async {
    try {
      final response = await _dio.get('/attendance/teacher/stats/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('Error obteniendo estadísticas de asistencia del docente: $e');
      return {};
    }
  }

  // Métodos específicos para administradores
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _dio.get('/admin/system-stats/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('Error obteniendo estadísticas del sistema: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final response = await _dio.get('/admin/recent-activities/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      print('Error obteniendo actividades recientes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getGlobalAttendanceStats() async {
    try {
      final response = await _dio.get('/admin/attendance-stats/');
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      print('Error obteniendo estadísticas globales de asistencia: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> createAttendanceSession(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/attendance/sessions/create/', data: data);
      return _safeParseResponse(response.data);
    } on DioException catch (e) {
      throw Exception('Error creando sesión: ${e.response?.data ?? e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> markAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/attendance/mark/', data: data);
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error marcando asistencia: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para servicios
  Future<List<Servicio>> getServicios() async {
    try {
      final response = await _dio.get('/services/');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Servicio.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo servicios: ${e.response?.data ?? e.message}');
    }
  }

  // Métodos para notificaciones
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications/');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión: Verifica que el servidor esté ejecutándose');
      }
      throw Exception('Error obteniendo notificaciones: ${e.response?.data ?? e.message}');
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count/');
      final data = _safeParseResponse(response.data);
      return data['unread_count'] ?? 0;
    } on DioException catch (e) {
      print('Error obteniendo contador de notificaciones: $e');
      return 0;
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read/');
    } on DioException catch (e) {
      throw Exception('Error marcando notificación como leída: ${e.response?.data ?? e.message}');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('/notifications/mark-all-read/');
    } on DioException catch (e) {
      throw Exception('Error marcando notificaciones como leídas: ${e.response?.data ?? e.message}');
    }
  }
}

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  AuthInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _prefs.getString(AppConfig.accessTokenKey);

    // Solo log para endpoints importantes
    if (options.path.contains('/tasks/') || options.path.contains('/courses/') || options.path.contains('/debug/')) {
      print('🔑 AuthInterceptor: Verificando token para ${options.path}');
    }

    if (token != null && !options.path.contains('/auth/login') && !options.path.contains('/auth/register')) {
      options.headers['Authorization'] = 'Bearer $token';

      if (options.path.contains('/tasks/') || options.path.contains('/courses/') || options.path.contains('/debug/')) {
        print('✅ AuthInterceptor: Token agregado al header');
        print('   Token: ${token.substring(0, 50)}...');
      }
    } else if (token == null) {
      if (options.path.contains('/tasks/') || options.path.contains('/courses/')) {
        print('❌ AuthInterceptor: No hay token disponible para ${options.path}');
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    print('❌ AuthInterceptor: Error $statusCode en $path');

    if (statusCode == 401) {
      print('🔒 AuthInterceptor: Token expirado o inválido, limpiando datos');
      // Token expirado, limpiar datos y redirigir al login
      await _prefs.clear();
    } else if (statusCode == 403) {
      print('🚫 AuthInterceptor: Acceso prohibido - verificar permisos');
      print('   Path: $path');
      print('   Error data: ${err.response?.data}');

      // Log del token para debug
      final authHeader = err.requestOptions.headers['Authorization'];
      if (authHeader != null) {
        print('   Token usado: ${authHeader.toString().substring(0, 50)}...');
      } else {
        print('   ❌ No se envió token de autorización');
      }
    }

    handler.next(err);
  }
}