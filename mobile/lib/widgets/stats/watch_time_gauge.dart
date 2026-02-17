import 'package:flutter/material.dart';
import '../charts/gauge_painter.dart';
import '../../theme/coffee_colors.dart';

/// Circular gauge for watch time with animated progress.
class WatchTimeGauge extends StatefulWidget {
  final int totalMinutes;
  final String title;
  final int maxMinutes;
  final double? completionPercent; // 0..100 if provided

  const WatchTimeGauge({
    super.key,
    required this.totalMinutes,
    this.title = 'Temps de visionnage',
    this.maxMinutes = 10000,
    this.completionPercent,
  });

  @override
  State<WatchTimeGauge> createState() => _WatchTimeGaugeState();
}

class _WatchTimeGaugeState extends State<WatchTimeGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}min';
    }
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final hasCompletionPercent = widget.completionPercent != null;
    final completionPercent = hasCompletionPercent
        ? widget.completionPercent!.clamp(0.0, 100.0)
        : ((widget.totalMinutes / widget.maxMinutes).clamp(0.0, 1.0) * 100.0);
    final progress = (completionPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.milkFoam,
        borderRadius: BorderRadius.circular(CoffeeColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.terracotta.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: GaugePainter(
                          progress: progress,
                          animationProgress: _animation.value,
                          strokeWidth: 22,
                          showGradient: false,
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final animatedMinutes =
                                (widget.totalMinutes * _animation.value)
                                    .toInt();
                            return SizedBox(
                              width: 148,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatTime(animatedMinutes),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'RecoletaAlt',
                                    color: Color(0xFF4A3529),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'regarde',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CoffeeColors.moka,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CoffeeColors.terracotta.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hasCompletionPercent
                                ? '${completionPercent.toStringAsFixed(0)}% collection vue'
                                : '${completionPercent.toStringAsFixed(0)}% objectif',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'RecoletaAlt',
                              color: CoffeeColors.terracotta,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildAdditionalStats(),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats() {
    final totalHours = widget.totalMinutes ~/ 60;
    final totalDays = totalHours / 24;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CoffeeColors.latteCream,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.access_time,
            value: '$totalHours',
            label: 'heures',
          ),
          Container(width: 1, height: 30, color: CoffeeColors.creamBorder),
          _buildStatItem(
            icon: Icons.calendar_today,
            value: totalDays.toStringAsFixed(1),
            label: 'jours',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CoffeeColors.terracotta),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'RecoletaAlt',
                color: CoffeeColors.espresso,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: CoffeeColors.moka),
            ),
          ],
        ),
      ],
    );
  }
}
