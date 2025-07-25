from django.db import models
from django.core.exceptions import ValidationError

class Course(models.Model):
    MODALITIES = (
        ('presencial', 'Presencial'),
        ('virtual', 'Virtual'),
        ('hibrido', 'Híbrido'),
    )

    LEVELS = (
        ('A1', 'Principiante A1'),
        ('A2', 'Principiante A2'),
        ('B1', 'Intermedio B1'),
        ('B2', 'Intermedio B2'),
        ('C1', 'Avanzado C1'),
        ('C2', 'Avanzado C2'),
    )

    name = models.CharField(max_length=100)
    code = models.CharField(max_length=20, unique=True)
    description = models.TextField()
    level = models.CharField(max_length=2, choices=LEVELS)
    modality = models.CharField(max_length=20, choices=MODALITIES)
    duration_weeks = models.IntegerField()
    hours_per_week = models.IntegerField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.code}"

class Classroom(models.Model):
    name = models.CharField(max_length=50)
    capacity = models.IntegerField()
    location = models.CharField(max_length=100)
    equipment = models.TextField(null=True, blank=True)

    def __str__(self):
        return self.name

class Period(models.Model):
    name = models.CharField(max_length=50)
    start_date = models.DateField()
    end_date = models.DateField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

class CourseGroup(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='groups')
    period = models.ForeignKey(Period, on_delete=models.CASCADE)
    teacher = models.ForeignKey('users.TeacherProfile', on_delete=models.CASCADE)
    name = models.CharField(max_length=50)  # e.g., "Grupo A", "Grupo B"
    max_students = models.IntegerField(default=20)

    class Meta:
        unique_together = ['course', 'period', 'name']

    def __str__(self):
        return f"{self.course.name} - {self.name} ({self.period.name})"

class Enrollment(models.Model):
    student = models.ForeignKey('users.StudentProfile', on_delete=models.CASCADE)
    course_group = models.ForeignKey(CourseGroup, on_delete=models.CASCADE)
    enrollment_date = models.DateField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ['student', 'course_group']

    def __str__(self):
        return f"{self.student.user.get_full_name()} - {self.course_group}"

class Schedule(models.Model):
    DAYS_OF_WEEK = (
        (0, 'Lunes'),
        (1, 'Martes'),
        (2, 'Miércoles'),
        (3, 'Jueves'),
        (4, 'Viernes'),
        (5, 'Sábado'),
        (6, 'Domingo'),
    )

    course_group = models.ForeignKey(CourseGroup, on_delete=models.CASCADE, related_name='schedules')
    day_of_week = models.IntegerField(choices=DAYS_OF_WEEK)
    start_time = models.TimeField()
    end_time = models.TimeField()
    classroom = models.ForeignKey(Classroom, on_delete=models.CASCADE)
    subject = models.CharField(max_length=100)  # e.g., "Grammar Focus", "Speaking Practice"

    class Meta:
        unique_together = ['course_group', 'day_of_week', 'start_time']

    def __str__(self):
        return f"{self.course_group} - {self.get_day_of_week_display()} {self.start_time}"

class Grade(models.Model):
    GRADE_TYPES = (
        ('quiz', 'Quiz'),
        ('exam', 'Examen'),
        ('assignment', 'Tarea'),
        ('participation', 'Participación'),
        ('project', 'Proyecto'),
    )

    enrollment = models.ForeignKey(Enrollment, on_delete=models.CASCADE, related_name='grades')
    grade_type = models.CharField(max_length=20, choices=GRADE_TYPES)
    subject = models.CharField(max_length=100)
    obtained_score = models.DecimalField(max_digits=5, decimal_places=2)
    max_score = models.DecimalField(max_digits=5, decimal_places=2)
    date = models.DateField()
    comments = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"{self.enrollment.student.user.get_full_name()} - {self.subject}: {self.obtained_score}/{self.max_score}"

    @property
    def percentage(self):
        """Calcular porcentaje de manera segura"""
        if self.max_score and float(self.max_score) > 0:
            return (float(self.obtained_score) / float(self.max_score)) * 100
        return 0.0

    def clean(self):
        """Validación personalizada"""
        if self.obtained_score and self.max_score and self.obtained_score > self.max_score:
            raise ValidationError('La puntuación obtenida no puede ser mayor que la puntuación máxima')