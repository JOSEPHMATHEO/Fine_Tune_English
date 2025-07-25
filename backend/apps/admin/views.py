from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta
from apps.users.models import User, StudentProfile, TeacherProfile
from apps.courses.models import Course, CourseGroup, Enrollment
from apps.news.models import News
from apps.tasks.models import Task
from apps.attendance.models import AttendanceSession, Attendance

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def system_stats(request):
    """Obtener estadísticas generales del sistema (solo admin)"""
    if request.user.rol != 'admin':
        return Response({'error': 'Solo administradores pueden acceder'}, status=403)

    try:
        # Contar usuarios por rol
        total_students = User.objects.filter(rol='estudiante', is_active=True).count()
        total_teachers = User.objects.filter(rol='docente', is_active=True).count()

        # Contar cursos y matrículas
        total_courses = Course.objects.filter(is_active=True).count()
        active_enrollments = Enrollment.objects.filter(is_active=True).count()

        # Contar noticias y tareas
        total_news = News.objects.filter(is_published=True).count()
        pending_tasks = Task.objects.filter(is_active=True).count()

        # Calcular salud del sistema (ejemplo simple)
        system_health = 98.5  # Esto podría calcularse basado en métricas reales

        stats_data = {
            'total_students': total_students,
            'total_teachers': total_teachers,
            'total_courses': total_courses,
            'active_enrollments': active_enrollments,
            'total_news': total_news,
            'pending_tasks': pending_tasks,
            'system_health': system_health,
        }

        return Response(stats_data)

    except Exception as e:
        print(f'Error obteniendo estadísticas del sistema: {e}')
        return Response({
            'error': 'Error obteniendo estadísticas del sistema'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_activities(request):
    """Obtener actividades recientes del sistema (solo admin)"""
    if request.user.rol != 'admin':
        return Response({'error': 'Solo administradores pueden acceder'}, status=403)

    try:
        activities = []

        # Matrículas recientes
        recent_enrollments = Enrollment.objects.filter(
            enrollment_date__gte=timezone.now() - timedelta(days=7)
        ).select_related('student__user', 'course_group__course').order_by('-enrollment_date')[:5]

        for enrollment in recent_enrollments:
            activities.append({
                'type': 'enrollment',
                'description': f'Nuevo estudiante matriculado en {enrollment.course_group.course.name}',
                'timestamp': enrollment.enrollment_date.isoformat(),
                'user': enrollment.student.user.nombre_completo,
            })

        # Tareas recientes
        recent_tasks = Task.objects.filter(
            created_at__gte=timezone.now() - timedelta(days=7)
        ).select_related('course_group__course', 'course_group__teacher__user').order_by('-created_at')[:5]

        for task in recent_tasks:
            activities.append({
                'type': 'task_created',
                'description': f'Tarea creada: {task.title}',
                'timestamp': task.created_at.isoformat(),
                'user': f'Prof. {task.course_group.teacher.user.nombre_completo}',
            })

        # Noticias recientes
        recent_news = News.objects.filter(
            created_at__gte=timezone.now() - timedelta(days=7),
            is_published=True
        ).select_related('author').order_by('-created_at')[:5]

        for news in recent_news:
            activities.append({
                'type': 'news_published',
                'description': f'Nueva noticia publicada: {news.title}',
                'timestamp': news.created_at.isoformat(),
                'user': news.author.nombre_completo,
            })

        # Ordenar por timestamp
        activities.sort(key=lambda x: x['timestamp'], reverse=True)

        return Response(activities[:10])  # Retornar las 10 más recientes

    except Exception as e:
        print(f'Error obteniendo actividades recientes: {e}')
        return Response({
            'error': 'Error obteniendo actividades recientes'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def global_attendance_stats(request):
    """Obtener estadísticas globales de asistencia (solo admin)"""
    if request.user.rol != 'admin':
        return Response({'error': 'Solo administradores pueden acceder'}, status=403)

    try:
        # Estadísticas generales
        total_attendances = Attendance.objects.all()
        present_count = total_attendances.filter(status='present').count()
        total_count = total_attendances.count()

        overall_attendance = (present_count / total_count * 100) if total_count > 0 else 0

        # Estadísticas de hoy
        today = timezone.now().date()
        today_sessions = AttendanceSession.objects.filter(date=today).count()

        today_attendances = Attendance.objects.filter(session__date=today)
        students_present_today = today_attendances.filter(status='present').count()
        total_students_today = today_attendances.count()

        # Tendencia semanal (últimos 7 días)
        weekly_trend = []
        for i in range(7):
            date = today - timedelta(days=6-i)
            day_attendances = Attendance.objects.filter(session__date=date)
            day_present = day_attendances.filter(status='present').count()
            day_total = day_attendances.count()
            day_percentage = (day_present / day_total * 100) if day_total > 0 else 0
            weekly_trend.append(round(day_percentage, 1))

        stats_data = {
            'overall_attendance': round(overall_attendance, 1),
            'today_sessions': today_sessions,
            'students_present_today': students_present_today,
            'total_students_today': total_students_today,
            'weekly_trend': weekly_trend,
        }

        return Response(stats_data)

    except Exception as e:
        print(f'Error obteniendo estadísticas globales de asistencia: {e}')
        return Response({
            'error': 'Error obteniendo estadísticas globales de asistencia'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)