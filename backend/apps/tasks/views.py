from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Task, TaskSubmission
from .serializers import TaskSerializer, TaskSubmissionSerializer
from apps.courses.models import Enrollment, CourseGroup

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_tasks(request):
    """Lista de tareas del estudiante"""
    print(f'📤 BACKEND: Usuario {request.user.correo} ({request.user.rol}) solicitando tareas')
    print(f'📤 BACKEND: Usuario activo: {request.user.is_active}')
    print(f'📤 BACKEND: Username: {request.user.username}')

    if request.user.rol != 'estudiante':
        print(f'❌ BACKEND: ACCESO DENEGADO - Usuario {request.user.correo} no es estudiante')
        print(f'❌ BACKEND: Rol actual: "{request.user.rol}" (esperado: "estudiante")')
        print(f'❌ BACKEND: Tipo de rol: {type(request.user.rol)}')
        return Response({'error': 'Solo estudiantes pueden acceder'}, status=403)

    try:
        print(f'✅ BACKEND: Usuario {request.user.correo} autorizado para ver tareas')

        # Obtener cursos del estudiante
        if not hasattr(request.user, 'student_profile'):
            print(f'❌ BACKEND: Usuario {request.user.correo} no tiene perfil de estudiante')
            return Response({
                'error': 'Perfil de estudiante no encontrado. Contacta al administrador.',
                'user_info': {
                    'correo': request.user.correo,
                    'rol': request.user.rol,
                    'has_student_profile': False
                }
            }, status=400)

        enrollments = Enrollment.objects.filter(
            student=request.user.student_profile,
            is_active=True
        ).select_related('course_group')

        print(f'📊 BACKEND: Encontradas {enrollments.count()} matrículas activas')

        if not enrollments.exists():
            print('⚠️ BACKEND: No hay matrículas activas para este estudiante')
            return Response([])

        course_groups = [enrollment.course_group for enrollment in enrollments]
        print(f'📚 BACKEND: Grupos de curso: {[cg.id for cg in course_groups]}')

        # Obtener tareas de esos cursos
        tasks = Task.objects.filter(
            course_group__in=course_groups,
            is_active=True
        ).select_related('course_group__course', 'course_group__teacher__user').order_by('-created_at')

        print(f'📋 BACKEND: Encontradas {tasks.count()} tareas activas')

        # Agregar información de entrega para cada tarea
        tasks_data = []
        for task in tasks:
            task_data = TaskSerializer(task).data

            # Verificar si el estudiante ya entregó la tarea
            try:
                submission = TaskSubmission.objects.get(
                    task=task,
                    student=request.user.student_profile
                )
                task_data['submission'] = TaskSubmissionSerializer(submission).data
                task_data['has_submission'] = True
            except TaskSubmission.DoesNotExist:
                task_data['submission'] = None
                task_data['has_submission'] = False

            # Calcular estado de la tarea
            now = timezone.now()
            if task.due_date < now:
                if task_data['has_submission']:
                    task_data['status'] = 'entregada_tarde' if submission.submitted_at > task.due_date else 'entregada'
                else:
                    task_data['status'] = 'vencida'
            elif task.due_date.date() == now.date():
                task_data['status'] = 'vence_hoy'
            else:
                days_left = (task.due_date.date() - now.date()).days
                if days_left <= 3:
                    task_data['status'] = 'urgente'
                else:
                    task_data['status'] = 'pendiente'

            # Agregar información adicional
            task_data['days_remaining'] = (task.due_date.date() - now.date()).days
            task_data['is_overdue'] = task.due_date < now

            tasks_data.append(task_data)

        return Response(tasks_data)

    except Exception as e:
        print(f'❌ BACKEND: Error obteniendo tareas del estudiante: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def task_detail(request, task_id):
    """Detalle de una tarea específica"""
    try:
        task = get_object_or_404(Task, id=task_id, is_active=True)

        # Verificar que el estudiante esté matriculado en el curso
        if request.user.rol == 'estudiante':
            enrollment_exists = Enrollment.objects.filter(
                student=request.user.student_profile,
                course_group=task.course_group,
                is_active=True
            ).exists()

            if not enrollment_exists:
                return Response({'error': 'No tienes acceso a esta tarea'}, status=403)

        task_data = TaskSerializer(task).data

        # Agregar información de entrega si es estudiante
        if request.user.rol == 'estudiante':
            try:
                submission = TaskSubmission.objects.get(
                    task=task,
                    student=request.user.student_profile
                )
                task_data['submission'] = TaskSubmissionSerializer(submission).data
                task_data['has_submission'] = True
            except TaskSubmission.DoesNotExist:
                task_data['submission'] = None
                task_data['has_submission'] = False

        return Response(task_data)

    except Exception as e:
        print(f'Error obteniendo detalle de tarea: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_task(request, task_id):
    """Entregar una tarea"""
    if request.user.rol != 'estudiante':
        return Response({'error': 'Solo estudiantes pueden entregar tareas'}, status=403)

    try:
        task = get_object_or_404(Task, id=task_id, is_active=True)

        # Verificar que el estudiante esté matriculado en el curso
        enrollment_exists = Enrollment.objects.filter(
            student=request.user.student_profile,
            course_group=task.course_group,
            is_active=True
        ).exists()

        if not enrollment_exists:
            return Response({'error': 'No tienes acceso a esta tarea'}, status=403)

        submission_text = request.data.get('submission_text', '').strip()
        if not submission_text:
            return Response({
                'error': 'El texto de la entrega es requerido'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Verificar si ya existe una entrega
        submission, created = TaskSubmission.objects.get_or_create(
            task=task,
            student=request.user.student_profile,
            defaults={
                'submission_text': submission_text,
                'status': 'submitted',
                'submitted_at': timezone.now()
            }
        )

        if not created:
            # Actualizar entrega existente
            submission.submission_text = submission_text
            submission.status = 'submitted'
            submission.submitted_at = timezone.now()
            submission.save()

        serializer = TaskSubmissionSerializer(submission)
        return Response({
            'message': 'Tarea entregada exitosamente',
            'submission': serializer.data
        })

    except Exception as e:
        print(f'Error entregando tarea: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_task(request):
    """Crear nueva tarea (solo docentes)"""
    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden crear tareas'}, status=403)

    try:
        # Obtener y validar el grupo del curso
        course_group_id = request.data.get('course_group')
        if not course_group_id:
            return Response({'error': 'course_group es requerido'}, status=status.HTTP_400_BAD_REQUEST)

        course_group = get_object_or_404(CourseGroup, id=course_group_id)

        # Verificar que el docente tenga acceso al grupo
        if course_group.teacher.user != request.user:
            return Response({'error': 'No tienes acceso a este grupo'}, status=403)

        # Preparar los datos para el serializer
        task_data = request.data.copy()

        # Validar campos requeridos
        required_fields = ['title', 'description', 'task_type', 'due_date', 'priority']
        for field in required_fields:
            if not task_data.get(field):
                return Response({
                    'error': f'El campo {field} es requerido'
                }, status=status.HTTP_400_BAD_REQUEST)

        # Crear el serializer con los datos
        serializer = TaskSerializer(data=task_data)

        if serializer.is_valid():
            # Guardar la tarea con el course_group correcto
            task = serializer.save(course_group=course_group)

            return Response({
                'message': 'Tarea creada exitosamente',
                'task': TaskSerializer(task).data
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                'error': 'Datos inválidos',
                'details': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

    except CourseGroup.DoesNotExist:
        return Response({
            'error': 'Grupo de curso no encontrado'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f'Error creando tarea: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def teacher_course_groups(request):
    """Obtener grupos de curso del docente"""
    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden acceder'}, status=403)

    try:
        course_groups = CourseGroup.objects.filter(
            teacher__user=request.user
        ).select_related('course', 'period', 'teacher__user')

        from apps.courses.serializers import CourseGroupSerializer
        serializer = CourseGroupSerializer(course_groups, many=True)
        return Response(serializer.data)
    except Exception as e:
        print(f'Error obteniendo grupos del docente: {e}')
        return Response({
            'error': f'Error obteniendo grupos: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def teacher_tasks(request):
    """Obtener tareas creadas por el docente"""
    if request.user.rol != 'docente':
        return Response({'error': 'Solo docentes pueden acceder'}, status=403)

    try:
        # Obtener grupos del docente
        course_groups = CourseGroup.objects.filter(teacher__user=request.user)

        # Obtener tareas de esos grupos
        tasks = Task.objects.filter(
            course_group__in=course_groups,
            is_active=True
        ).select_related('course_group__course').order_by('-created_at')

        tasks_data = []
        for task in tasks:
            task_data = TaskSerializer(task).data

            # Agregar estadísticas de entregas
            total_students = Enrollment.objects.filter(
                course_group=task.course_group,
                is_active=True
            ).count()

            submitted_count = TaskSubmission.objects.filter(
                task=task,
                status__in=['submitted', 'graded']
            ).count()

            task_data['total_students'] = total_students
            task_data['submitted_count'] = submitted_count
            task_data['pending_count'] = total_students - submitted_count

            tasks_data.append(task_data)

        return Response(tasks_data)

    except Exception as e:
        print(f'Error obteniendo tareas del docente: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)