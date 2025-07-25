from rest_framework import serializers
from .models import Notification, NotificationType

class NotificationTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationType
        fields = '__all__'

class NotificationSerializer(serializers.ModelSerializer):
    recipient = serializers.SerializerMethodField()
    notification_type = NotificationTypeSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'notification_type', 'title', 'message',
            'priority', 'is_read', 'action_url',
            'metadata', 'created_at', 'read_at', 'expires_at'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['priority_display'] = instance.get_priority_display()
        return data

    def get_recipient(self, obj):
        if obj.recipient:
            return {
                'id': obj.recipient.id,
                'nombre_completo': obj.recipient.nombre_completo,
                'correo': obj.recipient.correo,
                'rol': obj.recipient.rol
            }
        return None