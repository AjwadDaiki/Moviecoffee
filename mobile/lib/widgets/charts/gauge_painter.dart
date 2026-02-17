import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter pour une jauge circulaire (style speedometer)
/// Amelioration : gradient optionnel + animation fluide + marqueurs visuels
class GaugePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final double animationProgress; // Animation de remplissage
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool showGradient;

  GaugePainter({
    required this.progress,
    this.animationProgress = 1.0,
    this.trackColor = const Color(0xFFEFE6DD), // Beige creme
    this.progressColor = const Color(0xFF6A4A3F), // Marron cafe
    this.strokeWidth = 25.0,
    this.showGradient = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // On dessine un arc de 270 degres pour un rendu type gauge.
    const startAngle = math.pi * 0.75; // 135 degres
    const totalSweepAngle = math.pi * 1.5; // 270 degres

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweepAngle,
      false,
      trackPaint,
    );

    final progressSweepAngle = totalSweepAngle * progress * animationProgress;

    if (showGradient) {
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + progressSweepAngle,
        colors: const [Color(0xFF3E2723), Color(0xFF6A4A3F)],
        stops: const [0.0, 1.0],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweepAngle,
        false,
        progressPaint,
      );
    } else {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweepAngle,
        false,
        progressPaint,
      );
    }

    _drawTicks(canvas, center, radius, startAngle, totalSweepAngle);
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double totalSweepAngle,
  ) {
    final tickPaint = Paint()
      ..color = const Color(0xFF3E2723).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i <= 4; i++) {
      final angle = startAngle + (totalSweepAngle * i / 4);
      final innerRadius = radius - strokeWidth / 2 - 5;
      final outerRadius = radius + strokeWidth / 2 + 5;

      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationProgress != animationProgress;
  }
}
