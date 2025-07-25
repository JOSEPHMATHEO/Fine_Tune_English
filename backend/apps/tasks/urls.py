from django.urls import path
from . import views

urlpatterns = [
    path('', views.student_tasks, name='student_tasks'),
    path('<int:task_id>/', views.task_detail, name='task_detail'),
    path('<int:task_id>/submit/', views.submit_task, name='submit_task'),
    path('create/', views.create_task, name='create_task'),
    path('teacher/course-groups/', views.teacher_course_groups, name='teacher_course_groups'),
    path('teacher/tasks/', views.teacher_tasks, name='teacher_tasks'),
]