from rest_framework import serializers
from django.contrib.auth.hashers import make_password, check_password
from .models import User, StudentProfile, TeacherProfile, PasswordResetToken

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'nombre_completo', 'correo', 'cedula', 'telefono', 'rol']
        read_only_fields = ['id']

class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = StudentProfile
        fields = ['user', 'nivel_estudio', 'fecha_nacimiento', 'genero', 'estado_civil', 'parroquia', 'origen_ingresos']

class TeacherProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = TeacherProfile
        fields = ['user', 'especialization', 'hire_date']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    # Campos opcionales del perfil de estudiante
    nivel_estudio = serializers.CharField(required=False, allow_blank=True)
    fecha_nacimiento = serializers.DateField(required=False, allow_null=True)
    genero = serializers.CharField(required=False, allow_blank=True)
    estado_civil = serializers.CharField(required=False, allow_blank=True)
    parroquia = serializers.CharField(required=False, allow_blank=True)
    origen_ingresos = serializers.CharField(required=False, allow_blank=True)

    # Campos opcionales del perfil de docente
    especialization = serializers.CharField(required=False, allow_blank=True)
    hire_date = serializers.DateField(required=False, allow_null=True)

    class Meta:
        model = User
        fields = [
            'nombre_completo', 'correo', 'cedula', 'telefono', 'rol',
            'password', 'confirm_password',
            # Campos de estudiante
            'nivel_estudio', 'fecha_nacimiento', 'genero', 'estado_civil',
            'parroquia', 'origen_ingresos',
            # Campos de docente
            'especialization', 'hire_date'
        ]

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError('Las contraseñas no coinciden.')

        # Validar campos requeridos según el rol
        if data['rol'] == 'estudiante':
            required_fields = ['nivel_estudio', 'fecha_nacimiento', 'genero', 'estado_civil']
            for field in required_fields:
                if not data.get(field):
                    raise serializers.ValidationError(f'El campo {field} es requerido para estudiantes.')

        elif data['rol'] == 'docente':
            if not data.get('especialization'):
                raise serializers.ValidationError('La especialización es requerida para docentes.')

        return data

    def validate_correo(self, value):
        if User.objects.filter(correo=value).exists():
            raise serializers.ValidationError('Ya existe un usuario con este correo electrónico.')
        return value

    def validate_cedula(self, value):
        if value and User.objects.filter(cedula=value).exists():
            raise serializers.ValidationError('Ya existe un usuario con esta cédula.')
        return value

    def create(self, validated_data):
        # Extraer campos que no pertenecen al modelo User
        password = validated_data.pop('password')
        validated_data.pop('confirm_password')

        # Campos del perfil de estudiante
        student_fields = {
            'nivel_estudio': validated_data.pop('nivel_estudio', ''),
            'fecha_nacimiento': validated_data.pop('fecha_nacimiento', None),
            'genero': validated_data.pop('genero', ''),
            'estado_civil': validated_data.pop('estado_civil', ''),
            'parroquia': validated_data.pop('parroquia', ''),
            'origen_ingresos': validated_data.pop('origen_ingresos', ''),
        }

        # Campos del perfil de docente
        teacher_fields = {
            'especialization': validated_data.pop('especialization', ''),
            'hire_date': validated_data.pop('hire_date', None),
        }

        # Generar username único basado en el correo
        username = validated_data['correo'].split('@')[0]
        counter = 1
        original_username = username
        while User.objects.filter(username=username).exists():
            username = f"{original_username}{counter}"
            counter += 1

        # Crear usuario
        user = User.objects.create(
            username=username,
            password=make_password(password),
            **validated_data
        )

        # Crear perfil según el rol
        if user.rol == 'estudiante':
            StudentProfile.objects.create(
                user=user,
                **{k: v for k, v in student_fields.items() if v}
            )
        elif user.rol == 'docente':
            TeacherProfile.objects.create(
                user=user,
                **{k: v for k, v in teacher_fields.items() if v}
            )

        return user

class LoginSerializer(serializers.Serializer):
    correo = serializers.EmailField()
    password = serializers.CharField()

    def validate(self, data):
        correo = data.get('correo')
        password = data.get('password')

        if correo and password:
            try:
                user = User.objects.get(correo=correo, is_active=True)
                if check_password(password, user.password):
                    data['user'] = user
                else:
                    raise serializers.ValidationError('Credenciales incorrectas.')
            except User.DoesNotExist:
                raise serializers.ValidationError('Usuario no encontrado.')
        else:
            raise serializers.ValidationError('Debe incluir correo y contraseña.')

        return data

class PasswordResetRequestSerializer(serializers.Serializer):
    correo = serializers.EmailField()

    def validate_correo(self, value):
        try:
            User.objects.get(correo=value, is_active=True)
        except User.DoesNotExist:
            raise serializers.ValidationError('No existe un usuario con este correo electrónico.')
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.UUIDField()
    new_password = serializers.CharField(min_length=6)
    confirm_password = serializers.CharField(min_length=6)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError('Las contraseñas no coinciden.')

        try:
            reset_token = PasswordResetToken.objects.get(token=data['token'])
            if not reset_token.is_valid:
                raise serializers.ValidationError('El token ha expirado o ya fue utilizado.')
            data['reset_token'] = reset_token
        except PasswordResetToken.DoesNotExist:
            raise serializers.ValidationError('Token inválido.')

        return data

class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField()
    new_password = serializers.CharField(min_length=6)
    confirm_password = serializers.CharField(min_length=6)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError('Las contraseñas no coinciden.')
        return data

    def validate_current_password(self, value):
        user = self.context['request'].user
        if not check_password(value, user.password):
            raise serializers.ValidationError('La contraseña actual es incorrecta.')
        return value