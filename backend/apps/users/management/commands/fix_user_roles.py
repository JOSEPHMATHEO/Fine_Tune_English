from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from apps.users.models import User, StudentProfile, TeacherProfile
from datetime import datetime

class Command(BaseCommand):
    help = 'Corregir roles de usuarios y crear perfiles faltantes'

    def add_arguments(self, parser):
        parser.add_argument('--create-test-student', action='store_true', help='Crear estudiante de prueba')
        parser.add_argument('--fix-existing', action='store_true', help='Corregir usuarios existentes')

    def handle(self, *args, **options):
        self.stdout.write('🔧 CORRIGIENDO ROLES Y PERFILES DE USUARIOS...')
        self.stdout.write('=' * 60)

        if options['create_test_student']:
            self._create_test_student()

        if options['fix_existing']:
            self._fix_existing_users()

        if not options['create_test_student'] and not options['fix_existing']:
            self.stdout.write('Opciones disponibles:')
            self.stdout.write('  --create-test-student: Crear estudiante de prueba')
            self.stdout.write('  --fix-existing: Corregir usuarios existentes')

    def _create_test_student(self):
        self.stdout.write('👨‍🎓 Creando estudiante de prueba...')

        # Verificar si ya existe
        if User.objects.filter(correo='estudiante.test@finetuneenglish.com').exists():
            self.stdout.write(self.style.WARNING('⚠️ El estudiante de prueba ya existe'))
            return

        # Buscar una cédula única
        cedula_base = '9999999999'
        cedula_counter = 0
        while User.objects.filter(cedula=cedula_base).exists():
            cedula_counter += 1
            cedula_base = f'999999999{cedula_counter}'
            if cedula_counter > 9:
                cedula_base = f'99999999{cedula_counter}'

        self.stdout.write(f'📝 Usando cédula única: {cedula_base}')

        try:
            # Crear usuario estudiante
            student_user = User.objects.create(
                username='estudiante.test',
                correo='estudiante.test@finetuneenglish.com',
                nombre_completo='Estudiante de Prueba',
                cedula=cedula_base,
                telefono='0999999999',
                rol='estudiante',
                password=make_password('password123'),
                is_active=True
            )

            # Crear perfil de estudiante
            StudentProfile.objects.create(
                user=student_user,
                nivel_estudio='B1',
                fecha_nacimiento=datetime(1995, 5, 15).date(),
                genero='Masculino',
                estado_civil='Soltero',
                parroquia='Centro',
                origen_ingresos='Trabajo'
            )

            self.stdout.write(self.style.SUCCESS(f'✅ Estudiante de prueba creado exitosamente:'))
            self.stdout.write(f'   📧 Email: estudiante.test@finetuneenglish.com')
            self.stdout.write(f'   🔑 Contraseña: password123')
            self.stdout.write(f'   👤 Nombre: Estudiante de Prueba')
            self.stdout.write(f'   🎓 Rol: estudiante')
            self.stdout.write(f'   🆔 Cédula: {cedula_base}')

        except Exception as e:
            self.stdout.write(self.style.ERROR(f'❌ Error creando estudiante: {e}'))

    def _fix_existing_users(self):
        self.stdout.write('🔧 Corrigiendo usuarios existentes...')

        # Buscar usuarios con rol estudiante sin perfil
        estudiantes_sin_perfil = []
        for user in User.objects.filter(rol='estudiante'):
            if not hasattr(user, 'student_profile'):
                estudiantes_sin_perfil.append(user)

        if estudiantes_sin_perfil:
            self.stdout.write(f'📚 Encontrados {len(estudiantes_sin_perfil)} estudiantes sin perfil')

            for user in estudiantes_sin_perfil:
                try:
                    StudentProfile.objects.create(
                        user=user,
                        nivel_estudio='A1',
                        fecha_nacimiento=datetime(1990, 1, 1).date(),
                        genero='No especificado',
                        estado_civil='No especificado',
                        parroquia='No especificado',
                        origen_ingresos='No especificado'
                    )
                    self.stdout.write(f'   ✅ Perfil creado para: {user.correo}')
                except Exception as e:
                    self.stdout.write(f'   ❌ Error creando perfil para {user.correo}: {e}')

        # Buscar usuarios con rol docente sin perfil
        docentes_sin_perfil = []
        for user in User.objects.filter(rol='docente'):
            if not hasattr(user, 'teacher_profile'):
                docentes_sin_perfil.append(user)

        if docentes_sin_perfil:
            self.stdout.write(f'🏫 Encontrados {len(docentes_sin_perfil)} docentes sin perfil')

            for user in docentes_sin_perfil:
                try:
                    TeacherProfile.objects.create(
                        user=user,
                        especialization='English Teaching',
                        hire_date=datetime.now().date()
                    )
                    self.stdout.write(f'   ✅ Perfil creado para: {user.correo}')
                except Exception as e:
                    self.stdout.write(f'   ❌ Error creando perfil para {user.correo}: {e}')

        self.stdout.write(self.style.SUCCESS('✅ Corrección completada'))