import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

/// Header pour l'écran de statistiques avec bouton refresh
/// Design System : Coffee Premium
class StatsHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const StatsHeader({
    super.key,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Titre
          const Text(
            "Statistiques",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
              letterSpacing: -0.5,
            ),
          ),

          // Bouton refresh avec animation
          GestureDetector(
            onTap: isRefreshing ? null : onRefresh,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoffeeColors.caramelBronze,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CoffeeColors.caramelBronze.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: isRefreshing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
