import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

/// =============================================================================
/// COMMON HEADER - Header Unifié pour toute l'application
/// =============================================================================
/// Utilisé sur : Feed, Collection, Stats, etc.
/// Garantit une cohérence visuelle totale.
/// =============================================================================

class CommonHeader extends StatelessWidget {
  /// Action custom pour le bouton de droite (null = notification par défaut)
  final VoidCallback? onActionTap;

  /// Icône custom pour le bouton de droite
  final IconData actionIcon;

  /// Afficher ou non le bouton d'action
  final bool showActionButton;

  const CommonHeader({
    super.key,
    this.onActionTap,
    this.actionIcon = Icons.notifications_none_rounded,
    this.showActionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // LOGO / TITRE
          // ═══════════════════════════════════════════════════════════════════
          Row(
            children: [
              // Icône café
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CoffeeColors.caramelBronze,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Texte
              const Text(
                "Movie Coffee",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RecoletaAlt',
                  color: CoffeeColors.espresso,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // ═══════════════════════════════════════════════════════════════════
          // BOUTON D'ACTION (Notification par défaut)
          // ═══════════════════════════════════════════════════════════════════
          if (showActionButton)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CoffeeColors.milkFoam,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CoffeeColors.creamBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CoffeeColors.espresso.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  actionIcon,
                  color: CoffeeColors.espresso,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// =============================================================================
/// COMMON PAGE TITLE - Titre de section sous le header
/// =============================================================================
/// Utilisé pour "Ma Collection", "Statistiques", etc.
/// =============================================================================

class CommonPageTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const CommonPageTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
              letterSpacing: -0.5,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
