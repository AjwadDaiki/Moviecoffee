import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/movie.dart';
import 'app_ui_components.dart';

class MatchAnimationDialog extends StatefulWidget {
  final String partnerUsername;
  final Movie movie;

  const MatchAnimationDialog({
    super.key,
    required this.partnerUsername,
    required this.movie,
  });

  @override
  State<MatchAnimationDialog> createState() => _MatchAnimationDialogState();
}

class _MatchAnimationDialogState extends State<MatchAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _scaleController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Confettis en arrière-plan
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_confettiController.value),
                child: Container(),
              );
            },
          ),

          // Contenu principal
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de match
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titre
                  Text(
                    "IT'S A MATCH!",
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coffeeDark,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Message
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      children: [
                        const TextSpan(text: "Vous et "),
                        TextSpan(
                          text: widget.partnerUsername,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const TextSpan(text: " aimez tous les deux"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Film
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.bgCream,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.movie.posterPath,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 90,
                                color: AppColors.coffeeDark,
                                child: const Icon(
                                  Icons.movie,
                                  color: AppColors.accentOrange,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.movie.title.fr,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.movie.formattedRuntime,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Bouton
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Continuer",
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour les confettis
class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.pink,
      Colors.purple,
      AppColors.accentOrange,
    ];

    final random = math.Random(42); // Seed fixe pour animation consistante

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -50.0;
      final endY = size.height + 50;
      final y = startY + (endY - startY) * progress;

      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final rotation = progress * 4 * math.pi + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Dessiner un petit rectangle comme confetti
      canvas.drawRect(
        const Rect.fromLTWH(-5, -2, 10, 4),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
