import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';

/// =============================================================================
/// MODERN HEADER - Header Ultra-Minimaliste 2026
/// =============================================================================
/// Style : Apple HIG, Linear, Arc Browser
/// Features : Glass effect, Logo animé, Actions contextuelles
/// =============================================================================

class ModernHeader extends StatelessWidget {
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final bool showAction;
  final String? subtitle;

  const ModernHeader({
    super.key,
    this.onActionTap,
    this.actionIcon,
    this.showAction = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // LOGO MODERNE - Icône + Texte avec gradient subtil
            // ═══════════════════════════════════════════════════════════════════
            Row(
              children: [
                // Logo container avec effet glass
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accent,
                        AppTheme.accentDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.shadowAccent(AppTheme.accent),
                  ),
                  child: const Center(
                    child: Text(
                      "M",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre avec shimmer subtil
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppTheme.textPrimary,
                          AppTheme.textSecondary,
                          AppTheme.textPrimary,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        "Movie Coffee",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // ═══════════════════════════════════════════════════════════════════
            // BOUTON D'ACTION - Effet Glass moderne
            // ═══════════════════════════════════════════════════════════════════
            if (showAction && actionIcon != null)
              _GlassActionButton(
                icon: actionIcon!,
                onTap: onActionTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// GLASS ACTION BUTTON - Bouton d'action avec effet glass
/// =============================================================================

class _GlassActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveDefault,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Icon(
                widget.icon,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// SECTION TITLE - Titre de section moderne
/// =============================================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.displayMedium,
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// =============================================================================
/// PILL BUTTON - Bouton pilule moderne
/// =============================================================================

class PillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    required this.onTap,
    this.activeColor,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveDefault,
        child: AnimatedContainer(
          duration: AppTheme.durationMedium,
          curve: AppTheme.curveDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor
                : AppTheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: 0.3)
                  : AppTheme.border,
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? AppTheme.shadowAccent(activeColor)
                : AppTheme.shadowSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppTheme.textOnAccent
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? AppTheme.textOnAccent
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// MODERN SEARCH BAR - Barre de recherche avec glass effect
/// =============================================================================

class ModernSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hint;
  final Widget? suffix;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hint = "Rechercher...",
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.search_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null) ...[
                suffix!,
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
