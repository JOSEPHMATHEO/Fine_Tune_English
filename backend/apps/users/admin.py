from django.contrib import admin
from .models import User, StudentProfile, TeacherProfile, PasswordResetToken

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['nombre_completo', 'correo', 'rol', 'is_active', 'created_at']
    list_filter = ['rol', 'is_active', 'created_at']
    search_fields = ['nombre_completo', 'correo', 'cedula']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'nivel_estudio', 'fecha_nacimiento', 'genero']
    list_filter = ['nivel_estudio', 'genero', 'estado_civil']
    search_fields = ['user__nombre_completo', 'user__correo']

@admin.register(TeacherProfile)
class TeacherProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'especialization', 'hire_date']
    list_filter = ['hire_date']
    search_fields = ['user__nombre_completo', 'user__correo', 'especialization']

@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ['user', 'token', 'created_at', 'expires_at', 'is_used']
    list_filter = ['is_used', 'created_at']
    readonly_fields = ['token', 'created_at', 'expires_at']