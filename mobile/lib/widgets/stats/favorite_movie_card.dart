import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/coffee_colors.dart';

/// Carte premium pour afficher le film préféré (meilleure note)
/// Design System : Coffee Premium
class FavoriteMovieCard extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;
  final String? runtime;
  final List<String>? genres;

  const FavoriteMovieCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.rating,
    this.runtime,
    this.genres,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.caramelBronze.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            CachedNetworkImage(
              imageUrl: posterUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: CoffeeColors.darkRoast.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: CoffeeColors.caramelBronze,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: CoffeeColors.darkRoast,
                child: const Icon(
                  Icons.movie,
                  size: 60,
                  color: CoffeeColors.caramelBronze,
                ),
              ),
            ),

            // Gradient overlay (plus prononcé pour lisibilité) - marron espresso
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CoffeeColors.espresso.withValues(alpha: 0.3),
                    CoffeeColors.darkRoast.withValues(alpha: 0.95),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Badge "Meilleur film" en haut
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CoffeeColors.caramelBronze,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CoffeeColors.caramelBronze.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "Meilleur film",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Note en haut à droite avec badge doré
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CoffeeColors.terracotta,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: CoffeeColors.terracotta.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Infos en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Métadonnées (durée + genre)
                    Row(
                      children: [
                        if (runtime != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  runtime!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (genres != null && genres!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              genres!.first,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
