from django.contrib import admin
from .models import Task, TaskSubmission

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'task_type', 'course_group', 'due_date', 'priority', 'is_active']
    list_filter = ['task_type', 'priority', 'is_active', 'due_date']
    search_fields = ['title', 'description']

@admin.register(TaskSubmission)
class TaskSubmissionAdmin(admin.ModelAdmin):
    list_display = ['task', 'student', 'status', 'submitted_at', 'score']
    list_filter = ['status', 'submitted_at']