from django.contrib import admin
from .models import Service, ServiceCategory, ServiceRequest, Certificate

@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active']
    list_filter = ['is_active']

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'service_type', 'category', 'status', 'is_premium']
    list_filter = ['service_type', 'status', 'is_premium']
    search_fields = ['name', 'description']

@admin.register(ServiceRequest)
class ServiceRequestAdmin(admin.ModelAdmin):
    list_display = ['service', 'user', 'status', 'requested_at']
    list_filter = ['status', 'requested_at']

@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = ['student', 'certificate_type', 'course_name', 'issue_date', 'is_valid']
    list_filter = ['certificate_type', 'is_valid', 'issue_date']
    search_fields = ['certificate_id', 'course_name']