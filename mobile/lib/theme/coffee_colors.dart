import 'package:flutter/material.dart';

/// =============================================================================
/// COFFEE COLORS - Palette Premium "Coffee Shop"
/// =============================================================================
/// Design System inspiré des cafés specialty : chaleureux, premium, lisible.
/// Aucune couleur agressive. Tout est doux et accueillant.
/// =============================================================================

class CoffeeColors {
  CoffeeColors._(); // Empêche l'instanciation

  // ═══════════════════════════════════════════════════════════════════════════
  // FONDS (Backgrounds)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fond principal de l'app - Crème Latte doux (pas blanc pur)
  static const Color latteCream = Color(0xFFF5F0E8);

  /// Fond des cartes - Mousse de lait (légèrement plus clair)
  static const Color milkFoam = Color(0xFFFFFBF7);

  /// Fond sombre (pour contrastes, overlays)
  static const Color darkRoast = Color(0xFF2D2420);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS (CTA & Interactions) - MARRON FONCÉ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Action principale - Marron café foncé (LIKE, boutons primaires)
  static const Color caramelBronze = Color(0xFF5D4037);

  /// Action secondaire - Marron moyen chaud
  static const Color terracotta = Color(0xFF8D6E63);

  /// Action négative - Gris neutre (pas rouge agressif)
  static const Color stoneGrey = Color(0xFF78716C);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTES (Typography)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Titres et texte principal - Espresso (jamais noir pur)
  static const Color espresso = Color(0xFF3D2B1F);

  /// Sous-titres et texte secondaire - Moka gris
  static const Color moka = Color(0xFF7A6B5B);

  /// Texte désactivé / placeholder
  static const Color steamMilk = Color(0xFFB5A99A);

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES (Borders, Dividers, Shadows)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bordures et séparateurs
  static const Color creamBorder = Color(0xFFE8E0D5);

  /// Overlay sombre (pour modales, gradients)
  static const Color overlay = Color(0x99000000);

  // ═══════════════════════════════════════════════════════════════════════════
  // OMBRES PRÉDÉFINIES (Shadows)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ombre douce pour les cartes
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: espresso.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Ombre pour les boutons d'action
  static List<BoxShadow> buttonShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gradient pour overlay sur les images - marron espresso
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xE62D2420), // darkRoast 90% opacité
    ],
    stops: [0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONS STANDARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Border radius standard pour les cartes
  static const double cardRadius = 24.0;

  /// Border radius pour les boutons
  static const double buttonRadius = 20.0;

  /// Border radius pour les chips/pills
  static const double pillRadius = 50.0;
}

/// =============================================================================
/// DARK MODE COLORS - Palette sombre premium
/// =============================================================================

class CoffeeColorsDark {
  CoffeeColorsDark._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FONDS (Backgrounds)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fond principal dark - Espresso profond
  static const Color background = Color(0xFF1A1412);

  /// Fond des cartes dark - Brun chaud
  static const Color cardBackground = Color(0xFF2D2420);

  /// Surface surélevée
  static const Color surface = Color(0xFF3D322A);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS (CTA & Interactions) - MARRON FONCÉ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Action principale - Marron café (plus lumineux pour dark mode)
  static const Color caramelBronze = Color(0xFF8D6E63);

  /// Action secondaire - Marron moyen lumineux
  static const Color terracotta = Color(0xFFA1887F);

  /// Action négative
  static const Color stoneGrey = Color(0xFF9B9188);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXTES (Typography)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Titres et texte principal - Crème clair
  static const Color textPrimary = Color(0xFFF5F0E8);

  /// Sous-titres - Crème atténué
  static const Color textSecondary = Color(0xFFB5A99A);

  /// Texte désactivé
  static const Color textDisabled = Color(0xFF7A6B5B);

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bordures dark
  static const Color border = Color(0xFF4A3D35);

  /// Overlay
  static const Color overlay = Color(0xCC000000);

  // ═══════════════════════════════════════════════════════════════════════════
  // OMBRES
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> buttonShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
