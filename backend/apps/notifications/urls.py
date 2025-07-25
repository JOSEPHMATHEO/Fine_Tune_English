from django.urls import path
from . import views

urlpatterns = [
    path('', views.user_notifications, name='user_notifications'),
    path('<int:notification_id>/read/', views.mark_as_read, name='mark_notification_read'),
    path('mark-all-read/', views.mark_all_as_read, name='mark_all_notifications_read'),
    path('unread-count/', views.unread_count, name='unread_notifications_count'),
]