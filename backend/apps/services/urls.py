from django.urls import path
from . import views

urlpatterns = [
    path('', views.services_list, name='services_list'),
    path('<int:service_id>/request/', views.request_service, name='request_service'),
    path('requests/', views.service_requests, name='service_requests'),
]