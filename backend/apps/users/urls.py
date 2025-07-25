from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Endpoint de prueba
    path('test/', views.test_connection, name='test_connection'),

    # Autenticación
    path('register/', views.register_view, name='register'),
    path('login/', views.login_view, name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Recuperación de contraseña
    path('password-reset/request/', views.password_reset_request_view, name='password_reset_request'),
    path('password-reset/verify/', views.verify_reset_token_view, name='verify_reset_token'),
    path('password-reset/confirm/', views.password_reset_confirm_view, name='password_reset_confirm'),
    path('change-password/', views.change_password_view, name='change_password'),

    # Perfil
    path('profile/', views.profile_view, name='profile'),
    path('profile/update/', views.update_profile_view, name='update_profile'),

    # Debug
    path('debug/', views.debug_user_info, name='debug_user_info'),
]