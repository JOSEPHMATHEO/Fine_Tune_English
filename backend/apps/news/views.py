from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import News, NewsView, NewsCategory
from .serializers import NewsSerializer, NewsCategorySerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def news_list(request):
    """Lista de TODAS las noticias publicadas"""
    try:
        print(f'📰 BACKEND: Usuario {request.user.correo} solicitando noticias')

        # Obtener TODAS las noticias publicadas
        news = News.objects.filter(
            is_published=True
        ).select_related('category', 'author').order_by('-created_at')

        total_count = news.count()
        print(f'✅ BACKEND: Encontradas {total_count} noticias publicadas')

        if total_count == 0:
            print('⚠️ BACKEND: No hay noticias publicadas en la base de datos')
            return Response([])

        # Log detallado de cada noticia
        for i, n in enumerate(news, 1):
            print(f'   📰 BACKEND {i}. "{n.title}" (ID: {n.id})')
            print(f'      - Autor: {n.author.nombre_completo} ({n.author.rol})')
            print(f'      - Fecha: {n.publication_date}')
            print(f'      - Destacada: {n.is_featured}')
            print(f'      - Categoría: {n.category.name if n.category else "Sin categoría"}')
            print(f'      - Imagen: {n.image_url if n.image else "Sin imagen"}')
            print(f'      - Vistas: {n.views_count}')

        # Serializar todas las noticias
        serializer = NewsSerializer(news, many=True, context={'request': request})
        serialized_data = serializer.data

        print(f'📤 BACKEND: Enviando {len(serialized_data)} noticias al frontend')

        # Log de datos serializados
        for i, news_data in enumerate(serialized_data, 1):
            print(f'   📤 BACKEND Serializada {i}: {news_data["title"]} - Imagen URL: {news_data.get("image_url", "None")}')

        return Response(serialized_data)

    except Exception as e:
        print(f'❌ BACKEND: Error obteniendo noticias: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def news_detail(request, news_id):
    """Detalle de una noticia específica"""
    try:
        news = get_object_or_404(News, id=news_id, is_published=True)

        # Registrar visualización
        NewsView.objects.get_or_create(news=news, user=request.user)

        # Incrementar contador de vistas
        news.views_count += 1
        news.save()

        serializer = NewsSerializer(news, context={'request': request})
        return Response(serializer.data)

    except Exception as e:
        print(f'❌ Error obteniendo detalle de noticia: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_news(request):
    """Crear nueva noticia (solo admin)"""
    if request.user.rol != 'admin':
        return Response({'error': 'Solo administradores pueden crear noticias'}, status=403)

    try:
        print(f'📰 BACKEND: Admin {request.user.correo} creando noticia')
        print(f'📤 BACKEND: Datos recibidos: {request.data}')

        # Validar campos requeridos
        required_fields = ['title', 'summary', 'content']
        for field in required_fields:
            if not request.data.get(field, '').strip():
                return Response({
                    'error': f'El campo {field} es requerido'
                }, status=status.HTTP_400_BAD_REQUEST)

        # Obtener categoría si se especifica
        category = None
        category_id = request.data.get('category')
        if category_id:
            try:
                category = NewsCategory.objects.get(id=category_id)
                print(f'✅ BACKEND: Categoría encontrada: {category.name}')
            except NewsCategory.DoesNotExist:
                print(f'❌ BACKEND: Categoría {category_id} no encontrada')
                return Response({
                    'error': 'Categoría no encontrada'
                }, status=status.HTTP_400_BAD_REQUEST)

        # Crear la noticia
        news = News.objects.create(
            title=request.data['title'].strip(),
            summary=request.data['summary'].strip(),
            content=request.data['content'].strip(),
            category=category,
            author=request.user,
            publication_date=timezone.now(),
            is_published=request.data.get('is_published', 'true').lower() in ['true', '1', 'yes'],
            is_featured=request.data.get('is_featured', 'false').lower() in ['true', '1', 'yes']
        )

        print(f'✅ BACKEND: Noticia creada exitosamente:')
        print(f'   - ID: {news.id}')
        print(f'   - Título: {news.title}')
        print(f'   - Publicada: {news.is_published}')
        print(f'   - Destacada: {news.is_featured}')
        print(f'   - Autor: {news.author.nombre_completo}')
        print(f'   - Categoría: {news.category.name if news.category else "Sin categoría"}')

        # Verificar que se guardó correctamente
        saved_news = News.objects.get(id=news.id)
        print(f'✅ BACKEND: Verificación: Noticia guardada con ID {saved_news.id}')

        serializer = NewsSerializer(news, context={'request': request})
        return Response({
            'message': 'Noticia creada exitosamente',
            'news': serializer.data
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        print(f'❌ BACKEND: Error creando noticia: {e}')
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def news_categories(request):
    """Lista de categorías de noticias"""
    try:
        categories = NewsCategory.objects.all()
        serializer = NewsCategorySerializer(categories, many=True)
        return Response(serializer.data)
    except Exception as e:
        print(f'❌ Error obteniendo categorías: {e}')
        return Response({
            'error': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)