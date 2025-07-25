from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import datetime, timedelta
import random
from django.contrib.auth.hashers import make_password

from apps.users.models import User, StudentProfile, TeacherProfile
from apps.courses.models import Course, Classroom, Period, CourseGroup, Enrollment, Schedule, Grade
from apps.news.models import News, NewsCategory
from apps.tasks.models import Task, TaskSubmission
from apps.services.models import Service, ServiceCategory, ServiceRequest
from apps.attendance.models import AttendanceSession, Attendance, AttendanceSummary
from apps.notifications.models import Notification, NotificationType, NotificationPreference

class Command(BaseCommand):
    help = 'Populate database with sample data'

    def handle(self, *args, **options):
        self.stdout.write('🚀 Poblando base de datos con datos completos...')

        # Crear categorías de noticias
        self.stdout.write('📰 Creando categorías de noticias...')
        news_categories = [
            {'name': 'Académico', 'description': 'Noticias académicas', 'color': '#2563EB'},
            {'name': 'Eventos', 'description': 'Eventos institucionales', 'color': '#10B981'},
            {'name': 'Anuncios', 'description': 'Anuncios generales', 'color': '#F59E0B'},
            {'name': 'Deportes', 'description': 'Actividades deportivas', 'color': '#8B5CF6'},
            {'name': 'Cultura', 'description': 'Actividades culturales', 'color': '#EF4444'},
        ]

        for cat_data in news_categories:
            category, created = NewsCategory.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            if created:
                self.stdout.write(f'✅ Categoría creada: {category.name}')

        # Crear tipos de notificación
        self.stdout.write('🔔 Creando tipos de notificación...')
        notification_types = [
            {'name': 'Tarea', 'description': 'Notificaciones de tareas', 'icon': 'assignment', 'color': '#2563EB'},
            {'name': 'Clase', 'description': 'Notificaciones de clases', 'icon': 'schedule', 'color': '#10B981'},
            {'name': 'Evaluación', 'description': 'Notificaciones de evaluaciones', 'icon': 'quiz', 'color': '#F59E0B'},
            {'name': 'Anuncio', 'description': 'Anuncios generales', 'icon': 'info', 'color': '#8B5CF6'},
        ]

        for nt_data in notification_types:
            nt, created = NotificationType.objects.get_or_create(
                name=nt_data['name'],
                defaults=nt_data
            )
            if created:
                self.stdout.write(f'✅ Tipo de notificación creado: {nt.name}')

        # Crear aulas
        self.stdout.write('🏫 Creando aulas...')
        classrooms = [
            {'name': 'Aula 101', 'capacity': 25, 'location': 'Primer Piso', 'equipment': 'Proyector, Audio'},
            {'name': 'Aula 201', 'capacity': 30, 'location': 'Segundo Piso', 'equipment': 'Proyector, Pizarra Digital'},
            {'name': 'Aula Virtual 1', 'capacity': 50, 'location': 'Online', 'equipment': 'Zoom, Recursos Digitales'},
            {'name': 'Laboratorio', 'capacity': 20, 'location': 'Primer Piso', 'equipment': 'Computadoras, Audio'},
        ]

        for classroom_data in classrooms:
            classroom, created = Classroom.objects.get_or_create(
                name=classroom_data['name'],
                defaults=classroom_data
            )
            if created:
                self.stdout.write(f'✅ Aula creada: {classroom.name}')

        # Crear períodos
        self.stdout.write('📅 Creando períodos...')
        current_year = timezone.now().year
        period, created = Period.objects.get_or_create(
            name=f'Período {current_year}',
            defaults={
                'start_date': datetime(current_year, 1, 1).date(),
                'end_date': datetime(current_year, 12, 31).date(),
                'is_active': True
            }
        )
        if created:
            self.stdout.write(f'✅ Período creado: {period.name}')

        # Crear cursos
        self.stdout.write('📚 Creando cursos...')
        courses = [
            {'name': 'Inglés Básico A1', 'code': 'ENG-A1', 'level': 'A1', 'modality': 'presencial'},
            {'name': 'Inglés Básico A2', 'code': 'ENG-A2', 'level': 'A2', 'modality': 'presencial'},
            {'name': 'Inglés Intermedio B1', 'code': 'ENG-B1', 'level': 'B1', 'modality': 'hibrido'},
            {'name': 'Inglés Intermedio B2', 'code': 'ENG-B2', 'level': 'B2', 'modality': 'virtual'},
            {'name': 'Inglés Avanzado C1', 'code': 'ENG-C1', 'level': 'C1', 'modality': 'presencial'},
        ]

        for course_data in courses:
            course, created = Course.objects.get_or_create(
                code=course_data['code'],
                defaults={
                    'name': course_data['name'],
                    'description': f'Curso de {course_data["name"]} - Desarrolla tus habilidades en inglés',
                    'level': course_data['level'],
                    'modality': course_data['modality'],
                    'duration_weeks': 16,
                    'hours_per_week': 6
                }
            )
            if created:
                self.stdout.write(f'✅ Curso creado: {course.name}')

        # Crear usuarios docentes
        self.stdout.write('👨‍🏫 Creando docentes...')
        teachers_data = [
            {
                'username': 'sarah.johnson',
                'correo': 'sarah.johnson@finetuneenglish.com',
                'nombre_completo': 'Sarah Johnson',
                'cedula': '1234567890',
                'telefono': '0999999999',
                'especialization': 'English Language Teaching',
                'hire_date': datetime(2020, 1, 15).date()
            },
            {
                'username': 'michael.brown',
                'correo': 'michael.brown@finetuneenglish.com',
                'nombre_completo': 'Michael Brown',
                'cedula': '1234567891',
                'telefono': '0999999998',
                'especialization': 'Applied Linguistics',
                'hire_date': datetime(2019, 8, 20).date()
            },
            {
                'username': 'emma.davis',
                'correo': 'emma.davis@finetuneenglish.com',
                'nombre_completo': 'Emma Davis',
                'cedula': '1234567892',
                'telefono': '0999999997',
                'especialization': 'TESOL Certification',
                'hire_date': datetime(2021, 3, 10).date()
            }
        ]

        for teacher_data in teachers_data:
            if not User.objects.filter(correo=teacher_data['correo']).exists():
                teacher_user = User.objects.create(
                    username=teacher_data['username'],
                    correo=teacher_data['correo'],
                    nombre_completo=teacher_data['nombre_completo'],
                    cedula=teacher_data['cedula'],
                    telefono=teacher_data['telefono'],
                    rol='docente',
                    password=make_password('password123'),
                    is_active=True
                )

                TeacherProfile.objects.create(
                    user=teacher_user,
                    especialization=teacher_data['especialization'],
                    hire_date=teacher_data['hire_date']
                )
                self.stdout.write(f'✅ Docente creado: {teacher_user.nombre_completo}')

        # Crear usuarios estudiantes
        self.stdout.write('👨‍🎓 Creando estudiantes...')
        students_data = [
            {
                'username': 'luis.morales',
                'correo': 'luis.morales@student.com',
                'nombre_completo': 'Luis Morales',
                'cedula': '0987654321',
                'telefono': '0988888888',
                'nivel_estudio': 'B1',
                'fecha_nacimiento': datetime(1995, 5, 15).date(),
                'genero': 'Masculino',
                'estado_civil': 'Soltero',
                'parroquia': 'Centro',
                'origen_ingresos': 'Trabajo'
            },
            {
                'username': 'maria.garcia',
                'correo': 'maria.garcia@student.com',
                'nombre_completo': 'María García',
                'cedula': '0987654322',
                'telefono': '0988888887',
                'nivel_estudio': 'A2',
                'fecha_nacimiento': datetime(1998, 3, 22).date(),
                'genero': 'Femenino',
                'estado_civil': 'Soltera',
                'parroquia': 'Norte',
                'origen_ingresos': 'Estudiante'
            },
            {
                'username': 'carlos.rodriguez',
                'correo': 'carlos.rodriguez@student.com',
                'nombre_completo': 'Carlos Rodríguez',
                'cedula': '0987654323',
                'telefono': '0988888886',
                'nivel_estudio': 'B2',
                'fecha_nacimiento': datetime(1992, 8, 10).date(),
                'genero': 'Masculino',
                'estado_civil': 'Casado',
                'parroquia': 'Sur',
                'origen_ingresos': 'Trabajo'
            },
            {
                'username': 'ana.lopez',
                'correo': 'ana.lopez@student.com',
                'nombre_completo': 'Ana López',
                'cedula': '0987654324',
                'telefono': '0988888885',
                'nivel_estudio': 'A1',
                'fecha_nacimiento': datetime(2000, 12, 5).date(),
                'genero': 'Femenino',
                'estado_civil': 'Soltera',
                'parroquia': 'Este',
                'origen_ingresos': 'Estudiante'
            }
        ]

        for student_data in students_data:
            if not User.objects.filter(correo=student_data['correo']).exists():
                student_user = User.objects.create(
                    username=student_data['username'],
                    correo=student_data['correo'],
                    nombre_completo=student_data['nombre_completo'],
                    cedula=student_data['cedula'],
                    telefono=student_data['telefono'],
                    rol='estudiante',
                    password=make_password('password123'),
                    is_active=True
                )

                StudentProfile.objects.create(
                    user=student_user,
                    nivel_estudio=student_data['nivel_estudio'],
                    fecha_nacimiento=student_data['fecha_nacimiento'],
                    genero=student_data['genero'],
                    estado_civil=student_data['estado_civil'],
                    parroquia=student_data['parroquia'],
                    origen_ingresos=student_data['origen_ingresos']
                )
                self.stdout.write(f'✅ Estudiante creado: {student_user.nombre_completo}')

        # Crear usuario administrador
        self.stdout.write('👨‍💼 Creando administrador...')
        if not User.objects.filter(correo='admin@finetuneenglish.com').exists():
            admin_user = User.objects.create(
                username='admin',
                correo='admin@finetuneenglish.com',
                nombre_completo='Administrador Sistema',
                cedula='1111111111',
                telefono='0999999990',
                rol='admin',
                password=make_password('admin123'),
                is_active=True,
                is_staff=True,
                is_superuser=True
            )
            self.stdout.write(f'✅ Administrador creado: {admin_user.nombre_completo}')

        # Crear grupos de curso
        self.stdout.write('👥 Creando grupos de curso...')
        teachers = TeacherProfile.objects.all()
        for i, course in enumerate(Course.objects.all()):
            teacher = teachers[i % len(teachers)] if teachers else None
            if teacher:
                course_group, created = CourseGroup.objects.get_or_create(
                    course=course,
                    period=period,
                    name='Grupo A',
                    defaults={
                        'teacher': teacher,
                        'max_students': 25
                    }
                )
                if created:
                    self.stdout.write(f'✅ Grupo creado: {course_group}')

        # Crear horarios
        self.stdout.write('⏰ Creando horarios...')
        days = [0, 2, 4]  # Lunes, Miércoles, Viernes
        subjects = ['Grammar Focus', 'Speaking Practice', 'Writing Skills']

        for course_group in CourseGroup.objects.all():
            for i, day in enumerate(days):
                schedule, created = Schedule.objects.get_or_create(
                    course_group=course_group,
                    day_of_week=day,
                    start_time='10:00',
                    defaults={
                        'end_time': '12:00',
                        'classroom': Classroom.objects.all()[i % Classroom.objects.count()],
                        'subject': subjects[i % len(subjects)]
                    }
                )
                if created:
                    self.stdout.write(f'✅ Horario creado: {schedule}')

        # Crear matrículas
        self.stdout.write('📝 Creando matrículas...')
        students = StudentProfile.objects.all()
        course_groups = CourseGroup.objects.all()

        for student in students:
            for course_group in course_groups[:2]:  # Matricular en 2 cursos
                enrollment, created = Enrollment.objects.get_or_create(
                    student=student,
                    course_group=course_group,
                    defaults={'is_active': True}
                )
                if created:
                    self.stdout.write(f'✅ Matrícula creada: {student.user.nombre_completo} en {course_group}')

        # Crear noticias COMPLETAS
        self.stdout.write('📰 Creando noticias completas...')
        admin_user = User.objects.filter(rol='admin').first()
        if not admin_user:
            admin_user = User.objects.filter(is_superuser=True).first()

        if admin_user:
            # Limpiar noticias existentes para evitar duplicados
            News.objects.all().delete()

            news_data = [
                {
                    'title': 'Bienvenidos al nuevo período académico 2024',
                    'summary': 'Iniciamos un nuevo período lleno de oportunidades de aprendizaje y crecimiento personal.',
                    'content': 'Estimados estudiantes, les damos la bienvenida al nuevo período académico 2024. Este semestre tenemos nuevas metodologías de enseñanza, recursos digitales actualizados y un equipo docente comprometido con su éxito. Esperamos que este sea un período de grandes logros y aprendizajes significativos. Nuestro objetivo es brindarles la mejor experiencia educativa posible.',
                    'category': NewsCategory.objects.get(name='Académico'),
                    'is_featured': True,
                },
                {
                    'title': 'Evento cultural: English Day 2024',
                    'summary': 'Celebraremos el día del inglés con actividades especiales, presentaciones y premios.',
                    'content': 'El próximo viernes 15 de marzo celebraremos nuestro tradicional English Day con presentaciones estudiantiles, juegos interactivos, concursos de pronunciación y actividades culturales. Habrá premios para los mejores participantes. ¡Los esperamos a todos para celebrar juntos el idioma inglés! Este evento es una oportunidad única para practicar el idioma en un ambiente divertido y relajado.',
                    'category': NewsCategory.objects.get(name='Eventos'),
                    'is_featured': True,
                },
                {
                    'title': 'Nuevos horarios de biblioteca digital disponibles',
                    'summary': 'La biblioteca digital estará disponible 24/7 con nuevos recursos y materiales.',
                    'content': 'Nos complace anunciar que nuestra biblioteca digital ahora está disponible las 24 horas del día, los 7 días de la semana. Hemos agregado más de 500 nuevos recursos incluyendo libros digitales, audiolibros, ejercicios interactivos y videos educativos. Accede desde cualquier dispositivo con tu cuenta estudiantil. Esta mejora representa nuestro compromiso con la educación continua.',
                    'category': NewsCategory.objects.get(name='Anuncios'),
                    'is_featured': True,
                },
                {
                    'title': 'Certificaciones internacionales disponibles',
                    'summary': 'Ahora puedes obtener certificaciones Cambridge y TOEFL a través de nuestra institución.',
                    'content': 'Estamos orgullosos de anunciar que Fine Tune English es ahora centro autorizado para certificaciones Cambridge English y TOEFL. Los estudiantes pueden registrarse para estos exámenes internacionales con descuentos especiales. Las fechas de examen están disponibles en secretaría académica. Estas certificaciones te abrirán puertas a nivel internacional.',
                    'category': NewsCategory.objects.get(name='Académico'),
                    'is_featured': True,
                },
                {
                    'title': 'Torneo de debate en inglés',
                    'summary': 'Participa en nuestro primer torneo de debate académico en inglés.',
                    'content': 'Invitamos a todos los estudiantes de nivel intermedio y avanzado a participar en nuestro primer torneo de debate en inglés. El evento se realizará el 20 de marzo y contará con premios para los mejores debatientes. Es una excelente oportunidad para mejorar tus habilidades de expresión oral y argumentación. Las inscripciones están abiertas hasta el 15 de marzo.',
                    'category': NewsCategory.objects.get(name='Deportes'),
                    'is_featured': True,
                },
                {
                    'title': 'Taller de escritura creativa en inglés',
                    'summary': 'Desarrolla tus habilidades de escritura con nuestro nuevo taller especializado.',
                    'content': 'Lanzamos un nuevo taller de escritura creativa en inglés dirigido por la profesora Emma Davis. El taller se enfoca en técnicas narrativas, desarrollo de personajes y construcción de tramas. Las clases serán los sábados de 9:00 AM a 11:00 AM. Cupos limitados a 15 estudiantes. Este taller es perfecto para quienes desean mejorar su expresión escrita de manera creativa.',
                    'category': NewsCategory.objects.get(name='Cultura'),
                    'is_featured': True,
                },
                {
                    'title': 'Intercambio cultural con estudiantes de Canadá',
                    'summary': 'Oportunidad única de intercambio virtual con estudiantes canadienses.',
                    'content': 'Hemos establecido una alianza con una institución educativa de Toronto, Canadá, para realizar intercambios culturales virtuales. Los estudiantes podrán participar en conversaciones con hablantes nativos, conocer sobre la cultura canadiense y practicar inglés en contextos reales. El programa inicia en abril y tendrá una duración de 8 semanas.',
                    'category': NewsCategory.objects.get(name='Eventos'),
                    'is_featured': False,
                },
                {
                    'title': 'Actualización del sistema de calificaciones',
                    'summary': 'Mejoras en la plataforma digital para consulta de notas y progreso académico.',
                    'content': 'Hemos actualizado nuestro sistema de calificaciones para ofrecer una mejor experiencia a estudiantes y padres de familia. Ahora pueden consultar calificaciones en tiempo real, ver el progreso detallado por habilidades y recibir notificaciones automáticas. La nueva plataforma estará disponible a partir del lunes 25 de marzo.',
                    'category': NewsCategory.objects.get(name='Anuncios'),
                    'is_featured': False,
                },
                {
                    'title': 'Conferencia magistral: El futuro del inglés en la era digital',
                    'summary': 'Conferencia con experto internacional sobre tendencias en enseñanza de idiomas.',
                    'content': 'El Dr. James Wilson, reconocido experto en lingüística aplicada de la Universidad de Oxford, ofrecerá una conferencia magistral sobre las tendencias futuras en la enseñanza del inglés. El evento será el 30 de marzo a las 7:00 PM en nuestro auditorio principal. Entrada libre para estudiantes y docentes. Una oportunidad única de aprender de un experto mundial.',
                    'category': NewsCategory.objects.get(name='Académico'),
                    'is_featured': False,
                },
                {
                    'title': 'Programa de voluntariado en inglés',
                    'summary': 'Únete a nuestro programa de voluntariado para enseñar inglés a la comunidad.',
                    'content': 'Lanzamos un programa de voluntariado donde nuestros estudiantes avanzados pueden enseñar inglés básico a miembros de la comunidad. Es una excelente oportunidad para practicar el idioma mientras ayudas a otros. El programa incluye capacitación pedagógica básica y certificado de participación. Las actividades se realizarán los fines de semana.',
                    'category': NewsCategory.objects.get(name='Cultura'),
                    'is_featured': False,
                }
            ]

            for i, news_item in enumerate(news_data):
                news = News.objects.create(
                    title=news_item['title'],
                    summary=news_item['summary'],
                    content=news_item['content'],
                    category=news_item['category'],
                    author=admin_user,
                    publication_date=timezone.now() - timedelta(days=random.randint(1, 30)),
                    is_published=True,
                    is_featured=news_item['is_featured'],
                    views_count=random.randint(10, 100)
                )
                self.stdout.write(f'✅ Noticia {i+1} creada: {news.title}')

        # Crear categorías de servicios
        self.stdout.write('🛠️ Creando categorías de servicios...')
        service_categories = [
            {'name': 'Académico', 'description': 'Servicios académicos', 'icon': 'school', 'color': '#2563EB'},
            {'name': 'Digital', 'description': 'Servicios digitales', 'icon': 'computer', 'color': '#10B981'},
            {'name': 'Certificación', 'description': 'Servicios de certificación', 'icon': 'card_membership', 'color': '#F59E0B'},
        ]

        for cat_data in service_categories:
            category, created = ServiceCategory.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            if created:
                self.stdout.write(f'✅ Categoría de servicio creada: {category.name}')

        # Crear servicios
        self.stdout.write('🎯 Creando servicios...')
        services_data = [
            {
                'name': 'Certificados Online',
                'description': 'Genera tu certificado de aprobación de curso al instante',
                'service_type': 'certificate',
                'category': ServiceCategory.objects.get(name='Certificación'),
                'instructions': 'Completa tu curso con calificación mínima de 70% para generar tu certificado.',
                'icon': 'card_membership',
                'color': '#10B981',
                'status': 'available'
            },
            {
                'name': 'Fine Online - Clases Virtuales',
                'description': 'Accede a clases en vivo por Zoom con profesores especializados',
                'service_type': 'virtual_class',
                'category': ServiceCategory.objects.get(name='Digital'),
                'url': 'https://zoom.us/j/1234567890',
                'instructions': 'Únete a las clases virtuales usando el enlace proporcionado.',
                'icon': 'video_call',
                'color': '#2563EB',
                'status': 'available'
            },
            {
                'name': 'Biblioteca Digital',
                'description': 'Acceso a más de 1000 recursos educativos disponibles 24/7',
                'service_type': 'library',
                'category': ServiceCategory.objects.get(name='Digital'),
                'instructions': 'Accede con tu cuenta estudiantil a todos los recursos digitales.',
                'icon': 'library_books',
                'color': '#8B5CF6',
                'status': 'available'
            },
            {
                'name': 'Tutorías Personalizadas',
                'description': 'Sesiones individuales con profesores especializados',
                'service_type': 'tutoring',
                'category': ServiceCategory.objects.get(name='Académico'),
                'instructions': 'Agenda tu sesión de tutoría a través de secretaría académica.',
                'icon': 'person_pin',
                'color': '#F59E0B',
                'status': 'available'
            }
        ]

        for service_data in services_data:
            service, created = Service.objects.get_or_create(
                name=service_data['name'],
                defaults=service_data
            )
            if created:
                self.stdout.write(f'✅ Servicio creado: {service.name}')

        # Crear tareas
        self.stdout.write('📋 Creando tareas...')
        course_groups = CourseGroup.objects.all()
        tasks_data = [
            {
                'title': 'Grammar Exercise - Present Perfect',
                'description': 'Complete los ejercicios del capítulo 5 sobre Present Perfect. Incluye ejercicios de completar oraciones y traducción.',
                'task_type': 'assignment',
                'priority': 'medium',
                'max_score': 20.00,
                'instructions': 'Lea el material del capítulo 5 y complete todos los ejercicios. Envíe sus respuestas antes de la fecha límite.'
            },
            {
                'title': 'Speaking Practice - Job Interview',
                'description': 'Prepare una presentación de 5 minutos simulando una entrevista de trabajo en inglés.',
                'task_type': 'project',
                'priority': 'high',
                'max_score': 25.00,
                'instructions': 'Prepare respuestas para preguntas comunes de entrevistas. Practique pronunciación y fluidez.'
            },
            {
                'title': 'Reading Comprehension Quiz',
                'description': 'Quiz sobre el texto "Technology in Education" - 10 preguntas de comprensión lectora.',
                'task_type': 'quiz',
                'priority': 'medium',
                'max_score': 15.00,
                'instructions': 'Lea cuidadosamente el texto y responda las preguntas de comprensión.'
            }
        ]

        for course_group in course_groups:
            for task_data in tasks_data:
                task, created = Task.objects.get_or_create(
                    title=task_data['title'],
                    course_group=course_group,
                    defaults={
                        'description': task_data['description'],
                        'task_type': task_data['task_type'],
                        'due_date': timezone.now() + timedelta(days=random.randint(3, 14)),
                        'priority': task_data['priority'],
                        'max_score': task_data['max_score'],
                        'instructions': task_data['instructions'],
                        'is_active': True
                    }
                )
                if created:
                    self.stdout.write(f'✅ Tarea creada: {task.title} para {course_group}')

        # Crear notificaciones
        self.stdout.write('🔔 Creando notificaciones...')
        students = User.objects.filter(rol='estudiante')
        notification_types = NotificationType.objects.all()

        notifications_data = [
            {
                'title': 'Nueva tarea asignada',
                'message': 'Se ha asignado una nueva tarea: Grammar Exercise - Present Perfect',
                'priority': 'medium',
                'type_name': 'Tarea'
            },
            {
                'title': 'Recordatorio de clase',
                'message': 'Tu clase de Speaking Practice comienza en 30 minutos',
                'priority': 'high',
                'type_name': 'Clase'
            },
            {
                'title': 'Evaluación próxima',
                'message': 'Tienes un quiz de Reading Comprehension programado para mañana',
                'priority': 'medium',
                'type_name': 'Evaluación'
            },
            {
                'title': 'Nuevo material disponible',
                'message': 'Se ha agregado nuevo material de estudio a la biblioteca digital',
                'priority': 'low',
                'type_name': 'Anuncio'
            }
        ]

        for student in students:
            for notif_data in notifications_data:
                notification_type = notification_types.filter(name=notif_data['type_name']).first()
                if notification_type:
                    notification, created = Notification.objects.get_or_create(
                        recipient=student,
                        title=notif_data['title'],
                        notification_type=notification_type,
                        defaults={
                            'message': notif_data['message'],
                            'priority': notif_data['priority'],
                            'is_read': random.choice([True, False]),
                            'created_at': timezone.now() - timedelta(hours=random.randint(1, 48))
                        }
                    )
                    if created:
                        self.stdout.write(f'✅ Notificación creada para {student.nombre_completo}')

        # Crear preferencias de notificación
        self.stdout.write('⚙️ Creando preferencias de notificación...')
        for user in User.objects.all():
            pref, created = NotificationPreference.objects.get_or_create(
                user=user,
                defaults={
                    'email_notifications': True,
                    'push_notifications': True,
                    'sms_notifications': False
                }
            )
            if created:
                pref.notification_types.set(NotificationType.objects.all())
                self.stdout.write(f'✅ Preferencias creadas para {user.nombre_completo}')

        # Verificar noticias creadas
        total_news = News.objects.count()
        published_news = News.objects.filter(is_published=True).count()
        featured_news = News.objects.filter(is_featured=True).count()

        self.stdout.write(self.style.SUCCESS('🎉 ¡Base de datos poblada exitosamente!'))
        self.stdout.write(self.style.SUCCESS(''))
        self.stdout.write(self.style.SUCCESS('📊 ESTADÍSTICAS:'))
        self.stdout.write(self.style.SUCCESS(f'   📰 Total noticias: {total_news}'))
        self.stdout.write(self.style.SUCCESS(f'   ✅ Noticias publicadas: {published_news}'))
        self.stdout.write(self.style.SUCCESS(f'   ⭐ Noticias destacadas: {featured_news}'))
        self.stdout.write(self.style.SUCCESS(''))
        self.stdout.write(self.style.SUCCESS('👥 Usuarios creados:'))
        self.stdout.write(self.style.SUCCESS('   📧 Admin: admin@finetuneenglish.com / admin123'))
        self.stdout.write(self.style.SUCCESS('   👨‍🏫 Docente: sarah.johnson@finetuneenglish.com / password123'))
        self.stdout.write(self.style.SUCCESS('   👨‍🎓 Estudiante: luis.morales@student.com / password123'))
        self.stdout.write(self.style.SUCCESS(''))
        self.stdout.write(self.style.SUCCESS('🚀 ¡La aplicación está lista para usar!'))