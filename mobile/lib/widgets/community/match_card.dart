import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

class MatchCard extends StatelessWidget {
  final String matchedWithUsername;
  final String movieTitle;
  final String moviePoster;
  final int movieId;
  final String matchedAt;
  final VoidCallback? onTap;

  const MatchCard({
    Key? key,
    required this.matchedWithUsername,
    required this.movieTitle,
    required this.moviePoster,
    required this.movieId,
    required this.matchedAt,
    this.onTap,
  }) : super(key: key);

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return "Il y a ${diff.inMinutes}min";
        }
        return "Il y a ${diff.inHours}h";
      } else if (diff.inDays == 1) {
        return "Hier";
      } else if (diff.inDays < 7) {
        return "Il y a ${diff.inDays}j";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image de fond (poster)
              Positioned.fill(
                child: moviePoster.isNotEmpty
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w500$moviePoster',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: CoffeeColors.darkRoast.withValues(alpha: 0.3),
                            child: const Center(
                              child: Icon(Icons.movie, size: 40, color: Colors.white54),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: CoffeeColors.darkRoast.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(Icons.movie, size: 40, color: Colors.white54),
                        ),
                      ),
              ),

              // Gradient overlay pour lisibilité - marron espresso
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CoffeeColors.espresso.withValues(alpha: 0.3),
                        CoffeeColors.darkRoast.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "C'est un match!" avec icône coeur
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.pink.shade400,
                                Colors.red.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "C'est un match!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Heure du match
                        if (matchedAt.isNotEmpty)
                          Text(
                            _formatDate(matchedAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Titre du film
                    Text(
                      movieTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Info "Avec..."
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CoffeeColors.caramelBronze,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              matchedWithUsername[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Avec $matchedWithUsername",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // CTA - Bouton d'action
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Discuter pour planifier",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Version compacte pour la liste
class CompactMatchCard extends StatelessWidget {
  final String matchedWithUsername;
  final String movieTitle;
  final String moviePoster;
  final VoidCallback? onTap;

  const CompactMatchCard({
    Key? key,
    required this.matchedWithUsername,
    required this.movieTitle,
    required this.moviePoster,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Poster
              Positioned.fill(
                child: moviePoster.isNotEmpty
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w342$moviePoster',
                        fit: BoxFit.cover,
                      )
                    : Container(color: CoffeeColors.darkRoast),
              ),

              // Gradient - marron espresso
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        CoffeeColors.darkRoast.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Badge coeur en haut
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),

              // Infos en bas
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movieTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Avec $matchedWithUsername",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
