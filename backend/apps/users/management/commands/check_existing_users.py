from django.core.management.base import BaseCommand
from apps.users.models import User, StudentProfile, TeacherProfile

class Command(BaseCommand):
    help = 'Verificar usuarios existentes y encontrar el que está causando problemas'

    def handle(self, *args, **options):
        self.stdout.write('🔍 VERIFICANDO USUARIOS EXISTENTES...')
        self.stdout.write('=' * 60)

        # Buscar usuario con cédula problemática
        problematic_cedula = '1234567890'
        try:
            user_with_cedula = User.objects.get(cedula=problematic_cedula)
            self.stdout.write(f'🔍 Usuario con cédula {problematic_cedula}:')
            self.stdout.write(f'   - ID: {user_with_cedula.id}')
            self.stdout.write(f'   - Nombre: {user_with_cedula.nombre_completo}')
            self.stdout.write(f'   - Email: {user_with_cedula.correo}')
            self.stdout.write(f'   - Username: {user_with_cedula.username}')
            self.stdout.write(f'   - Rol: {user_with_cedula.rol}')
            self.stdout.write(f'   - Activo: {user_with_cedula.is_active}')

            # Verificar si tiene perfil
            if user_with_cedula.rol == 'estudiante':
                if hasattr(user_with_cedula, 'student_profile'):
                    self.stdout.write(f'   ✅ Tiene perfil de estudiante')
                else:
                    self.stdout.write(f'   ❌ NO tiene perfil de estudiante')

            elif user_with_cedula.rol == 'docente':
                if hasattr(user_with_cedula, 'teacher_profile'):
                    self.stdout.write(f'   ✅ Tiene perfil de docente')
                else:
                    self.stdout.write(f'   ❌ NO tiene perfil de docente')

            self.stdout.write('')

            # Verificar si este usuario puede ser usado para pruebas
            if user_with_cedula.rol == 'estudiante' and hasattr(user_with_cedula, 'student_profile'):
                self.stdout.write(self.style.SUCCESS(f'✅ ESTE USUARIO PUEDE USARSE PARA PRUEBAS:'))
                self.stdout.write(f'   📧 Email: {user_with_cedula.correo}')
                self.stdout.write(f'   🔑 Contraseña: Usar la contraseña que configuraste')
                self.stdout.write(f'   🎓 Rol: {user_with_cedula.rol}')
            else:
                self.stdout.write(self.style.WARNING(f'⚠️ Este usuario necesita corrección'))

        except User.DoesNotExist:
            self.stdout.write(f'❌ No se encontró usuario con cédula {problematic_cedula}')

        self.stdout.write('')

        # Mostrar todos los usuarios estudiantes
        estudiantes = User.objects.filter(rol='estudiante')
        self.stdout.write(f'👨‍🎓 ESTUDIANTES EN LA BASE DE DATOS ({estudiantes.count()}):')

        for i, estudiante in enumerate(estudiantes, 1):
            self.stdout.write(f'   {i}. {estudiante.nombre_completo} ({estudiante.correo})')
            self.stdout.write(f'      - Rol: {estudiante.rol}')
            self.stdout.write(f'      - Activo: {estudiante.is_active}')

            if hasattr(estudiante, 'student_profile'):
                self.stdout.write(f'      - ✅ Tiene perfil de estudiante')
            else:
                self.stdout.write(f'      - ❌ NO tiene perfil de estudiante')
            self.stdout.write('')

        # Recomendaciones
        self.stdout.write('💡 RECOMENDACIONES:')

        estudiantes_validos = []
        for estudiante in estudiantes:
            if estudiante.is_active and hasattr(estudiante, 'student_profile'):
                estudiantes_validos.append(estudiante)

        if estudiantes_validos:
            self.stdout.write(f'✅ Tienes {len(estudiantes_validos)} estudiante(s) válido(s) para pruebas:')
            for estudiante in estudiantes_validos:
                self.stdout.write(f'   📧 {estudiante.correo}')
        else:
            self.stdout.write('❌ No hay estudiantes válidos. Necesitas crear uno.')

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('✅ Verificación completada'))