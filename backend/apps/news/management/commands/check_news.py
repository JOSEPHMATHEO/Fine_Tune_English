from django.core.management.base import BaseCommand
from apps.news.models import News

class Command(BaseCommand):
    help = 'Verificar estado de las noticias en la base de datos'

    def handle(self, *args, **options):
        self.stdout.write('🔍 Verificando noticias en la base de datos...')

        # Obtener todas las noticias
        all_news = News.objects.all().order_by('-created_at')
        total_count = all_news.count()

        self.stdout.write(f'📊 Total de noticias en BD: {total_count}')

        if total_count == 0:
            self.stdout.write(self.style.WARNING('⚠️ No hay noticias en la base de datos'))
            return

        # Noticias publicadas
        published_news = all_news.filter(is_published=True)
        published_count = published_news.count()

        self.stdout.write(f'✅ Noticias publicadas: {published_count}')
        self.stdout.write(f'❌ Noticias no publicadas: {total_count - published_count}')

        # Noticias destacadas
        featured_news = published_news.filter(is_featured=True)
        featured_count = featured_news.count()

        self.stdout.write(f'⭐ Noticias destacadas: {featured_count}')

        self.stdout.write('\n📰 Lista detallada de noticias publicadas:')
        for i, news in enumerate(published_news, 1):
            self.stdout.write(f'   {i}. "{news.title}" (ID: {news.id})')
            self.stdout.write(f'      - Autor: {news.author.nombre_completo} ({news.author.rol})')
            self.stdout.write(f'      - Fecha creación: {news.created_at}')
            self.stdout.write(f'      - Fecha publicación: {news.publication_date}')
            self.stdout.write(f'      - Destacada: {"Sí" if news.is_featured else "No"}')
            self.stdout.write(f'      - Categoría: {news.category.name if news.category else "Sin categoría"}')
            self.stdout.write(f'      - Imagen: {"Sí" if news.image else "No"}')
            self.stdout.write(f'      - Vistas: {news.views_count}')
            self.stdout.write('')

        if total_count != published_count:
            self.stdout.write('\n❌ Noticias NO publicadas:')
            unpublished_news = all_news.filter(is_published=False)
            for i, news in enumerate(unpublished_news, 1):
                self.stdout.write(f'   {i}. "{news.title}" (ID: {news.id}) - Autor: {news.author.nombre_completo}')

        self.stdout.write(self.style.SUCCESS('\n✅ Verificación completada'))