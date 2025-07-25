from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import make_password, check_password
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.utils import timezone
from .serializers import (
    UserSerializer,
    StudentProfileSerializer,
    TeacherProfileSerializer,
    LoginSerializer,
    RegisterSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    ChangePasswordSerializer
)
from .models import User, StudentProfile, TeacherProfile, PasswordResetToken

@api_view(['GET'])
@permission_classes([AllowAny])
def test_connection(request):
    """Endpoint para probar la conexión"""
    return Response({
        'message': 'Conexión exitosa con el backend Django',
        'status': 'OK',
        'timestamp': timezone.now().isoformat()
    })

@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """Registro de nuevo usuario"""
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()

        # Generar tokens JWT
        refresh = RefreshToken.for_user(user)

        # Obtener datos del perfil si existe
        profile_data = None
        if user.rol == 'estudiante' and hasattr(user, 'student_profile'):
            profile_data = StudentProfileSerializer(user.student_profile).data
        elif user.rol == 'docente' and hasattr(user, 'teacher_profile'):
            profile_data = TeacherProfileSerializer(user.teacher_profile).data

        return Response({
            'message': 'Usuario creado exitosamente',
            'access_token': str(refresh.access_token),
            'refresh_token': str(refresh),
            'usuario': UserSerializer(user).data,
            'perfil': profile_data
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """Login de usuario con validación mejorada"""
    try:
        correo = request.data.get('correo', '').strip()
        password = request.data.get('password', '')

        print(f'🔐 BACKEND: Intento de login para: {correo}')

        if not correo or not password:
            print(f'❌ BACKEND: Datos incompletos para login')
            return Response({
                'non_field_errors': ['Correo y contraseña son requeridos.']
            }, status=status.HTTP_400_BAD_REQUEST)

        # Buscar usuario por correo
        try:
            user = User.objects.get(correo=correo)
            print(f'✅ BACKEND: Usuario encontrado: {user.nombre_completo} - Rol: {user.rol} - Activo: {user.is_active}')

            # Verificar si tiene perfil según su rol
            if user.rol == 'estudiante':
                if not hasattr(user, 'student_profile'):
                    print(f'❌ BACKEND: Usuario estudiante {correo} no tiene perfil de estudiante')
                    return Response({
                        'non_field_errors': ['Perfil de estudiante no configurado. Contacta al administrador.']
                    }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    print(f'✅ BACKEND: Perfil de estudiante verificado para {correo}')

            elif user.rol == 'docente':
                if not hasattr(user, 'teacher_profile'):
                    print(f'❌ BACKEND: Usuario docente {correo} no tiene perfil de docente')
                    return Response({
                        'non_field_errors': ['Perfil de docente no configurado. Contacta al administrador.']
                    }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    print(f'✅ BACKEND: Perfil de docente verificado para {correo}')

        except User.DoesNotExist:
            print(f'❌ BACKEND: Usuario no encontrado: {correo}')
            return Response({
                'non_field_errors': ['Credenciales incorrectas.']
            }, status=status.HTTP_400_BAD_REQUEST)

        # Verificar si el usuario está activo
        if not user.is_active:
            print(f'❌ BACKEND: Usuario inactivo: {correo}')
            return Response({
                'non_field_errors': ['Cuenta desactivada.']
            }, status=status.HTTP_400_BAD_REQUEST)

        # Verificar contraseña
        if not check_password(password, user.password):
            print(f'❌ BACKEND: Contraseña incorrecta para: {correo}')
            return Response({
                'non_field_errors': ['Credenciales incorrectas.']
            }, status=status.HTTP_400_BAD_REQUEST)

        print(f'✅ BACKEND: Login exitoso para: {correo}')

        # Generar tokens
        refresh = RefreshToken.for_user(user)

        # Obtener datos del perfil
        profile_data = None
        if user.rol == 'estudiante' and hasattr(user, 'student_profile'):
            profile_data = StudentProfileSerializer(user.student_profile).data
        elif user.rol == 'docente' and hasattr(user, 'teacher_profile'):
            profile_data = TeacherProfileSerializer(user.teacher_profile).data

        # Log del token generado para debug
        access_token = str(refresh.access_token)
        print(f'🔑 BACKEND: Token generado para {correo}: {access_token[:50]}...')

        return Response({
            'access_token': access_token,
            'refresh_token': str(refresh),
            'usuario': UserSerializer(user).data,
            'perfil': profile_data
        })

    except Exception as e:
        print(f'❌ BACKEND: Error en login: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'non_field_errors': ['Error interno del servidor.']
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request_view(request):
    """Solicitar recuperación de contraseña"""
    serializer = PasswordResetRequestSerializer(data=request.data)
    if serializer.is_valid():
        correo = serializer.validated_data['correo']
        user = User.objects.get(correo=correo)

        # Invalidar tokens anteriores
        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)

        # Crear nuevo token
        reset_token = PasswordResetToken.objects.create(user=user)

        # Enviar email
        try:
            reset_url = f"{settings.FRONTEND_URL}/reset-password?token={reset_token.token}"

            html_message = render_to_string('emails/password_reset.html', {
                'user': user,
                'reset_url': reset_url,
                'token': reset_token.token
            })
            plain_message = strip_tags(html_message)

            send_mail(
                subject='Recuperación de Contraseña - Fine Tune English',
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.correo],
                html_message=html_message,
                fail_silently=False,
            )

            return Response({
                'message': 'Se ha enviado un enlace de recuperación a tu correo electrónico.',
                'token': str(reset_token.token)  # Solo para desarrollo/testing
            })
        except Exception as e:
            return Response({
                'error': 'Error al enviar el correo. Inténtalo más tarde.'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_confirm_view(request):
    """Confirmar y cambiar contraseña"""
    serializer = PasswordResetConfirmSerializer(data=request.data)
    if serializer.is_valid():
        reset_token = serializer.validated_data['reset_token']
        new_password = serializer.validated_data['new_password']

        # Cambiar contraseña
        user = reset_token.user
        user.password = make_password(new_password)
        user.save()

        # Marcar token como usado
        reset_token.is_used = True
        reset_token.save()

        return Response({
            'message': 'Contraseña cambiada exitosamente.'
        })

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([AllowAny])
def verify_reset_token_view(request):
    """Verificar si un token de recuperación es válido"""
    token = request.GET.get('token')
    if not token:
        return Response({'error': 'Token requerido'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        reset_token = PasswordResetToken.objects.get(token=token)
        if reset_token.is_valid:
            return Response({
                'valid': True,
                'user_email': reset_token.user.correo
            })
        else:
            return Response({
                'valid': False,
                'message': 'Token expirado o ya utilizado'
            })
    except PasswordResetToken.DoesNotExist:
        return Response({
            'valid': False,
            'message': 'Token inválido'
        })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password_view(request):
    """Cambiar contraseña estando autenticado"""
    serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = request.user
        new_password = serializer.validated_data['new_password']

        user.password = make_password(new_password)
        user.save()

        return Response({
            'message': 'Contraseña cambiada exitosamente.'
        })

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_view(request):
    """Obtener perfil del usuario autenticado"""
    user = request.user
    user_data = UserSerializer(user).data

    profile_data = None
    if user.rol == 'estudiante' and hasattr(user, 'student_profile'):
        profile_data = StudentProfileSerializer(user.student_profile).data
    elif user.rol == 'docente' and hasattr(user, 'teacher_profile'):
        profile_data = TeacherProfileSerializer(user.teacher_profile).data

    return Response({
        'usuario': user_data,
        'perfil': profile_data
    })

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile_view(request):
    """Actualizar perfil del usuario autenticado"""
    user = request.user

    # Actualizar datos del usuario
    user_serializer = UserSerializer(user, data=request.data, partial=True)
    if user_serializer.is_valid():
        user_serializer.save()

        # Actualizar perfil específico
        profile_data = None
        if user.rol == 'estudiante' and hasattr(user, 'student_profile'):
            profile_serializer = StudentProfileSerializer(
                user.student_profile,
                data=request.data,
                partial=True
            )
            if profile_serializer.is_valid():
                profile_serializer.save()
                profile_data = profile_serializer.data
        elif user.rol == 'docente' and hasattr(user, 'teacher_profile'):
            profile_serializer = TeacherProfileSerializer(
                user.teacher_profile,
                data=request.data,
                partial=True
            )
            if profile_serializer.is_valid():
                profile_serializer.save()
                profile_data = profile_serializer.data

        return Response({
            'usuario': user_serializer.data,
            'perfil': profile_data,
            'message': 'Perfil actualizado exitosamente'
        })

    return Response(user_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Cerrar sesión"""
    try:
        refresh_token = request.data.get('refresh_token')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()

        return Response({
            'message': 'Sesión cerrada exitosamente'
        })
    except Exception as e:
        return Response({
            'message': 'Sesión cerrada exitosamente'
        })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def debug_user_info(request):
    """Endpoint de debug para verificar información del usuario"""
    try:
        print(f'🔍 DEBUG: Usuario autenticado: {request.user.correo}')
        print(f'🔍 DEBUG: Rol del usuario: {request.user.rol}')
        print(f'🔍 DEBUG: Usuario activo: {request.user.is_active}')

        user_info = {
            'user_id': request.user.id,
            'correo': request.user.correo,
            'nombre_completo': request.user.nombre_completo,
            'rol': request.user.rol,
            'is_active': request.user.is_active,
            'has_student_profile': hasattr(request.user, 'student_profile'),
            'has_teacher_profile': hasattr(request.user, 'teacher_profile'),
            'username': request.user.username,
            'is_staff': request.user.is_staff,
            'is_superuser': request.user.is_superuser,
        }

        print(f'🔍 DEBUG: Tiene perfil estudiante: {user_info["has_student_profile"]}')
        print(f'🔍 DEBUG: Tiene perfil docente: {user_info["has_teacher_profile"]}')

        if hasattr(request.user, 'student_profile'):
            from apps.courses.models import Enrollment
            enrollments = Enrollment.objects.filter(
                student=request.user.student_profile,
                is_active=True
            )
            user_info['enrollments_count'] = enrollments.count()
            user_info['enrollments'] = [
                {
                    'id': e.id,
                    'course_name': e.course_group.course.name,
                    'group_name': e.course_group.name
                } for e in enrollments
            ]
            print(f'🔍 DEBUG: Matrículas encontradas: {user_info["enrollments_count"]}')
        else:
            print(f'🔍 DEBUG: Usuario no tiene perfil de estudiante')

        return Response(user_info)
    except Exception as e:
        print(f'❌ DEBUG: Error en debug_user_info: {e}')
        import traceback
        traceback.print_exc()
        return Response({'error': str(e)}, status=500)