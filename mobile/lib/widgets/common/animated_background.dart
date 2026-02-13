import 'package:flutter/material.dart';
import 'dart:math' as math;

/// =============================================================================
/// ANIMATED BACKGROUND - Fond "Vague Café" Liquide Premium
/// =============================================================================
/// Effet : Vagues café en haut ET en bas avec ombres
/// Style : Abstract, Fluid, Coffee Premium
/// =============================================================================

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // Plus fluide
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0E8), // CoffeeColors.latteCream
      child: Stack(
        children: [
          // VAGUES ANIMÉES (haut et bas)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CoffeeWavePainter(
                    animation1: _controller.value * 6,
                    animation2: _controller.value * 4.3,
                    animation3: _controller.value * 3.3,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          // CONTENU
          widget.child,
        ],
      ),
    );
  }
}

/// =============================================================================
/// COFFEE WAVE PAINTER - Vagues en haut ET en bas
/// =============================================================================

class _CoffeeWavePainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;

  // Couleurs café MARRON FONCÉ (espresso)
  static const Color wave1Color = Color(0xFF5D4037); // Marron café foncé
  static const Color wave2Color = Color(0xFF4E342E); // Marron plus foncé
  static const Color wave3Color = Color(0xFF3E2723); // Espresso profond

  // Ombres marron foncé
  static const Color shadow1Color = Color(0x405D4037);
  static const Color shadow2Color = Color(0x504E342E);
  static const Color shadow3Color = Color(0x603E2723);

  _CoffeeWavePainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ═══════════════════════════════════════════════════════════════════════
    // VAGUES DU HAUT (inversées)
    // ═══════════════════════════════════════════════════════════════════════

    // Vague 3 haut (la plus proche du bord)
    _drawTopWave(
      canvas, size,
      animation: animation3,
      waveColor: wave3Color,
      shadowColor: shadow3Color,
      amplitude: 15,
      frequency: 1.4,
      baseY: size.height * 0.12,
      phase: math.pi,
    );

    // Vague 2 haut
    _drawTopWave(
      canvas, size,
      animation: animation2,
      waveColor: wave2Color,
      shadowColor: shadow2Color,
      amplitude: 18,
      frequency: 1.2,
      baseY: size.height * 0.09,
      phase: math.pi / 3,
    );

    // Vague 1 haut (la plus proche du bord supérieur)
    _drawTopWave(
      canvas, size,
      animation: animation1,
      waveColor: wave1Color,
      shadowColor: shadow1Color,
      amplitude: 12,
      frequency: 1.6,
      baseY: size.height * 0.05,
      phase: math.pi / 2,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // VAGUES DU BAS (plus basses pour ne pas masquer la nav bar)
    // ═══════════════════════════════════════════════════════════════════════

    _drawBottomWave(
      canvas, size,
      animation: animation3,
      waveColor: wave3Color,
      shadowColor: shadow3Color,
      amplitude: 20,
      frequency: 1.2,
      baseY: size.height * 0.82,
      phase: 0,
    );

    _drawBottomWave(
      canvas, size,
      animation: animation2,
      waveColor: wave2Color,
      shadowColor: shadow2Color,
      amplitude: 22,
      frequency: 1.5,
      baseY: size.height * 0.89,
      phase: math.pi / 4,
    );

    _drawBottomWave(
      canvas, size,
      animation: animation1,
      waveColor: wave1Color,
      shadowColor: shadow1Color,
      amplitude: 25,
      frequency: 1.8,
      baseY: size.height * 0.95,
      phase: math.pi / 2,
    );
  }

  /// Dessine une vague en haut (inversée - part du haut)
  void _drawTopWave(
    Canvas canvas, Size size, {
    required double animation,
    required Color waveColor,
    required Color shadowColor,
    required double amplitude,
    required double frequency,
    required double baseY,
    required double phase,
  }) {
    // Ombre
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final shadowPath = _createTopWavePath(size,
      animation: animation, amplitude: amplitude, frequency: frequency,
      baseY: baseY + 4, phase: phase,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // Vague principale
    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final wavePath = _createTopWavePath(size,
      animation: animation, amplitude: amplitude, frequency: frequency,
      baseY: baseY, phase: phase,
    );
    canvas.drawPath(wavePath, wavePaint);

    // Reflet subtil
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, baseY + amplitude));
    canvas.drawPath(wavePath, highlightPaint);
  }

  /// Dessine une vague en bas
  void _drawBottomWave(
    Canvas canvas, Size size, {
    required double animation,
    required Color waveColor,
    required Color shadowColor,
    required double amplitude,
    required double frequency,
    required double baseY,
    required double phase,
  }) {
    // Ombre
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final shadowPath = _createBottomWavePath(size,
      animation: animation, amplitude: amplitude, frequency: frequency,
      baseY: baseY - 8, phase: phase,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // Vague principale
    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final wavePath = _createBottomWavePath(size,
      animation: animation, amplitude: amplitude, frequency: frequency,
      baseY: baseY, phase: phase,
    );
    canvas.drawPath(wavePath, wavePaint);

    // Reflet
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromLTWH(0, baseY - amplitude, size.width, amplitude * 2));
    canvas.drawPath(wavePath, highlightPaint);
  }

  /// Path pour vague du HAUT (part de y=0)
  Path _createTopWavePath(Size size, {
    required double animation,
    required double amplitude,
    required double frequency,
    required double baseY,
    required double phase,
  }) {
    final path = Path();
    path.moveTo(0, 0); // Part du coin supérieur gauche

    // Ligne vers le premier point de la vague
    path.lineTo(0, baseY);

    // Dessiner la vague
    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final waveValue = math.sin(
            (normalizedX * frequency * 2 * math.pi) +
                (animation * 2 * math.pi) +
                phase,
          ) * 0.6 +
          math.sin(
            (normalizedX * frequency * 1.5 * 2 * math.pi) +
                (animation * 2 * math.pi * 0.8) +
                phase * 1.3,
          ) * 0.4;
      final y = baseY + (waveValue * amplitude);
      path.lineTo(x, y);
    }

    // Fermer vers le coin supérieur droit
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  /// Path pour vague du BAS (part de y=height)
  Path _createBottomWavePath(Size size, {
    required double animation,
    required double amplitude,
    required double frequency,
    required double baseY,
    required double phase,
  }) {
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final waveValue = math.sin(
            (normalizedX * frequency * 2 * math.pi) +
                (animation * 2 * math.pi) +
                phase,
          ) * 0.6 +
          math.sin(
            (normalizedX * frequency * 1.5 * 2 * math.pi) +
                (animation * 2 * math.pi * 0.8) +
                phase * 1.3,
          ) * 0.4;
      final y = baseY + (waveValue * amplitude);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_CoffeeWavePainter oldDelegate) {
    return animation1 != oldDelegate.animation1 ||
        animation2 != oldDelegate.animation2 ||
        animation3 != oldDelegate.animation3;
  }
}
