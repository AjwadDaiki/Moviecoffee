import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

/// Legacy - utilise désormais les valeurs CoffeeColors pour cohérence DA
class AppColors {
  static const Color bgCream = Color(0xFFF5F0E8); // CoffeeColors.latteCream
  static const Color coffeeDark = Color(0xFF3D2B1F); // CoffeeColors.espresso
  static const Color accentOrange = Color(0xFF5D4037); // CoffeeColors.caramelBronze (marron DA)
  static const Color textDark = Color(0xFF3D2B1F); // CoffeeColors.espresso

  static const Color coffeeReal = coffeeDark;
  static const Color bgDark = Color(0xFF2D2420); // CoffeeColors.darkRoast
  static const Color bgLight = Color(0xFFF5F0E8); // CoffeeColors.latteCream
  static const Color cardSurface = Color(0xFFFFFBF7); // CoffeeColors.milkFoam
  static const Color accentCaramel = accentOrange;
  static const Color accentAmbre = accentOrange;
  static const Color neonRed = Color(0xFFC62828);
}

class LatteBackground extends StatefulWidget {
  const LatteBackground({super.key});
  @override
  State<LatteBackground> createState() => _LatteBackgroundState();
}

class _LatteBackgroundState extends State<LatteBackground> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(painter: DeepCoffeePainter(_c.value), size: Size.infinite),
    );
  }
}

class DeepCoffeePainter extends CustomPainter {
  final double v;
  DeepCoffeePainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(AppColors.bgCream, BlendMode.src);
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.coffeeDark, AppColors.bgDark],
      ).createShader(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35));

    final path = Path();
    double baseHeight = size.height * 0.70;
    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, baseHeight + 12 * math.sin((x / size.width * 2 * math.pi) + v * 2 * math.pi));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant DeepCoffeePainter old) => true;
}

class MoovieHeader extends StatelessWidget {
  const MoovieHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      // HEADER COLLÉ : padding top = 0, seulement marges latérales et bottom
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Moovie Coffee",
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: 1.0
            )
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            child: const Icon(Icons.notifications_outlined, color: AppColors.coffeeDark),
          ),
        ],
      ),
    );
  }
}