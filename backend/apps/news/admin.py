from django.contrib import admin
from .models import News, NewsCategory, NewsView

@admin.register(NewsCategory)
class NewsCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'color']

@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'author', 'publication_date', 'is_published', 'is_featured']
    list_filter = ['is_published', 'is_featured', 'category', 'publication_date']
    search_fields = ['title', 'content']
    readonly_fields = ['views_count', 'created_at', 'updated_at']

@admin.register(NewsView)
class NewsViewAdmin(admin.ModelAdmin):
    list_display = ['news', 'user', 'viewed_at']
    list_filter = ['viewed_at']