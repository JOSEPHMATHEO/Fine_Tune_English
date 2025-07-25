from django.apps import AppConfig


class AdminDashboardConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.admin'
    label = 'admin_dashboard'  # Cambiado de 'admin' a 'admin_dashboard'