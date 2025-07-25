from django.db import models

class ServiceCategory(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50)  # Icon name for frontend
    color = models.CharField(max_length=7, default='#3B82F6')
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Service Categories"

    def __str__(self):
        return self.name

class Service(models.Model):
    SERVICE_TYPES = (
        ('certificate', 'Certificado'),
        ('virtual_class', 'Clase Virtual'),
        ('tutoring', 'Tutoría'),
        ('library', 'Biblioteca Digital'),
        ('evaluation', 'Evaluación'),
        ('other', 'Otro'),
    )

    STATUS_CHOICES = (
        ('available', 'Disponible'),
        ('coming_soon', 'Próximamente'),
        ('maintenance', 'Mantenimiento'),
        ('disabled', 'Deshabilitado'),
    )

    name = models.CharField(max_length=100)
    description = models.TextField()
    service_type = models.CharField(max_length=20, choices=SERVICE_TYPES)
    category = models.ForeignKey(ServiceCategory, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    url = models.URLField(null=True, blank=True)  # For external services like Zoom
    instructions = models.TextField(null=True, blank=True)
    icon = models.CharField(max_length=50)
    color = models.CharField(max_length=7, default='#3B82F6')
    is_premium = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class ServiceRequest(models.Model):
    REQUEST_STATUS = (
        ('pending', 'Pendiente'),
        ('processing', 'Procesando'),
        ('completed', 'Completada'),
        ('cancelled', 'Cancelada'),
    )

    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=REQUEST_STATUS, default='pending')
    request_data = models.JSONField(default=dict)  # Store additional request data
    response_data = models.JSONField(default=dict)  # Store response/result data
    requested_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.service.name}"

class Certificate(models.Model):
    CERTIFICATE_TYPES = (
        ('completion', 'Finalización de Curso'),
        ('achievement', 'Logro Específico'),
        ('participation', 'Participación'),
    )

    student = models.ForeignKey('users.StudentProfile', on_delete=models.CASCADE)
    certificate_type = models.CharField(max_length=20, choices=CERTIFICATE_TYPES)
    course_name = models.CharField(max_length=100)
    issue_date = models.DateField(auto_now_add=True)
    certificate_id = models.CharField(max_length=50, unique=True)
    pdf_file = models.FileField(upload_to='certificates/', null=True, blank=True)
    is_valid = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.student.user.get_full_name()} - {self.course_name}"