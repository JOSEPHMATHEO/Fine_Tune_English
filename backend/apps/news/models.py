from django.db import models

class NewsCategory(models.Model):
    name = models.CharField(max_length=50)
    description = models.TextField(null=True, blank=True)
    color = models.CharField(max_length=7, default='#3B82F6')  # Hex color

    class Meta:
        verbose_name_plural = "News Categories"

    def __str__(self):
        return self.name

class News(models.Model):
    title = models.CharField(max_length=200)
    summary = models.TextField(max_length=300)
    content = models.TextField()
    image = models.ImageField(upload_to='news/', null=True, blank=True)
    category = models.ForeignKey(NewsCategory, on_delete=models.SET_NULL, null=True, blank=True)
    author = models.ForeignKey('users.User', on_delete=models.CASCADE)
    publication_date = models.DateTimeField()
    is_published = models.BooleanField(default=True)  # Por defecto publicado
    is_featured = models.BooleanField(default=False)
    views_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = "News"

    def __str__(self):
        return self.title

    @property
    def image_url(self):
        """Obtener URL completa de la imagen"""
        if self.image:
            # Construir URL completa para el frontend
            from django.conf import settings
            if hasattr(settings, 'MEDIA_URL') and self.image.url.startswith('/'):
                return f"http://127.0.0.1:8000{self.image.url}"
            return self.image.url
        return None

class NewsView(models.Model):
    news = models.ForeignKey(News, on_delete=models.CASCADE, related_name='views')
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['news', 'user']