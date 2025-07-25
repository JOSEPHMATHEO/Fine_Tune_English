from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Attendance, AttendanceSummary, AttendanceSession
from .serializers import AttendanceSerializer, AttendanceSummarySerializer, AttendanceSessionSerializer
from apps.courses.models import Enrollment, CourseGroup

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_attendance(request):
    """Lista de asistencias del estudiante"""
    print(f'📊 BACKEND: Usuario {request.user.correo} solicitando historial de asistencia')

    if request.user.rol != 'estudiante':
        print(f'❌ BACKEND: Usuario {request.user.correo} no es estudiante (rol: {request.user.rol})')
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    try:
        # Verificar que el usuario tenga perfil de estudiante
        if not hasattr(request.user, 'student_profile'):
            print(f'❌ BACKEND: Usuario {request.user.correo} no tiene perfil de estudiante')
            return Response({
                'error': 'Perfil de estudiante no encontrado'
            }, status=400)

        attendances = Attendance.objects.filter(
            student=request.user.student_profile
        ).select_related(
            'session__course_group__course',
            'session__schedule__classroom',
            'session__course_group__teacher__user'
        ).order_by('-session__date')

        print(f'📊 BACKEND: Encontradas {attendances.count()} asistencias para {request.user.correo}')

        serializer = AttendanceSerializer(attendances, many=True)
        return Response(serializer.data)

    except Exception as e:
        print(f'❌ BACKEND: Error obteniendo asistencias: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def attendance_summary(request):
    """Resumen de asistencia del estudiante"""
    if request.user.rol != 'estudiante':
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    try:
        # Obtener todas las asistencias del estudiante
        attendances = Attendance.objects.filter(
            student=request.user.student_profile
        ).select_related('session__course_group__course')

        # Calcular estadísticas generales
        total_sessions = attendances.count()
        present_count = attendances.filter(status='present').count()
        absent_count = attendances.filter(status='absent').count()
        late_count = attendances.filter(status='late').count()
        excused_count = attendances.filter(status='excused').count()

        attendance_percentage = (present_count / total_sessions * 100) if total_sessions > 0 else 0

        # Calcular estadísticas por materia
        by_subject = {}
        subjects = attendances.values_list('session__subject', flat=True).distinct()

        for subject in subjects:
            subject_attendances = attendances.filter(session__subject=subject)
            subject_total = subject_attendances.count()
            subject_present = subject_attendances.filter(status='present').count()
            subject_percentage = (subject_present / subject_total * 100) if subject_total > 0 else 0

            by_subject[subject] = {
                'total': subject_total,
                'present': subject_present,
                'percentage': round(subject_percentage, 1)
            }

        summary_data = {
            'total_sessions': total_sessions,
            'present_count': present_count,
            'absent_count': absent_count,
            'late_count': late_count,
            'excused_count': excused_count,
            'attendance_percentage': round(attendance_percentage, 1),
            'by_subject': by_subject
        }

        return Response(summary_data)
    except Exception as e:
        print(f'Error calculando resumen de asistencia: {e}')
        return Response({
            'error': 'Error calculando resumen de asistencia'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_attendance_session(request):
    """Crear sesión de asistencia (solo docentes)"""
    print(f'📊 BACKEND: Docente {request.user.correo} creando sesión de asistencia')

    if request.user.rol != 'docente':
        print(f'❌ BACKEND: Usuario {request.user.correo} no es docente')
        return Response({'error': 'Solo docentes pueden crear sesiones'}, status=403)

    try:
        course_group_id = request.data.get('course_group')
        if not course_group_id:
            return Response({'error': 'course_group es requerido'}, status=400)

        course_group = get_object_or_404(CourseGroup, id=course_group_id)

        # Verificar que el docente tenga acceso al grupo
        if course_group.teacher.user != request.user:
            print(f'❌ BACKEND: Docente {request.user.correo} no tiene acceso al grupo {course_group_id}')
            return Response({'error': 'No tienes acceso a este grupo'}, status=403)

        # Obtener o crear el schedule correspondiente
        from apps.courses.models import Schedule
        schedule = Schedule.objects.filter(course_group=course_group).first()
        if not schedule:
            print(f'⚠️ BACKEND: No hay horario definido para el grupo {course_group_id}')
            return Response({'error': 'No hay horario definido para este grupo'}, status=400)

        # Crear la sesión de asistencia
        session_data = request.data.copy()
        session_data['schedule'] = schedule.id

        serializer = AttendanceSessionSerializer(data=session_data)
        if serializer.is_valid():
            session = serializer.save()
            print(f'✅ BACKEND: Sesión de asistencia creada: {session.id}')
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            print(f'❌ BACKEND: Errores de validación: {serializer.errors}')
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        print(f'❌ BACKEND: Error creando sesión de asistencia: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_attendance(request):
    """Marcar asistencia de estudiantes (solo docentes)"""
    print(f'📊 BACKEND: Docente {request.user.correo} marcando asistencia')

    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden marcar asistencia'}, status=403)

    try:
        session_id = request.data.get('session_id')
        attendances_data = request.data.get('attendances', [])

        if not session_id:
            return Response({'error': 'session_id es requerido'}, status=400)

        if not attendances_data:
            return Response({'error': 'attendances es requerido'}, status=400)

        session = get_object_or_404(AttendanceSession, id=session_id)

        # Verificar que el docente tenga acceso a la sesión
        if session.course_group.teacher.user != request.user:
            print(f'❌ BACKEND: Docente {request.user.correo} no tiene acceso a la sesión {session_id}')
            return Response({'error': 'No tienes acceso a esta sesión'}, status=403)

        created_attendances = []
        for attendance_data in attendances_data:
            try:
                # Obtener el perfil del estudiante
                from apps.users.models import StudentProfile
                student_profile = get_object_or_404(StudentProfile, id=attendance_data['student_id'])

                attendance, created = Attendance.objects.update_or_create(
                    session=session,
                    student=student_profile,
                    defaults={
                        'status': attendance_data['status'],
                        'arrival_time': attendance_data.get('arrival_time'),
                        'notes': attendance_data.get('notes', ''),
                        'marked_by': request.user
                    }
                )
                created_attendances.append(attendance)
                print(f'✅ BACKEND: Asistencia {"actualizada" if not created else "creada"} para estudiante {student_profile.user.nombre_completo}')

            except Exception as e:
                print(f'❌ BACKEND: Error procesando asistencia para estudiante {attendance_data.get("student_id")}: {e}')
                continue

        print(f'✅ BACKEND: Procesadas {len(created_attendances)} asistencias')

        serializer = AttendanceSerializer(created_attendances, many=True)
        return Response(serializer.data)

    except Exception as e:
        print(f'❌ BACKEND: Error marcando asistencia: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def teacher_attendance_sessions(request):
    """Obtener sesiones de asistencia del docente"""
    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden acceder'}, status=403)

    sessions = AttendanceSession.objects.filter(
        course_group__teacher__user=request.user
    ).order_by('-date')

    serializer = AttendanceSessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def teacher_attendance_stats(request):
    """Obtener estadísticas de asistencia para el docente"""
    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden acceder'}, status=403)

    try:
        # Obtener grupos del docente
        course_groups = CourseGroup.objects.filter(teacher__user=request.user)

        # Calcular estadísticas
        total_sessions = AttendanceSession.objects.filter(
            course_group__in=course_groups
        ).count()

        total_attendances = Attendance.objects.filter(
            session__course_group__in=course_groups
        )

        present_count = total_attendances.filter(status='present').count()
        total_count = total_attendances.count()

        average_attendance = (present_count / total_count * 100) if total_count > 0 else 0

        # Estadísticas por grupo
        group_stats = []
        for group in course_groups:
            group_attendances = Attendance.objects.filter(
                session__course_group=group
            )
            group_present = group_attendances.filter(status='present').count()
            group_total = group_attendances.count()
            group_percentage = (group_present / group_total * 100) if group_total > 0 else 0

            group_stats.append({
                'group_id': group.id,
                'group_name': group.name,
                'course_name': group.course.name,
                'attendance_rate': round(group_percentage, 1),
                'enrolled_students': Enrollment.objects.filter(
                    course_group=group, is_active=True
                ).count()
            })

        stats_data = {
            'average_attendance': round(average_attendance, 1),
            'total_sessions': total_sessions,
            'total_groups': course_groups.count(),
            'group_stats': group_stats,
        }

        return Response(stats_data)

    except Exception as e:
        print(f'Error calculando estadísticas del docente: {e}')
        return Response({
            'error': 'Error calculando estadísticas'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)