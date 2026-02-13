import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

/// Carte de compatibilité avec le partenaire
/// Design System : Coffee Premium
class MatchCompatibilityCard extends StatefulWidget {
  final double matchPercentage; // 0-100
  final String? partnerName;

  const MatchCompatibilityCard({
    super.key,
    required this.matchPercentage,
    this.partnerName,
  });

  @override
  State<MatchCompatibilityCard> createState() => _MatchCompatibilityCardState();
}

class _MatchCompatibilityCardState extends State<MatchCompatibilityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.matchPercentage / 100,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getCompatibilityColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF4CAF50); // Vert
    if (percentage >= 60) return const Color(0xFFFFB74D); // Orange clair
    if (percentage >= 40) return CoffeeColors.caramelBronze; // Orange
    return const Color(0xFFE57373); // Rouge clair
  }

  String _getCompatibilityLabel(double percentage) {
    if (percentage >= 80) return "Excellente";
    if (percentage >= 60) return "Bonne";
    if (percentage >= 40) return "Moyenne";
    return "Faible";
  }

  IconData _getCompatibilityIcon(double percentage) {
    if (percentage >= 80) return Icons.favorite;
    if (percentage >= 60) return Icons.thumb_up;
    if (percentage >= 40) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCompatibilityColor(widget.matchPercentage);
    final label = _getCompatibilityLabel(widget.matchPercentage);
    final icon = _getCompatibilityIcon(widget.matchPercentage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.milkFoam,
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et icône
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Compatibilité",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: CoffeeColors.espresso,
                      ),
                    ),
                    if (widget.partnerName != null)
                      Text(
                        "avec ${widget.partnerName}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: CoffeeColors.moka,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pourcentage + Label
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Text(
                    "${(_progressAnimation.value * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'RecoletaAlt',
                      color: color,
                      height: 1.0,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CoffeeColors.moka,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Barre de progression avec gradient
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: CoffeeColors.creamBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.7),
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          // Description / Conseil
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getCompatibilityMessage(widget.matchPercentage),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCompatibilityMessage(double percentage) {
    if (percentage >= 80) {
      return "Vous avez des goûts très similaires ! Continuez à explorer ensemble.";
    } else if (percentage >= 60) {
      return "Bonne affinité cinématographique. Quelques divergences enrichissantes.";
    } else if (percentage >= 40) {
      return "Vos goûts sont complémentaires. Parfait pour découvrir de nouveaux horizons.";
    } else {
      return "Vos goûts diffèrent, mais c'est une opportunité de s'ouvrir à de nouveaux genres !";
    }
  }
}
