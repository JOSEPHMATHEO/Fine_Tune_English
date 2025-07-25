from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid
from django.utils import timezone
from datetime import timedelta

class User(AbstractUser):
    USER_ROLES = (
        ('estudiante', 'Estudiante'),
        ('docente', 'Docente'),
        ('admin', 'Administrativo'),
    )

    # Campos personalizados
    nombre_completo = models.CharField(max_length=100)
    cedula = models.CharField(max_length=20, unique=True, null=True, blank=True)
    correo = models.EmailField(max_length=100, unique=True)
    telefono = models.CharField(max_length=20, null=True, blank=True)
    rol = models.CharField(max_length=20, choices=USER_ROLES, default='estudiante')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Configurar email como campo de login
    USERNAME_FIELD = 'correo'
    REQUIRED_FIELDS = ['username', 'nombre_completo']

    def __str__(self):
        return f"{self.nombre_completo} - {self.get_rol_display()}"

    def get_full_name(self):
        """Método requerido por Django"""
        return self.nombre_completo

    @property
    def primer_nombre(self):
        return self.nombre_completo.split(' ')[0]

class PasswordResetToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    token = models.UUIDField(default=uuid.uuid4, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(hours=1)  # Token válido por 1 hora
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

    @property
    def is_valid(self):
        return not self.is_used and not self.is_expired

    def __str__(self):
        return f"Reset token for {self.user.correo}"

class StudentProfile(models.Model):
    LEVELS = (
        ('A1', 'Principiante A1'),
        ('A2', 'Principiante A2'),
        ('B1', 'Intermedio B1'),
        ('B2', 'Intermedio B2'),
        ('C1', 'Avanzado C1'),
        ('C2', 'Avanzado C2'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    nivel_estudio = models.CharField(max_length=50)
    fecha_nacimiento = models.DateField()
    genero = models.CharField(max_length=10)
    estado_civil = models.CharField(max_length=20)
    parroquia = models.CharField(max_length=100)
    origen_ingresos = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.user.nombre_completo} - Estudiante"

class TeacherProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='teacher_profile')
    especialization = models.CharField(max_length=100)
    hire_date = models.DateField()

    def __str__(self):
        return f"{self.user.nombre_completo} - {self.especialization}"