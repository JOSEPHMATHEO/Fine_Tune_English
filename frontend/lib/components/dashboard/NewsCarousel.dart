import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/noticia.dart';

class NewsCarousel extends StatefulWidget {
  final List<Noticia> noticias;

  const NewsCarousel({super.key, required this.noticias});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    print('📰 NewsCarousel: Recibidas ${widget.noticias.length} noticias del Dashboard');

    // Log detallado de cada noticia recibida
    for (int i = 0; i < widget.noticias.length; i++) {
      final n = widget.noticias[i];
      print('   📰 Frontend ${i + 1}. "${n.titulo}" (ID: ${n.id})');
      print('      - Publicada: ${n.estaPublicada}');
      print('      - Destacada: ${n.estaDestacada}');
      print('      - Autor: ${n.autor?.nombreCompleto ?? "Sin autor"}');
      print('      - Fecha: ${n.fechaFormateada}');
    }

    if (widget.noticias.isEmpty) {
      print('⚠️ NewsCarousel: No hay noticias para mostrar');
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildCarousel(),
        const SizedBox(height: 12),
        _buildPageIndicators(),
        const SizedBox(height: 20),
        if (widget.noticias.length > 6) _buildAdditionalNewsList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Noticias y Anuncios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No hay noticias disponibles',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Las noticias aparecerán aquí cuando estén disponibles',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Noticias y Anuncios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.noticias.length} noticias',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    // Mostrar hasta 6 noticias en el carrusel
    final carouselNews = widget.noticias.take(6).toList();

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: carouselNews.length,
        itemBuilder: (context, index) {
          final noticia = carouselNews[index];
          print('📌 Mostrando noticia en carrusel ${index + 1}: ${noticia.titulo}');
          return _buildNewsCard(noticia);
        },
      ),
    );
  }

  Widget _buildPageIndicators() {
    final carouselCount = widget.noticias.length > 6 ? 6 : widget.noticias.length;

    if (carouselCount <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        carouselCount,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalNewsList() {
    // Mostrar noticias adicionales después de las primeras 6
    final additionalNews = widget.noticias.skip(6).take(4).toList();

    if (additionalNews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas noticias',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: additionalNews.length,
          itemBuilder: (context, index) {
            final noticia = additionalNews[index];
            print('📄 Mostrando noticia en lista ${index + 1}: ${noticia.titulo}');
            return _buildNewsListItem(noticia);
          },
        ),
        if (widget.noticias.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Total: ${widget.noticias.length} noticias disponibles'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('Ver todas las ${widget.noticias.length} noticias'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewsCard(Noticia noticia) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue.withOpacity(0.1),
      ),
      child: Stack(
        children: [
          // Fondo de la tarjeta
          _buildCardBackground(noticia),

          // Overlay con gradiente
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Contenido de la tarjeta
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría
                  if (noticia.categoria != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: noticia.categoriaColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        noticia.categoriaTexto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Título
                  Text(
                    noticia.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Resumen
                  Text(
                    noticia.resumen,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Fecha y autor
                  Row(
                    children: [
                      Text(
                        noticia.fechaFormateada,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      if (noticia.autor != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          noticia.autor!.primerNombre,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBackground(Noticia noticia) {
    // Mostrar imagen si está disponible, sino usar fondo de color
    if (noticia.imagenUrl != null && noticia.imagenUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          noticia.imagenUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error cargando imagen: $error');
            return _buildColorBackground(noticia);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildColorBackground(noticia);
          },
        ),
      );
    } else {
      return _buildColorBackground(noticia);
    }
  }

  Widget _buildColorBackground(Noticia noticia) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            noticia.categoriaColor.withOpacity(0.4),
            noticia.categoriaColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article,
          size: 48,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildNewsListItem(Noticia noticia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: noticia.categoriaColor.withOpacity(0.1),
          ),
          child: Icon(
            Icons.article,
            color: noticia.categoriaColor,
            size: 24,
          ),
        ),
        title: Text(
          noticia.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              noticia.resumen,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (noticia.categoria != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: noticia.categoriaColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      noticia.categoriaTexto,
                      style: TextStyle(
                        color: noticia.categoriaColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  noticia.fechaFormateada,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                if (noticia.estaDestacada) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.amber,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility,
              size: 16,
              color: Colors.grey[600],
            ),
            Text(
              '${noticia.vistas}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          print('👆 Tap en noticia: ${noticia.titulo}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo: ${noticia.titulo}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}