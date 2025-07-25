from django.contrib import admin
from .models import AttendanceSession, Attendance, AttendanceSummary

@admin.register(AttendanceSession)
class AttendanceSessionAdmin(admin.ModelAdmin):
    list_display = ['course_group', 'date', 'start_time', 'end_time']
    list_filter = ['date', 'course_group']

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['session', 'student', 'status', 'arrival_time', 'marked_at']
    list_filter = ['status', 'session__date']

@admin.register(AttendanceSummary)
class AttendanceSummaryAdmin(admin.ModelAdmin):
    list_display = ['student', 'course_group', 'period_start', 'period_end', 'attendance_percentage']
    list_filter = ['period_start', 'period_end']