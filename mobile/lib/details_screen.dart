import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/movie.dart';

class AppColors {
  static const Color bgLight = Color(0xFFF3E9E1); 
  static const Color bgDark = Color(0xFF362824); 
  static const Color accentCaramel = Color(0xFFE68D45); 
  static const Color textDark = Color(0xFF2C221F); 
  static const Color cardSurface = Color(0xFF4A3B36); // Ajouté ici !
}

class DetailsScreen extends StatelessWidget {
  final Movie movie;

  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final String headerImage = movie.posterPath;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: Container( // RETRAIT DU CONST ICI
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: headerImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.bgDark),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.bgDark.withOpacity(0.8)],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title.fr,
                    style: GoogleFonts.dmSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoBadge(icon: Icons.calendar_today_rounded, text: movie.releaseDate.split('-')[0]),
                      const SizedBox(width: 10),
                      _InfoBadge(icon: Icons.star_rounded, text: "${movie.voteAverage.toStringAsFixed(1)}/10", color: Colors.amber[800]),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Synopsis",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview.fr.isNotEmpty ? movie.overview.fr : "Aucun résumé disponible en français.",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 120), // Espace pour pas être gêné par la nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoBadge({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardSurface.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
