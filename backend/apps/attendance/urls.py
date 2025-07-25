from django.urls import path
from . import views

urlpatterns = [
    path('', views.student_attendance, name='student_attendance'),
    path('summary/', views.attendance_summary, name='attendance_summary'),
    path('sessions/create/', views.create_attendance_session, name='create_attendance_session'),
    path('mark/', views.mark_attendance, name='mark_attendance'),
    path('teacher/sessions/', views.teacher_attendance_sessions, name='teacher_attendance_sessions'),
    path('teacher/stats/', views.teacher_attendance_stats, name='teacher_attendance_stats'),
]