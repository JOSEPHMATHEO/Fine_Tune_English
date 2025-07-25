from django.db import models
from django.core.exceptions import ValidationError

class Task(models.Model):
    TASK_TYPES = (
        ('assignment', 'Tarea'),
        ('quiz', 'Quiz'),
        ('project', 'Proyecto'),
        ('reading', 'Lectura'),
        ('exercise', 'Ejercicio'),
    )

    PRIORITY_LEVELS = (
        ('low', 'Baja'),
        ('medium', 'Media'),
        ('high', 'Alta'),
    )

    title = models.CharField(max_length=200)
    description = models.TextField()
    task_type = models.CharField(max_length=20, choices=TASK_TYPES)
    course_group = models.ForeignKey('courses.CourseGroup', on_delete=models.CASCADE)
    due_date = models.DateTimeField()
    priority = models.CharField(max_length=10, choices=PRIORITY_LEVELS, default='medium')
    max_score = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    instructions = models.TextField(null=True, blank=True)
    attachments = models.FileField(upload_to='task_attachments/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} - {self.course_group}"

    def clean(self):
        """Validación personalizada"""
        if self.max_score and self.max_score <= 0:
            raise ValidationError('La puntuación máxima debe ser mayor que 0')

class TaskSubmission(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pendiente'),
        ('submitted', 'Entregada'),
        ('graded', 'Calificada'),
        ('late', 'Tardía'),
    )

    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='submissions')
    student = models.ForeignKey('users.StudentProfile', on_delete=models.CASCADE)
    submission_text = models.TextField(null=True, blank=True)
    attachment = models.FileField(upload_to='submissions/', null=True, blank=True)
    submitted_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    score = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    feedback = models.TextField(null=True, blank=True)
    graded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ['task', 'student']

    def __str__(self):
        return f"{self.student.user.get_full_name()} - {self.task.title}"

    @property
    def percentage(self):
        """Calcular porcentaje de manera segura"""
        if self.score and self.task.max_score and float(self.task.max_score) > 0:
            return (float(self.score) / float(self.task.max_score)) * 100
        return 0.0

    def clean(self):
        """Validación personalizada"""
        if self.score and self.task.max_score and self.score > self.task.max_score:
            raise ValidationError('La puntuación no puede ser mayor que la puntuación máxima de la tarea')