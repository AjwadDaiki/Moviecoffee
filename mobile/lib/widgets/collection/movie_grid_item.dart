import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../theme/coffee_colors.dart';
import '../app_ui_components.dart';

/// Widget carte de film pour la grille de collection
class MovieGridItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback? onRateTap;
  final bool showRating;

  const MovieGridItem({
    super.key,
    required this.movie,
    required this.onTap,
    this.onRateTap,
    this.showRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.coffeeDark.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster du film
              CachedNetworkImage(
                imageUrl: movie.posterPath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.bgCream,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.coffeeDark.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.movie,
                      size: 50,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ),

              // Gradient overlay pour le texte - marron espresso
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      CoffeeColors.darkRoast.withValues(alpha: 0.95),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Note utilisateur (si présente)
              if (showRating && movie.isRated)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          movie.userRating!.toStringAsFixed(1),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Badge "Match" si source = match
              if (movie.source == 'match')
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOrange.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Match",
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bouton noter (visible)
              if (onRateTap != null)
                Positioned(
                  bottom: 56,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRateTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: CoffeeColors.caramelBronze,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CoffeeColors.espresso.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        movie.isRated ? Icons.edit_rounded : Icons.star_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // Titre en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title.fr,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (movie.genres.isNotEmpty)
                        Text(
                          movie.genres.first,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
