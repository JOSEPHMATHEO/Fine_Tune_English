from django.db import models
from django.core.exceptions import ValidationError

class AttendanceSession(models.Model):
    course_group = models.ForeignKey('courses.CourseGroup', on_delete=models.CASCADE)
    schedule = models.ForeignKey('courses.Schedule', on_delete=models.CASCADE)
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    topic = models.CharField(max_length=200, null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['course_group', 'schedule', 'date']

    def __str__(self):
        return f"{self.course_group} - {self.date}"

    def clean(self):
        """Validación personalizada"""
        if self.start_time and self.end_time and self.start_time >= self.end_time:
            raise ValidationError('La hora de inicio debe ser anterior a la hora de fin')

class Attendance(models.Model):
    ATTENDANCE_STATUS = (
        ('present', 'Presente'),
        ('absent', 'Ausente'),
        ('late', 'Tardanza'),
        ('excused', 'Justificada'),
    )

    session = models.ForeignKey(AttendanceSession, on_delete=models.CASCADE, related_name='attendances')
    student = models.ForeignKey('users.StudentProfile', on_delete=models.CASCADE)
    status = models.CharField(max_length=10, choices=ATTENDANCE_STATUS)
    arrival_time = models.TimeField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    marked_by = models.ForeignKey('users.User', on_delete=models.CASCADE)
    marked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['session', 'student']

    def __str__(self):
        return f"{self.student.user.get_full_name()} - {self.session.date} - {self.get_status_display()}"

class AttendanceSummary(models.Model):
    student = models.ForeignKey('users.StudentProfile', on_delete=models.CASCADE)
    course_group = models.ForeignKey('courses.CourseGroup', on_delete=models.CASCADE)
    period_start = models.DateField()
    period_end = models.DateField()
    total_sessions = models.IntegerField(default=0)
    present_count = models.IntegerField(default=0)
    absent_count = models.IntegerField(default=0)
    late_count = models.IntegerField(default=0)
    excused_count = models.IntegerField(default=0)
    attendance_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['student', 'course_group', 'period_start', 'period_end']

    def __str__(self):
        return f"{self.student.user.get_full_name()} - {self.course_group} - {self.attendance_percentage}%"

    def calculate_percentage(self):
        """Calcular porcentaje de asistencia de manera segura"""
        if self.total_sessions > 0:
            self.attendance_percentage = (float(self.present_count) / float(self.total_sessions)) * 100
        else:
            self.attendance_percentage = 0
        return self.attendance_percentage