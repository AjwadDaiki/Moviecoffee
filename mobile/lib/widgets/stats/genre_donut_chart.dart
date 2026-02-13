import 'package:flutter/material.dart';
import '../charts/donut_chart_painter.dart';
import '../../theme/coffee_colors.dart';

/// Widget donut chart avec animation et légende pour les genres
/// Amélioration : Animation d'entrée + légende interactive + palette cohérente
class GenreDonutChart extends StatefulWidget {
  final List<GenreData> genres;
  final String title;

  const GenreDonutChart({
    super.key,
    required this.genres,
    this.title = "Répartition des genres",
  });

  @override
  State<GenreDonutChart> createState() => _GenreDonutChartState();
}

class _GenreDonutChartState extends State<GenreDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // INITIATIVE : Palette de couleurs marron café premium
  static const List<Color> _genrePalette = [
    Color(0xFF5D4037), // Marron café foncé (principal)
    Color(0xFF3E2723), // Espresso profond
    Color(0xFF8D6E63), // Marron moyen
    Color(0xFF4E342E), // Marron chocolat
    Color(0xFFA1887F), // Marron clair
    Color(0xFF6D4C41), // Marron torréfié
    Color(0xFF795548), // Marron terreux
    Color(0xFFBCAAA4), // Beige café
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.genres.isEmpty) {
      return _buildEmptyState();
    }

    // Créer les segments avec couleurs
    final segments = widget.genres.asMap().entries.map((entry) {
      final index = entry.key;
      final genre = entry.value;
      return DonutSegment(
        label: genre.genre,
        value: genre.count.toDouble(),
        color: _genrePalette[index % _genrePalette.length],
      );
    }).toList();

    final totalCount = widget.genres.fold<int>(0, (sum, g) => sum + g.count);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.milkFoam,
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 25),

          // Donut + Légende
          Row(
            children: [
              // Donut Chart
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: DonutChartPainter(
                          segments: segments,
                          animationProgress: _animation.value,
                          strokeWidth: 30,
                          showInnerLabel: true,
                          centerLabel: "$totalCount\nfilms",
                          centerLabelStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'RecoletaAlt',
                            color: CoffeeColors.espresso,
                            height: 1.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Légende
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.genres.asMap().entries.map((entry) {
                    final index = entry.key;
                    final genre = entry.value;
                    final color = _genrePalette[index % _genrePalette.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildLegendItem(
                        color: color,
                        label: genre.genre,
                        percentage: genre.percentage,
                        count: genre.count,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double percentage,
    required int count,
  }) {
    return Row(
      children: [
        // Pastille colorée
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Label
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CoffeeColors.espresso,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Pourcentage + Count
        Text(
          "${percentage.toStringAsFixed(0)}%",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'RecoletaAlt',
            color: color,
          ),
        ),
        Text(
          " ($count)",
          style: const TextStyle(
            fontSize: 11,
            color: CoffeeColors.moka,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: CoffeeColors.milkFoam,
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.movie_filter, size: 60, color: CoffeeColors.steamMilk),
            SizedBox(height: 15),
            Text(
              "Aucune donnée",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CoffeeColors.moka,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modèle de données pour un genre
class GenreData {
  final String genre;
  final int count;
  final double percentage;

  const GenreData({
    required this.genre,
    required this.count,
    required this.percentage,
  });
}
