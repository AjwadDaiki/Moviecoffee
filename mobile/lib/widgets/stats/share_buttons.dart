import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import 'viral_share_card.dart';

// Import conditionnel pour le partage
import 'share_platform_stub.dart'
    if (dart.library.io) 'share_platform_io.dart'
    if (dart.library.html) 'share_platform_web.dart' as platform;

/// Widget avec boutons de partage (SOLO et DUO)
class ShareButtons extends StatefulWidget {
  // Données SOLO
  final String? topGenre;
  final int totalMinutes;
  final String? favoriteMovie;

  // Données DUO
  final String? partnerName;
  final double matchPercentage;
  final String? coupleGenre;

  const ShareButtons({
    super.key,
    this.topGenre,
    required this.totalMinutes,
    this.favoriteMovie,
    this.partnerName,
    this.matchPercentage = 0.0,
    this.coupleGenre,
  });

  @override
  State<ShareButtons> createState() => _ShareButtonsState();
}

class _ShareButtonsState extends State<ShareButtons> {
  bool _isGenerating = false;

  Future<void> _shareStory({required bool isDuo}) async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      // Créer le widget à capturer
      final cardWidget = isDuo
          ? ViralShareCard.duo(
              userName: "Moi",
              partnerName: widget.partnerName ?? "Partenaire",
              matchPercentage: widget.matchPercentage.toInt(),
              coupleGenre: widget.coupleGenre ?? widget.topGenre,
            )
          : ViralShareCard.solo(
              topGenre: widget.topGenre ?? "Inconnu",
              totalMinutes: widget.totalMinutes,
              favoriteMovie: widget.favoriteMovie ?? "Aucun",
            );

      // Capturer l'image avec OverlayEntry (SANS deadlock)
      final Uint8List? pngBytes = await _captureWidgetToImage(cardWidget);

      if (pngBytes == null) {
        throw Exception("Impossible de capturer l'image");
      }

      // Partager ou télécharger selon la plateforme
      final fileName = 'moovie_${isDuo ? "duo" : "solo"}_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = isDuo
          ? 'Découvrez notre compatibilité sur MoovieCoffee ❤️☕'
          : 'Mes stats ciné sur MoovieCoffee ☕🎬';

      await platform.shareOrDownload(pngBytes, fileName, shareText);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  kIsWeb ? "Image téléchargée !" : "Partagé avec succès !",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Share error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Erreur: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// Capture un widget en image PNG via OverlayEntry (SANS deadlock)
  Future<Uint8List?> _captureWidgetToImage(Widget widget) async {
    final completer = Completer<Uint8List?>();
    final GlobalKey repaintKey = GlobalKey();

    // Wrapper le widget avec tout le contexte nécessaire
    final wrappedWidget = RepaintBoundary(
      key: repaintKey,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: widget,
          ),
        ),
      ),
    );

    // Créer l'OverlayEntry positionné hors écran
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -5000,
        top: -5000,
        child: SizedBox(
          width: 1080,
          height: 1920,
          child: wrappedWidget,
        ),
      ),
    );

    // Insérer dans l'overlay
    final overlay = Overlay.of(context);
    overlay.insert(overlayEntry);

    // Attendre le rendu puis capturer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Attendre que le widget soit complètement rendu
        await Future.delayed(const Duration(milliseconds: 300));

        final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

        if (boundary == null) {
          overlayEntry.remove();
          completer.complete(null);
          return;
        }

        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        overlayEntry.remove();

        if (byteData != null) {
          completer.complete(byteData.buffer.asUint8List());
        } else {
          completer.complete(null);
        }
      } catch (e) {
        overlayEntry.remove();
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final hasDuoData = widget.partnerName != null && widget.partnerName != "Aucun";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Partagez vos stats", style: AppTheme.titleMedium),
        const SizedBox(height: 15),

        // Bouton SOLO
        _ShareButton(
          icon: Icons.person_rounded,
          title: "Mon Profil Ciné",
          subtitle: kIsWeb ? "Télécharger l'image" : "Partager sur les réseaux",
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentDark],
          ),
          isLoading: _isGenerating,
          onTap: _isGenerating ? null : () => _shareStory(isDuo: false),
        ),

        if (hasDuoData) ...[
          const SizedBox(height: 15),
          // Bouton DUO
          _ShareButton(
            icon: Icons.favorite_rounded,
            title: "Notre Duo Ciné",
            subtitle: kIsWeb ? "Télécharger l'image" : "Partager sur les réseaux",
            gradient: const LinearGradient(
              colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
            ),
            isLoading: _isGenerating,
            onTap: _isGenerating ? null : () => _shareStory(isDuo: true),
          ),
        ],
      ],
    );
  }
}

/// Bouton de partage moderne
class _ShareButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ShareButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.onTap != null ? widget.gradient : null,
            color: widget.onTap == null ? AppTheme.border : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    kIsWeb ? Icons.download_rounded : Icons.share_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
