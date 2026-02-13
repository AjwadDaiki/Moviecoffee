import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter pour un donut chart avec segments colorés
/// Amélioration : Animation progressive + labels au centre + ombres
class DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double animationProgress; // 0.0 -> 1.0
  final double strokeWidth;
  final bool showInnerLabel;
  final String? centerLabel;
  final TextStyle? centerLabelStyle;

  DonutChartPainter({
    required this.segments,
    this.animationProgress = 1.0,
    this.strokeWidth = 35.0,
    this.showInnerLabel = false,
    this.centerLabel,
    this.centerLabelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Calculer le total pour les pourcentages
    final total = segments.fold<double>(0, (sum, segment) => sum + segment.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2; // Commence en haut (12h)

    for (var segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi * animationProgress;

      // Ombre colorée douce (INITIATIVE : ombre légère pour profondeur)
      final shadowPaint = Paint()
        ..color = segment.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 2),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );

      // Arc principal
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Label central (INITIATIVE : texte centré avec style)
    if (showInnerLabel && centerLabel != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: centerLabel,
          style: centerLabelStyle ?? const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723), // Café
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.segments != segments;
  }
}

/// Modèle pour un segment du donut
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutSegment &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == value &&
          color == color;

  @override
  int get hashCode => label.hashCode ^ value.hashCode ^ color.hashCode;
}
