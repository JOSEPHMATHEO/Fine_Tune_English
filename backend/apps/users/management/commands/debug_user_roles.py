from django.core.management.base import BaseCommand
from apps.users.models import User, StudentProfile, TeacherProfile

class Command(BaseCommand):
    help = 'Verificar roles y perfiles de usuarios en la base de datos'

    def handle(self, *args, **options):
        self.stdout.write('🔍 VERIFICANDO ROLES Y PERFILES DE USUARIOS...')
        self.stdout.write('=' * 60)

        # Obtener todos los usuarios
        users = User.objects.all().order_by('id')
        total_users = users.count()

        self.stdout.write(f'📊 Total de usuarios en BD: {total_users}')
        self.stdout.write('')

        if total_users == 0:
            self.stdout.write(self.style.WARNING('⚠️ No hay usuarios en la base de datos'))
            return

        # Verificar cada usuario
        for i, user in enumerate(users, 1):
            self.stdout.write(f'👤 USUARIO {i}:')
            self.stdout.write(f'   - ID: {user.id}')
            self.stdout.write(f'   - Nombre: {user.nombre_completo}')
            self.stdout.write(f'   - Email: {user.correo}')
            self.stdout.write(f'   - Username: {user.username}')
            self.stdout.write(f'   - Rol: {user.rol}')
            self.stdout.write(f'   - Activo: {user.is_active}')
            self.stdout.write(f'   - Staff: {user.is_staff}')
            self.stdout.write(f'   - Superuser: {user.is_superuser}')

            # Verificar perfiles específicos
            if user.rol == 'estudiante':
                try:
                    student_profile = user.student_profile
                    self.stdout.write(f'   ✅ Perfil de estudiante: SÍ')
                    self.stdout.write(f'      - Nivel: {student_profile.nivel_estudio}')
                    self.stdout.write(f'      - Género: {student_profile.genero}')
                except:
                    self.stdout.write(f'   ❌ Perfil de estudiante: NO')

            elif user.rol == 'docente':
                try:
                    teacher_profile = user.teacher_profile
                    self.stdout.write(f'   ✅ Perfil de docente: SÍ')
                    self.stdout.write(f'      - Especialización: {teacher_profile.especialization}')
                except:
                    self.stdout.write(f'   ❌ Perfil de docente: NO')

            self.stdout.write('')

        # Estadísticas por rol
        self.stdout.write('📈 ESTADÍSTICAS POR ROL:')
        estudiantes = users.filter(rol='estudiante').count()
        docentes = users.filter(rol='docente').count()
        admins = users.filter(rol='admin').count()

        self.stdout.write(f'   👨‍🎓 Estudiantes: {estudiantes}')
        self.stdout.write(f'   👨‍🏫 Docentes: {docentes}')
        self.stdout.write(f'   👨‍💼 Administradores: {admins}')
        self.stdout.write('')

        # Verificar perfiles huérfanos
        student_profiles = StudentProfile.objects.count()
        teacher_profiles = TeacherProfile.objects.count()

        self.stdout.write('🔗 VERIFICACIÓN DE PERFILES:')
        self.stdout.write(f'   📚 Perfiles de estudiante en BD: {student_profiles}')
        self.stdout.write(f'   🏫 Perfiles de docente en BD: {teacher_profiles}')

        # Verificar inconsistencias
        estudiantes_sin_perfil = 0
        docentes_sin_perfil = 0

        for user in users.filter(rol='estudiante'):
            if not hasattr(user, 'student_profile'):
                estudiantes_sin_perfil += 1

        for user in users.filter(rol='docente'):
            if not hasattr(user, 'teacher_profile'):
                docentes_sin_perfil += 1

        if estudiantes_sin_perfil > 0:
            self.stdout.write(self.style.WARNING(f'⚠️ Estudiantes sin perfil: {estudiantes_sin_perfil}'))

        if docentes_sin_perfil > 0:
            self.stdout.write(self.style.WARNING(f'⚠️ Docentes sin perfil: {docentes_sin_perfil}'))

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('✅ Verificación completada'))