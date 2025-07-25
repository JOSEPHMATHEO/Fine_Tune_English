from django.urls import path
from . import views

urlpatterns = [
    path('enrollments/', views.student_enrollments, name='student_enrollments'),
    path('enrollments/<int:enrollment_id>/', views.course_detail, name='course_detail'),
    path('enrollments/<int:enrollment_id>/grades/', views.student_grades, name='student_grades'),
    path('enrollments/<int:enrollment_id>/schedules/', views.course_schedules, name='course_schedules'),
]