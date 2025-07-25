from django.urls import path
from . import views

urlpatterns = [
    path('system-stats/', views.system_stats, name='system_stats'),
    path('recent-activities/', views.recent_activities, name='recent_activities'),
    path('attendance-stats/', views.global_attendance_stats, name='global_attendance_stats'),
]