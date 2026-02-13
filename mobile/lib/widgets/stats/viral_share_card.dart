import 'package:flutter/material.dart';

/// =============================================================================
/// VIRAL SHARE CARD - Carte de partage premium (Format Story 1080x1920)
/// =============================================================================
/// Style: Spotify Wrapped / Premium Coffee Theme
/// Modes: SOLO (stats perso) et DUO (compatibilité couple)
/// =============================================================================

class ViralShareCard extends StatelessWidget {
  final bool isDuoMode;

  // Données SOLO
  final String? topGenre;
  final int? totalMinutes;
  final String? favoriteMovie;

  // Données DUO
  final String? userName;
  final String? partnerName;
  final int? matchPercentage;
  final String? coupleGenre;

  const ViralShareCard.solo({
    super.key,
    required this.topGenre,
    required this.totalMinutes,
    required this.favoriteMovie,
  })  : isDuoMode = false,
        userName = null,
        partnerName = null,
        matchPercentage = null,
        coupleGenre = null;

  const ViralShareCard.duo({
    super.key,
    required this.userName,
    required this.partnerName,
    required this.matchPercentage,
    required this.coupleGenre,
  })  : isDuoMode = true,
        topGenre = null,
        totalMinutes = null,
        favoriteMovie = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDuoMode
              ? [
                  const Color(0xFF2D1F14), // Marron très foncé
                  const Color(0xFF4E342E), // Marron expresso
                  const Color(0xFF6D4C41), // Marron café
                  const Color(0xFF8D6E63), // Marron caramel
                ]
              : [
                  const Color(0xFF1A120B), // Presque noir café
                  const Color(0xFF3E2723), // Marron foncé
                  const Color(0xFF5D4037), // Marron moyen
                  const Color(0xFF6D4C41), // Marron café
                ],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs en arrière-plan
          ..._buildBackgroundCircles(),

          // Grain de café stylisé en filigrane
          Positioned.fill(
            child: CustomPaint(
              painter: _CoffeePatternPainter(),
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
            child: Column(
              children: [
                // Header avec logo
                _buildHeader(),
                const SizedBox(height: 60),

                // Contenu principal
                Expanded(
                  child: isDuoMode ? _buildDuoContent() : _buildSoloContent(),
                ),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      // Grand cercle en haut à droite
      Positioned(
        top: -200,
        right: -150,
        child: Container(
          width: 600,
          height: 600,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Cercle en bas à gauche
      Positioned(
        bottom: -100,
        left: -200,
        child: Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Petit cercle décoratif
      Positioned(
        top: 400,
        left: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icône café
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: const Center(
            child: Text(
              "☕",
              style: TextStyle(fontSize: 60),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Nom de l'app
        const Text(
          "MoovieCoffee",
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            fontFamily: 'RecoletaAlt',
            color: Colors.white,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 15),
        // Sous-titre
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            isDuoMode ? "NOTRE BILAN CINÉ" : "MON BILAN CINÉ",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoloContent() {
    final hours = (totalMinutes ?? 0) ~/ 60;
    final minutes = (totalMinutes ?? 0) % 60;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stat principale : Genre favori
        _buildMainStatCard(
          emoji: _getGenreEmoji(topGenre ?? ""),
          label: "GENRE FAVORI",
          value: topGenre ?? "Inconnu",
        ),
        const SizedBox(height: 60),

        // Stats secondaires en ligne
        Row(
          children: [
            Expanded(
              child: _buildSecondaryStatCard(
                emoji: "⏱️",
                value: "${hours}h${minutes.toString().padLeft(2, '0')}",
                label: "de films",
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _buildSecondaryStatCard(
                emoji: "⭐",
                value: favoriteMovie ?? "Aucun",
                label: "coup de cœur",
                isText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDuoContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Noms du couple
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNameBadge(userName ?? "Moi"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE57373).withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  "❤️",
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
            _buildNameBadge(partnerName ?? "Partenaire"),
          ],
        ),
        const SizedBox(height: 80),

        // Pourcentage de compatibilité (HERO)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 70),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFD700)],
                ).createShader(bounds),
                child: Text(
                  "${matchPercentage ?? 0}%",
                  style: const TextStyle(
                    fontSize: 180,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "COMPATIBILITÉ",
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RecoletaAlt',
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),

        // Genre de couple
        if (coupleGenre != null)
          _buildSecondaryStatCard(
            emoji: _getGenreEmoji(coupleGenre!),
            value: coupleGenre!,
            label: "notre genre préféré",
            isText: true,
            fullWidth: true,
          ),
      ],
    );
  }

  Widget _buildNameBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          fontFamily: 'RecoletaAlt',
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainStatCard({
    required String emoji,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 140),
          ),
          const SizedBox(height: 30),
          Text(
            label,
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w800,
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatCard({
    required String emoji,
    required String value,
    required String label,
    bool isText = false,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 35),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: isText ? 38 : 55,
              fontWeight: FontWeight.w700,
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 28,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Ligne décorative
        Container(
          width: 150,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 35),
        // CTA
        Text(
          "Découvre tes stats sur",
          style: TextStyle(
            fontSize: 35,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        // Badge app
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "☕",
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 15),
              const Text(
                "MoovieCoffee",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'RecoletaAlt',
                  color: Color(0xFF3E2723),
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGenreEmoji(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return '💥';
      case 'comédie':
      case 'comedie':
        return '😂';
      case 'drame':
        return '🎭';
      case 'science-fiction':
      case 'science fiction':
        return '🚀';
      case 'horreur':
        return '👻';
      case 'romance':
        return '💕';
      case 'thriller':
        return '🔪';
      case 'documentaire':
        return '📽️';
      case 'animation':
        return '🎨';
      case 'aventure':
        return '🗺️';
      case 'fantastique':
      case 'fantasy':
        return '🧙';
      case 'guerre':
        return '⚔️';
      case 'histoire':
        return '📜';
      case 'musique':
        return '🎵';
      case 'mystère':
        return '🔍';
      case 'familial':
        return '👨‍👩‍👧‍👦';
      case 'crime':
        return '🔫';
      case 'western':
        return '🤠';
      default:
        return '🎬';
    }
  }
}

/// Pattern de fond avec des cercles et lignes subtiles
class _CoffeePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dessiner des cercles concentriques subtils
    final centerX = size.width * 0.7;
    final centerY = size.height * 0.3;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        i * 80.0,
        paint,
      );
    }

    // Quelques lignes diagonales
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final y = i * (size.height / 10);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 200),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
