import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

/// Carte métrique réutilisable pour afficher une stat simple
/// Design System : Coffee Premium
class StatsMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color? shadowColor;

  const StatsMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = CoffeeColors.caramelBronze,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.milkFoam,
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? iconColor).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône avec badge circulaire
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 15),

          // Valeur (gros et bold)
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),

          // Label (descriptif)
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CoffeeColors.moka,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
