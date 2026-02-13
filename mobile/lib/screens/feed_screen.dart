import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../services/collection_notifier.dart';

/// =============================================================================
/// FEED SCREEN 2026 - Design Moderne Premium
/// =============================================================================

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  CardSwiperController _controller = CardSwiperController();

  List<Movie> _movies = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _errorMessage;
  bool _hasReachedEnd = false;

  // Feed social (removed - now only in community_screen)

  // Override pour le bouton "Déjà vu"
  String? _nextActionOverride;
  double? _nextRatingOverride;

  // FILTRES
  String _selectedGenre = "Tous";
  int? _selectedYear;

  final List<String> _genres = [
    "Tous", "Action", "Comédie", "Drame", "Science-Fiction",
    "Horreur", "Romance", "Thriller", "Documentaire", "Animation",
  ];

  final List<int> _years = [2024, 2023, 2022, 2021, 2020, 2019, 2018];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasReachedEnd = false;
    });

    try {
      final movies = await _api.fetchFeed(
        genre: _selectedGenre != "Tous" ? _selectedGenre : null,
        year: _selectedYear,
      );
      if (mounted) {
        // Recréer le controller pour réinitialiser le swiper
        _controller.dispose();
        _controller = CardSwiperController();

        setState(() {
          _movies = movies;
          _isLoading = false;
          _currentIndex = 0;
          _hasReachedEnd = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _handleAction(int index, String action, {double? rating}) async {
    if (index < 0 || index >= _movies.length) return;

    final movie = _movies[index];

    try {
      // Utiliser v3 API qui retourne automatiquement les nouveaux matchs
      final result = await _api.sendActionV3(movie.tmdbId, action, rating: rating);

      // Si nouveaux matchs, afficher badge discret
      if (result != null &&
          result['new_matches'] != null &&
          (result['new_matches'] as List).isNotEmpty &&
          mounted) {
        final matches = result['new_matches'] as List;
        _showDiscreteMatchBadge(matches);
      }

      // Notifier les autres écrans pour rafraîchir
      collectionNotifier.notifyCollectionChanged();
    } on ApiException catch (e) {
      // Debug uniquement
      debugPrint("❌ Action failed: ${e.message}");
    }
  }

  void _showDiscreteMatchBadge(List<dynamic> matches) {
    final count = matches.length;
    final screenWidth = MediaQuery.of(context).size.width;

    // Badge minimaliste et discret
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              count == 1 ? 'Nouveau match !' : '$count matchs !',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(
          bottom: 220,
          left: screenWidth * 0.28,
          right: screenWidth * 0.28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    HapticFeedback.mediumImpact();
  }

  void _triggerLike() {
    if (_hasReachedEnd) return;
    HapticFeedback.mediumImpact();
    _nextActionOverride = "LIKE";
    _controller.swipe(CardSwiperDirection.right);
  }

  void _triggerDislike() {
    if (_hasReachedEnd) return;
    HapticFeedback.lightImpact();
    _nextActionOverride = "DISLIKE";
    _controller.swipe(CardSwiperDirection.left);
  }

  void _triggerSeen() {
    if (_hasReachedEnd) return;
    if (_currentIndex >= _movies.length) return;
    HapticFeedback.lightImpact();
    // Show quick rating before marking as seen
    _showQuickRating();
  }

  void _showQuickRating() {
    double selectedRating = 3.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Votre note',
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentIndex < _movies.length ? _movies[_currentIndex].title.fr : '',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                // Star rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starValue = (i + 1).toDouble();
                    final isHalf = selectedRating == starValue - 0.5;
                    final isFull = selectedRating >= starValue;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedRating = isFull && !isHalf
                              ? starValue - 0.5
                              : starValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isHalf
                              ? Icons.star_half_rounded
                              : isFull
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                          color: isFull || isHalf
                              ? const Color(0xFFFFC107)
                              : AppTheme.border,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${selectedRating.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          // Mark as seen without rating
                          _nextActionOverride = "SEEN";
                          _nextRatingOverride = null;
                          _controller.swipe(CardSwiperDirection.top);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Center(
                            child: Text(
                              'Sans note',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _nextActionOverride = "SEEN";
                          _nextRatingOverride = selectedRating;
                          _controller.swipe(CardSwiperDirection.top);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accent, AppTheme.accentDark],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.shadowAccent(AppTheme.accent),
                          ),
                          child: const Center(
                            child: Text(
                              'Confirmer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDetails(Movie movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MovieDetailSheet(movie: movie),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterModal(
        selectedGenre: _selectedGenre,
        selectedYear: _selectedYear,
        genres: _genres,
        years: _years,
        onApply: (genre, year) {
          setState(() {
            _selectedGenre = genre;
            _selectedYear = year;
          });
          _loadFeed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bottomNavHeight = 80.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER - Titre + Counter + Filtre
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Découvrir",
                    style: AppTheme.headerOnCoffee,
                  ),
                ),
                _FilterButton(onTap: _showFilterModal),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // CONTENU PRINCIPAL
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: _buildContent(bottomNavHeight + bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double bottomSpace) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_movies.isEmpty || _hasReachedEnd) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // ZONE SWIPER - Plus de place pour les cartes
        Positioned.fill(
          bottom: bottomSpace + 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSwiper(),
          ),
        ),

        // ZONE ACTIONS - Vraiment collés à la nav bar
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomSpace - 20,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildSwiper() {
    final int cardsToDisplay = _movies.length.clamp(1, 3);

    return CardSwiper(
      controller: _controller,
      cardsCount: _movies.length,
      numberOfCardsDisplayed: cardsToDisplay,
      scale: 0.92,
      padding: EdgeInsets.zero,
      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
        horizontal: true,
        vertical: true,
      ),
      onEnd: () {
        // Quand toutes les cartes sont swipées
        setState(() => _hasReachedEnd = true);
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        setState(() => _currentIndex = currentIndex ?? 0);

        String action;
        if (_nextActionOverride != null) {
          action = _nextActionOverride!;
        } else if (direction == CardSwiperDirection.right) {
          action = "LIKE";
        } else if (direction == CardSwiperDirection.top) {
          action = "SEEN";
        } else {
          action = "DISLIKE";
        }

        final rating = _nextRatingOverride;
        _nextActionOverride = null;
        _nextRatingOverride = null;

        _handleAction(previousIndex, action, rating: rating);
        return true;
      },
      cardBuilder: (context, index, _, __) {
        if (index >= _movies.length) return const SizedBox();
        return GestureDetector(
          onTap: () => _openDetails(_movies[index]),
          child: _ModernMovieCard(movie: _movies[index]),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DISLIKE - LIKE (ligne principale)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              icon: Icons.close_rounded,
              size: 60,
              color: AppTheme.surface,
              iconColor: AppTheme.negative,
              borderColor: AppTheme.border,
              onTap: _triggerDislike,
            ),
            const SizedBox(width: 40),
            _ActionButton(
              icon: Icons.favorite_rounded,
              size: 72,
              color: AppTheme.accent,
              iconColor: Colors.white,
              isAccent: true,
              onTap: _triggerLike,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // BOUTON "DÉJÀ VU" - Centré en dessous
        _SeenButton(onTap: _triggerSeen),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Chargement...",
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                size: 48,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasReachedEnd ? "Vous avez tout vu !" : "Aucun film",
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _hasReachedEnd
                  ? "Rechargez pour découvrir d'autres films"
                  : "Modifiez vos filtres ou revenez plus tard",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ModernButton(
              label: _hasReachedEnd ? "Recharger" : "Modifier les filtres",
              icon: _hasReachedEnd ? Icons.refresh_rounded : Icons.tune_rounded,
              onTap: _hasReachedEnd ? _loadFeed : _showFilterModal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text("Erreur de connexion", style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Une erreur est survenue",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ModernButton(
              label: "Réessayer",
              icon: Icons.refresh_rounded,
              onTap: _loadFeed,
            ),
          ],
        ),
      ),
    );
  }

}

/// =============================================================================
/// FILTER BUTTON - Bouton filtre moderne
/// =============================================================================

class _FilterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FilterButton({required this.onTap});

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.accentDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.shadowAccent(AppTheme.accent),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// MODERN MOVIE CARD
/// =============================================================================

class _ModernMovieCard extends StatelessWidget {
  final Movie movie;

  const _ModernMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // IMAGE
            CachedNetworkImage(
              imageUrl: movie.posterPath,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.border,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.surfaceDark,
                child: const Center(
                  child: Icon(Icons.movie_rounded, size: 64, color: AppTheme.accent),
                ),
              ),
            ),

            // OVERLAY GRADIENT
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.imageOverlay),
            ),

            // INFOS FILM
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2D1F14).withValues(alpha: 0.0),
                          const Color(0xFF2D1F14).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title.fr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _GlassBadge(
                              icon: Icons.star_rounded,
                              label: movie.voteAverage.toStringAsFixed(1),
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            _GlassBadge(
                              icon: Icons.schedule_rounded,
                              label: movie.formattedRuntime,
                            ),
                            if (movie.releaseDate.length >= 4) ...[
                              const SizedBox(width: 8),
                              _GlassBadge(
                                icon: Icons.calendar_today_rounded,
                                label: movie.releaseDate.substring(0, 4),
                              ),
                            ],
                            if (movie.genres.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  movie.genres.first,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // INDICATEUR DÉTAILS
            Positioned(
              top: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.9), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Détails",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// GLASS BADGE
/// =============================================================================

class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _GlassBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// =============================================================================
/// ACTION BUTTON
/// =============================================================================

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color iconColor;
  final Color? borderColor;
  final bool isAccent;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.iconColor,
    this.borderColor,
    this.isAccent = false,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: widget.isAccent
                ? AppTheme.shadowAccent(widget.color)
                : AppTheme.shadowMedium,
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: widget.size * 0.4,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// SEEN BUTTON
/// =============================================================================

class _SeenButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SeenButton({required this.onTap});

  @override
  State<_SeenButton> createState() => _SeenButtonState();
}

class _SeenButtonState extends State<_SeenButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppTheme.border, width: 1),
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    "Déjà vu",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// MODERN BUTTON
/// =============================================================================

class _ModernButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.shadowAccent(AppTheme.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
/// FILTER MODAL
/// =============================================================================

class _FilterModal extends StatefulWidget {
  final String selectedGenre;
  final int? selectedYear;
  final List<String> genres;
  final List<int> years;
  final Function(String genre, int? year) onApply;

  const _FilterModal({
    required this.selectedGenre,
    required this.selectedYear,
    required this.genres,
    required this.years,
    required this.onApply,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  late String _genre;
  late int? _year;

  @override
  void initState() {
    super.initState();
    _genre = widget.selectedGenre;
    _year = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filtres", style: AppTheme.titleLarge),
                if (_genre != "Tous" || _year != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _genre = "Tous";
                      _year = null;
                    }),
                    child: Text(
                      "Réinitialiser",
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.accent),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Genre", style: AppTheme.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.genres.map((genre) {
                      return _PillChip(
                        label: genre,
                        isSelected: _genre == genre,
                        onTap: () => setState(() => _genre = genre),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Text("Année", style: AppTheme.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillChip(
                        label: "Toutes",
                        isSelected: _year == null,
                        onTap: () => setState(() => _year = null),
                      ),
                      ...widget.years.map((year) {
                        return _PillChip(
                          label: year.toString(),
                          isSelected: _year == year,
                          onTap: () => setState(() => _year = year),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: _ModernButton(
                label: "Appliquer",
                icon: Icons.check_rounded,
                onTap: () {
                  Navigator.pop(context);
                  widget.onApply(_genre, _year);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationMedium,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.border,
            width: 1,
          ),
          boxShadow: isSelected ? AppTheme.shadowAccent(AppTheme.accent) : AppTheme.shadowSmall,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// MOVIE DETAIL SHEET
/// =============================================================================

class _MovieDetailSheet extends StatelessWidget {
  final Movie movie;

  const _MovieDetailSheet({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title.fr, style: AppTheme.displayMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _DetailBadge(
                        icon: Icons.star_rounded,
                        label: movie.voteAverage.toStringAsFixed(1),
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 12),
                      _DetailBadge(
                        icon: Icons.schedule_rounded,
                        label: movie.formattedRuntime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (movie.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: movie.genres.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            genre,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text("Synopsis", style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(movie.overview.fr, style: AppTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bgColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: bgColor, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
