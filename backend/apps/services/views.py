from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Service, ServiceRequest
from .serializers import ServiceSerializer, ServiceRequestSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def services_list(request):
    """Lista de servicios disponibles"""
    services = Service.objects.filter(status='available')
    serializer = ServiceSerializer(services, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_service(request, service_id):
    """Solicitar un servicio"""
    service = get_object_or_404(Service, id=service_id)
    
    service_request = ServiceRequest.objects.create(
        service=service,
        user=request.user,
        request_data=request.data.get('request_data', {})
    )
    
    serializer = ServiceRequestSerializer(service_request)
    return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def service_requests(request):
    """Lista de solicitudes de servicios del usuario"""
    requests = ServiceRequest.objects.filter(user=request.user).order_by('-requested_at')
    serializer = ServiceRequestSerializer(requests, many=True)
    return Response(serializer.data)