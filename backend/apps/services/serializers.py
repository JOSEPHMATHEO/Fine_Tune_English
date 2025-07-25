from rest_framework import serializers
from .models import Service, ServiceCategory, ServiceRequest

class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = '__all__'

class ServiceSerializer(serializers.ModelSerializer):
    category = ServiceCategorySerializer(read_only=True)

    class Meta:
        model = Service
        fields = [
            'id', 'name', 'description', 'service_type',
            'category', 'status', 'url', 'instructions',
            'icon', 'color', 'is_premium'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['service_type_display'] = instance.get_service_type_display()
        data['status_display'] = instance.get_status_display()
        return data

class ServiceRequestSerializer(serializers.ModelSerializer):
    service = ServiceSerializer(read_only=True)
    user = serializers.SerializerMethodField()

    class Meta:
        model = ServiceRequest
        fields = [
            'id', 'service', 'user', 'status',
            'request_data', 'response_data', 'requested_at',
            'completed_at', 'notes'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['status_display'] = instance.get_status_display()
        return data

    def get_user(self, obj):
        if obj.user:
            return {
                'id': obj.user.id,
                'nombre_completo': obj.user.nombre_completo,
                'correo': obj.user.correo,
                'rol': obj.user.rol
            }
        return None