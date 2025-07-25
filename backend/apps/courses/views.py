from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Enrollment, Grade, CourseGroup, Schedule
from .serializers import EnrollmentSerializer, GradeSerializer, ScheduleSerializer, CourseGroupSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_enrollments(request):
    """Lista de matrículas del estudiante"""
    print(f'📚 BACKEND: Usuario {request.user.correo} ({request.user.rol}) solicitando matrículas')
    print(f'📚 BACKEND: Usuario activo: {request.user.is_active}')
    print(f'📚 BACKEND: Username: {request.user.username}')

    if request.user.rol != 'estudiante':
        print(f'❌ BACKEND: ACCESO DENEGADO - Usuario {request.user.correo} no es estudiante')
        print(f'❌ BACKEND: Rol actual: "{request.user.rol}" (esperado: "estudiante")')
        print(f'❌ BACKEND: Tipo de rol: {type(request.user.rol)}')
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    try:
        print(f'✅ BACKEND: Usuario {request.user.correo} autorizado para ver matrículas')

        # Verificar que el usuario tenga perfil de estudiante
        if not hasattr(request.user, 'student_profile'):
            print(f'❌ BACKEND: Usuario {request.user.correo} no tiene perfil de estudiante')
            print(f'❌ BACKEND: Atributos del usuario: {dir(request.user)}')
            return Response({
                'error': 'Perfil de estudiante no encontrado. Contacta al administrador.',
                'user_info': {
                    'correo': request.user.correo,
                    'rol': request.user.rol,
                    'has_student_profile': False
                }
            }, status=400)

        print(f'✅ BACKEND: Perfil de estudiante verificado para {request.user.correo}')

        enrollments = Enrollment.objects.filter(
            student=request.user.student_profile,
            is_active=True
        ).select_related('course_group__course', 'course_group__teacher', 'course_group__period')

        print(f'📊 BACKEND: Encontradas {enrollments.count()} matrículas activas')

        if enrollments.count() == 0:
            print(f'⚠️ BACKEND: No hay matrículas activas para {request.user.correo}')
            return Response({
                'message': 'No tienes cursos matriculados actualmente',
                'enrollments': []
            })

        serializer = EnrollmentSerializer(enrollments, many=True)
        print(f'📤 BACKEND: Enviando {len(serializer.data)} matrículas al frontend')
        return Response(serializer.data)
    except Exception as e:
        print(f'❌ BACKEND: Error obteniendo matrículas: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_grades(request, enrollment_id):
    """Lista de calificaciones del estudiante para una matrícula específica"""
    if request.user.rol != 'estudiante':
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    enrollment = get_object_or_404(
        Enrollment,
        id=enrollment_id,
        student=request.user.student_profile
    )

    grades = Grade.objects.filter(enrollment=enrollment).order_by('-date')
    serializer = GradeSerializer(grades, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def course_schedules(request, enrollment_id):
    """Lista de horarios para una matrícula específica"""
    if request.user.rol != 'estudiante':
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    enrollment = get_object_or_404(
        Enrollment,
        id=enrollment_id,
        student=request.user.student_profile
    )

    schedules = enrollment.course_group.schedules.all().order_by('day_of_week', 'start_time')
    serializer = ScheduleSerializer(schedules, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def course_detail(request, enrollment_id):
    """Obtener detalles completos del curso"""
    if request.user.rol != 'estudiante':
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    enrollment = get_object_or_404(
        Enrollment,
        id=enrollment_id,
        student=request.user.student_profile
    )

    course_group = enrollment.course_group
    schedules = course_group.schedules.all().order_by('day_of_week', 'start_time')
    grades = Grade.objects.filter(enrollment=enrollment).order_by('-date')

    return Response({
        'course_group': CourseGroupSerializer(course_group).data,
        'schedules': ScheduleSerializer(schedules, many=True).data,
        'grades': GradeSerializer(grades, many=True).data,
        'enrollment': EnrollmentSerializer(enrollment).data
    })