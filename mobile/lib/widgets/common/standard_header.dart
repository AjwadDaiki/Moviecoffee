import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_ui_components.dart';

/// Header standardisé pour toute l'application
/// Gère automatiquement le SafeArea et évite les espaces inutiles
class StandardHeader extends StatelessWidget {
  final bool showNotificationIcon;
  final VoidCallback? onNotificationTap;

  const StandardHeader({
    super.key,
    this.showNotificationIcon = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Moovie Coffee
          Row(
            children: [
              SvgPicture.asset(
                'assets/logoB.svg',
                height: 36,
              ),
              const SizedBox(width: 10),
              const Text(
                'MoovieCoffee',
                style: TextStyle(
                  fontFamily: 'HolyCream',
                  fontSize: 24,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          // Icône notification (optionnelle)
          if (showNotificationIcon)
            GestureDetector(
              onTap: onNotificationTap,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                radius: 20,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.coffeeDark,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
