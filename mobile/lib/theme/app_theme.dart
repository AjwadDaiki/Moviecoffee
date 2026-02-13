import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

/// =============================================================================
/// APP THEME 2026 - Design System Premium Moderne
/// =============================================================================
/// Style : iOS Design Award / Glassmorphism / Soft UI / Apple HIG
/// Inspiration : Linear, Vercel, Arc Browser, Apple Music
/// Police : DM Sans (moderne, chaleureuse, lisible)
/// =============================================================================

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES - Palette "Café Espresso" Premium
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fond principal - Crème café doux
  static const Color background = Color(0xFFF5F0E8);

  /// Fond secondaire - Blanc cassé
  static const Color surface = Color(0xFFFFFBF7);

  /// Fond sombre - Espresso profond
  static const Color surfaceDark = Color(0xFF2D1F14);

  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS D'ACCENT - Palette Marron Café Foncé
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accent principal - Marron café foncé
  static const Color accent = Color(0xFF5D4037);

  /// Accent clair - Marron moyen
  static const Color accentLight = Color(0xFF8D6E63);

  /// Accent très clair - Beige café
  static const Color accentSoft = Color(0xFFEFEBE9);

  /// Accent sombre - Espresso très foncé
  static const Color accentDark = Color(0xFF3E2723);

  /// Couleur positive (like, succès)
  static const Color positive = Color(0xFF10B981);

  /// Couleur négative (dislike, erreur)
  static const Color negative = Color(0xFF78716C);

  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS DE TEXTE - Hiérarchie café (harmonisé avec CoffeeColors)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Texte principal - Espresso (identique à CoffeeColors.espresso)
  static const Color textPrimary = Color(0xFF3D2B1F);

  /// Texte secondaire - Moka (identique à CoffeeColors.moka)
  static const Color textSecondary = Color(0xFF7A6B5B);

  /// Texte tertiaire - Steam Milk (identique à CoffeeColors.steamMilk)
  static const Color textTertiary = Color(0xFFB5A99A);

  /// Texte sur accent - Blanc
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS UTILITAIRES (harmonisé avec CoffeeColors)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bordures subtiles (identique à CoffeeColors.creamBorder)
  static const Color border = Color(0xFFE8E0D5);

  /// Bordures sur glass
  static const Color borderGlass = Color(0x1AFFFFFF);

  /// Dividers
  static const Color divider = Color(0xFFF5F0E8);

  /// Overlay sombre (identique à CoffeeColors.overlay)
  static const Color overlay = Color(0x99000000);

  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS POUR LES VAGUES CAFÉ (marron foncé espresso)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color waveColor1 = Color(0x205D4037); // Marron café foncé transparent
  static const Color waveColor2 = Color(0x154E342E); // Marron plus foncé transparent
  static const Color waveColor3 = Color(0x103E2723); // Espresso profond transparent

  // ═══════════════════════════════════════════════════════════════════════════
  // EFFETS GLASSMORPHISM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Décoration Glass standard
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: borderGlass,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: textPrimary.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: -8,
      ),
    ],
  );

  /// Décoration Glass pour les cartes
  static BoxDecoration glassCard({double radius = 24}) => BoxDecoration(
    color: surface.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: border.withValues(alpha: 0.5),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: textPrimary.withValues(alpha: 0.06),
        blurRadius: 32,
        offset: const Offset(0, 12),
        spreadRadius: -8,
      ),
    ],
  );

  /// Décoration Glass pour les boutons
  static BoxDecoration glassButton({bool isActive = false}) => BoxDecoration(
    color: isActive
        ? accent
        : surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isActive
          ? accent.withValues(alpha: 0.3)
          : border.withValues(alpha: 0.5),
      width: 1,
    ),
    boxShadow: isActive ? [
      BoxShadow(
        color: accent.withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
    ] : [
      BoxShadow(
        color: textPrimary.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: -4,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // OMBRES PRÉDÉFINIES
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> shadowAccent(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gradient pour overlay sur les images - nuances marron
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x403E2723), // Marron expresso transparent
      Color(0xCC2D1F14), // Marron nav bar profond
    ],
    stops: [0.3, 0.6, 1.0],
  );

  /// Gradient accent
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHIE - Inter (Police moderne géométrique)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Style titre principal (Hero)
  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
    color: textPrimary,
  );

  /// Style titre (Page title)
  static TextStyle get displayMedium => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
    color: textPrimary,
  );

  /// Style sous-titre
  static TextStyle get titleLarge => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.25,
    color: textPrimary,
  );

  /// Style titre de carte
  static TextStyle get titleMedium => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: textPrimary,
  );

  /// Style label
  static TextStyle get labelLarge => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  /// Style corps de texte
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.5,
    color: textSecondary,
  );

  /// Style corps secondaire
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: textSecondary,
  );

  /// Style caption
  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: textTertiary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHIE SUR FOND CAFÉ (texte blanc avec ombre)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Style header sur fond café - blanc avec ombre
  static TextStyle get headerOnCoffee => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
    color: Colors.white,
    shadows: [
      Shadow(
        color: const Color(0xFF2D1F14).withValues(alpha: 0.6),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
      Shadow(
        color: const Color(0xFF2D1F14).withValues(alpha: 0.3),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  );

  /// Style sous-titre sur fond café
  static TextStyle get subtitleOnCoffee => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: Colors.white.withValues(alpha: 0.85),
    shadows: [
      Shadow(
        color: const Color(0xFF2D1F14).withValues(alpha: 0.5),
        offset: const Offset(0, 1),
        blurRadius: 4,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONS STANDARDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
}

/// =============================================================================
/// EXTENSION POUR BACKDROP BLUR
/// =============================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final EdgeInsets? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.borderRadius = 24,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppTheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppTheme.borderGlass,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
