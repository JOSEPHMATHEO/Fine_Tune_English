from django.contrib import admin
from .models import Course, Classroom, Period, CourseGroup, Enrollment, Schedule, Grade

@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'level', 'modality', 'is_active']
    list_filter = ['level', 'modality', 'is_active']
    search_fields = ['name', 'code']

@admin.register(Classroom)
class ClassroomAdmin(admin.ModelAdmin):
    list_display = ['name', 'capacity', 'location']
    search_fields = ['name', 'location']

@admin.register(Period)
class PeriodAdmin(admin.ModelAdmin):
    list_display = ['name', 'start_date', 'end_date', 'is_active']
    list_filter = ['is_active']

@admin.register(CourseGroup)
class CourseGroupAdmin(admin.ModelAdmin):
    list_display = ['course', 'name', 'period', 'teacher', 'max_students']
    list_filter = ['course', 'period']

@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ['student', 'course_group', 'enrollment_date', 'is_active']
    list_filter = ['is_active', 'enrollment_date']

@admin.register(Schedule)
class ScheduleAdmin(admin.ModelAdmin):
    list_display = ['course_group', 'day_of_week', 'start_time', 'end_time', 'classroom']
    list_filter = ['day_of_week']

@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ['enrollment', 'grade_type', 'subject', 'obtained_score', 'max_score', 'date']
    list_filter = ['grade_type', 'date']