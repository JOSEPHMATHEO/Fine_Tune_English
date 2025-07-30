# Fine Tune English - Mobile Application

Una aplicación móvil completa para la institución educativa Fine Tune English, desarrollada con Clean Architecture usando Django como backend y Flutter como frontend.

## 🏗️ Arquitectura

### Backend (Django)
- **Clean Architecture** con separación clara de capas
- **Django REST Framework** para APIs
- **PostgreSQL** como base de datos principal
- **Redis** para cache y Celery
- **JWT** para autenticación
- **Celery** para tareas asíncronas

### Frontend (Flutter)
- **Clean Architecture** con BLoC pattern
- **Flutter BLoC** para gestión de estado
- **Dio** para comunicación HTTP
- **Go Router** para navegación
- **Hive** para almacenamiento local

## 📱 Características

### Autenticación
- Login con email/username y contraseña
- Recuperación de contraseña
- JWT tokens con refresh automático
- Roles: Estudiante, Docente, Administrativo

### Dashboard
- Información personalizada del usuario
- Carrusel de noticias institucionales
- Tareas pendientes
- Acciones rápidas
- Notificaciones en tiempo real

### Gestión de Clases
- Visualización de cursos matriculados
- Horarios detallados por día
- Calificaciones y evaluaciones
- Información del docente

### Servicios
- Generación de certificados online
- Acceso a clases virtuales (Zoom)
- Biblioteca digital
- Tutorías personalizadas
- Evaluaciones online

### Calendario y Asistencia
- Calendario interactivo
- Registro de asistencia diaria
- Estadísticas de asistencia
- Próximas clases y eventos

### Perfil de Usuario
- Información personal completa
- Estadísticas académicas
- Logros y certificaciones
- Configuración de cuenta

## 🗄️ Base de Datos

### Entidades Principales

#### Usuarios
- `User` - Usuario base del sistema
- `StudentProfile` - Perfil específico de estudiante
- `TeacherProfile` - Perfil específico de docente

#### Académico
- `Course` - Cursos disponibles
- `CourseGroup` - Grupos de curso por período
- `Enrollment` - Matriculación de estudiantes
- `Schedule` - Horarios de clases
- `Grade` - Calificaciones

#### Contenido
- `News` - Noticias institucionales
- `Task` - Tareas asignadas
- `TaskSubmission` - Entregas de tareas

#### Servicios
- `Service` - Servicios disponibles
- `ServiceRequest` - Solicitudes de servicios
- `Certificate` - Certificados generados

#### Asistencia
- `AttendanceSession` - Sesiones de clase
- `Attendance` - Registro de asistencia
- `AttendanceSummary` - Resumen de asistencia

#### Notificaciones
- `Notification` - Notificaciones del sistema
- `NotificationType` - Tipos de notificación
- `NotificationPreference` - Preferencias de usuario

## 🚀 Instalación y Configuración

### Backend (Django)

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd fine-tune-english/backend
```

2. **Crear entorno virtual**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o
venv\Scripts\activate  # Windows
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**
```bash
cp .env.example .env
# Editar .env con tus configuraciones
```

5. **Configurar base de datos**
```bash
# Crear base de datos PostgreSQL
createdb fine_tuned_english

# Ejecutar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser
```

6. **Ejecutar servidor**
```bash
python manage.py runserver
```

### Frontend (Flutter)

1. **Navegar al directorio frontend**
```bash
cd ../frontend
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Generar código** 
```

4. **Ejecutar aplicación**
```bash
flutter run
```

### Docker (Opcional)

```bash
cd backend
docker-compose up -d
```

## 📋 API Endpoints

### Autenticación
- `POST /api/auth/login/` - Iniciar sesión
- `POST /api/auth/token/refresh/` - Renovar token
- `POST /api/auth/password-reset/` - Recuperar contraseña
- `GET /api/auth/profile/` - Obtener perfil
- `PUT /api/auth/profile/update/` - Actualizar perfil

### Cursos
- `GET /api/courses/enrollments/` - Cursos matriculados
- `GET /api/courses/enrollments/{id}/grades/` - Calificaciones
- `GET /api/courses/enrollments/{id}/schedules/` - Horarios

### Noticias
- `GET /api/news/` - Lista de noticias
- `GET /api/news/{id}/` - Detalle de noticia
- `POST /api/news/{id}/view/` - Marcar como vista

### Tareas
- `GET /api/tasks/` - Tareas asignadas
- `GET /api/tasks/{id}/` - Detalle de tarea
- `POST /api/tasks/{id}/submit/` - Entregar tarea

### Servicios
- `GET /api/services/` - Servicios disponibles
- `POST /api/services/{id}/request/` - Solicitar servicio

### Asistencia
- `GET /api/attendance/` - Registro de asistencia
- `GET /api/attendance/summary/` - Resumen de asistencia

### Notificaciones
- `GET /api/notifications/` - Lista de notificaciones
- `PUT /api/notifications/{id}/read/` - Marcar como leída

## 🔧 Tecnologías Utilizadas

### Backend
- Python 3.11+
- Django 4.2+
- Django REST Framework
- PostgreSQL
- Redis
- Celery
- JWT Authentication
- Docker

### Frontend
- Flutter 3.0+
- Dart 3.0+
- BLoC Pattern
- Dio HTTP Client

