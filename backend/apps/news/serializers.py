from rest_framework import serializers
from .models import News, NewsCategory
from apps.users.serializers import UserSerializer

class NewsCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsCategory
        fields = '__all__'

class NewsSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    category = NewsCategorySerializer(read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = News
        fields = [
            'id', 'title', 'summary', 'content', 'image', 'image_url', 'category',
            'author', 'publication_date', 'is_featured', 'views_count',
            'created_at', 'updated_at', 'is_published'
        ]

    def get_image_url(self, obj):
        """Obtener URL completa de la imagen"""
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None