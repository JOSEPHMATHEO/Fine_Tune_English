from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Notification
from .serializers import NotificationSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_notifications(request):
    """Lista de notificaciones del usuario"""
    notifications = Notification.objects.filter(
        recipient=request.user
    ).order_by('-created_at')

    # Marcar como vistas las notificaciones no leídas
    unread_notifications = notifications.filter(is_read=False)
    for notification in unread_notifications:
        if not notification.is_read:
            notification.is_read = True
            notification.read_at = timezone.now()
            notification.save()

    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_as_read(request, notification_id):
    """Marcar notificación como leída"""
    notification = get_object_or_404(
        Notification,
        id=notification_id,
        recipient=request.user
    )

    notification.is_read = True
    notification.read_at = timezone.now()
    notification.save()

    serializer = NotificationSerializer(notification)
    return Response(serializer.data)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_all_as_read(request):
    """Marcar todas las notificaciones como leídas"""
    notifications = Notification.objects.filter(
        recipient=request.user,
        is_read=False
    )

    for notification in notifications:
        notification.is_read = True
        notification.read_at = timezone.now()
        notification.save()

    return Response({
        'message': f'{notifications.count()} notificaciones marcadas como leídas'
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unread_count(request):
    """Obtener cantidad de notificaciones no leídas"""
    count = Notification.objects.filter(
        recipient=request.user,
        is_read=False
    ).count()

    return Response({'unread_count': count})