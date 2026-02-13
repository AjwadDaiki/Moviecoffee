import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/collection/edit_rating_modal.dart';
import '../api_service.dart';
import '../models/movie.dart';
import '../services/collection_notifier.dart';
import 'library_screen.dart';
import 'movie_detail_screen.dart';

/// =============================================================================
/// COLLECTION SCREEN 2026 - Design Moderne Premium
/// =============================================================================
/// Style : iOS Design Award / Glassmorphism / Fluid Animations
/// Features : Recherche avancée, Filtres multiples, Grille premium
/// =============================================================================

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _toSee = [];
  List<Movie> _seen = [];
  List<Movie> _seenNotRated = []; // Vu mais pas noté
  List<Movie> _allMovies = []; // TOUS les films (v3)
  bool _isLoading = true;
  String? _errorMessage;

  // Filtres
  String _activeFilter = "all"; // all, toSee, seenNotRated, rated
  String _searchQuery = "";
  String _searchType = "title"; // title, actor, director, genre
  String _sortBy = "date"; // date, rating, title, vote, year, runtime, genre

  // Animation
  late AnimationController _filterAnimController;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCollection();

    // Écouter les changements de collection (depuis feed_screen)
    collectionNotifier.addListener(_onCollectionChanged);
  }

  void _onCollectionChanged() {
    _loadCollection();
  }

  @override
  void dispose() {
    collectionNotifier.removeListener(_onCollectionChanged);
    _searchController.dispose();
    _filterAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.fetchMyListV2();
      if (mounted) {
        setState(() {
          _toSee = result['to_see'] ?? [];
          _seen = result['seen'] ?? [];
          _allMovies = result['all'] ?? [];
          // Séparer les films vus non notés (rating == 0 ou null)
          _seenNotRated = _seen.where((m) => !m.isRated).toList();
          _applySorting();
          _isLoading = false;
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

  void _applySorting() {
    int Function(Movie, Movie) sorter;
    switch (_sortBy) {
      case 'rating':
        sorter = (a, b) => (b.userRating ?? 0).compareTo(a.userRating ?? 0);
        break;
      case 'title':
        sorter = (a, b) => a.title.fr.compareTo(b.title.fr);
        break;
      case 'vote':
        sorter = (a, b) => b.voteAverage.compareTo(a.voteAverage);
        break;
      case 'year':
        sorter = (a, b) {
          // Extraire l'année depuis releaseDate si disponible
          final yearA = a.releaseDate.isNotEmpty
              ? int.tryParse(a.releaseDate.split('-')[0]) ?? 0
              : 0;
          final yearB = b.releaseDate.isNotEmpty
              ? int.tryParse(b.releaseDate.split('-')[0]) ?? 0
              : 0;
          return yearB.compareTo(yearA);
        };
        break;
      case 'runtime':
        sorter = (a, b) => b.runtime.compareTo(a.runtime);
        break;
      case 'genre':
        sorter = (a, b) {
          final genreA = a.genres.isNotEmpty ? a.genres.first : '';
          final genreB = b.genres.isNotEmpty ? b.genres.first : '';
          return genreA.compareTo(genreB);
        };
        break;
      case 'date':
      default:
        // Garder l'ordre original (plus récent en premier)
        return;
    }
    _toSee.sort(sorter);
    _seen.sort(sorter);
    _seenNotRated.sort(sorter);
    _allMovies.sort(sorter);
  }

  List<Movie> get _filteredMovies {
    List<Movie> movies;

    // Appliquer le filtre de catégorie
    switch (_activeFilter) {
      case 'toSee':
        movies = _toSee;
        break;
      case 'seenNotRated':
        movies = _seenNotRated;
        break;
      case 'rated':
        movies = _seen.where((m) => m.isRated).toList();
        break;
      case 'all':
      default:
        movies = [..._toSee, ..._seen];
        break;
    }

    // Appliquer la recherche
    if (_searchQuery.isEmpty) return movies;

    return movies.where((movie) {
      final query = _searchQuery.toLowerCase();
      switch (_searchType) {
        case 'actor':
          return movie.actors.any((actor) => actor.toLowerCase().contains(query)) ||
                 movie.title.fr.toLowerCase().contains(query);
        case 'director':
          // Note: directors n'est pas dans le modèle, on cherche dans le titre pour l'instant
          return movie.title.fr.toLowerCase().contains(query);
        case 'genre':
          return movie.genres.any((genre) => genre.toLowerCase().contains(query)) ||
                 movie.title.fr.toLowerCase().contains(query);
        case 'title':
        default:
          return movie.title.fr.toLowerCase().contains(query);
      }
    }).toList();
  }

  void _openMovieDetail(Movie movie) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(
          tmdbId: movie.tmdbId,
          posterUrl: movie.posterPath,
          title: movie.title.fr,
        ),
      ),
    );
  }

  void _openRatingModal(Movie movie) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditRatingModal(
        movie: movie,
        onUpdated: _loadCollection,
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortModal(
        currentSort: _sortBy,
        onSortChanged: (sort) {
          setState(() {
            _sortBy = sort;
            _applySorting();
          });
        },
      ),
    );
  }

  void _showSearchTypeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchTypeModal(
        currentType: _searchType,
        onTypeChanged: (type) {
          setState(() {
            _searchType = type;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER SIMPLE - Titre + Tri
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Collection", style: AppTheme.headerOnCoffee),
                    if (_getSubtitle() != null)
                      Text(
                        _getSubtitle()!,
                        style: AppTheme.subtitleOnCoffee,
                      ),
                  ],
                ),
                Row(
                  children: [
                    _buildStats(),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LibraryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.accent,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SortButton(onTap: _showSortOptions),
                  ],
                ),
              ],
            ),
          ),

            // ═══════════════════════════════════════════════════════════════════
            // BARRE DE RECHERCHE MODERNE
            // ═══════════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ModernSearchBar(
                controller: _searchController,
                hint: _getSearchHint(),
                onChanged: (value) => setState(() => _searchQuery = value),
                onTypePressed: _showSearchTypeOptions,
                searchType: _searchType,
              ),
            ),
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════════════════
            // FILTRES CHIPS MODERNES
            // ═══════════════════════════════════════════════════════════════════
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: "Tout",
                    icon: Icons.grid_view_rounded,
                    isActive: _activeFilter == "all",
                    count: _toSee.length + _seen.length,
                    onTap: () => setState(() => _activeFilter = "all"),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: "À voir",
                    icon: Icons.bookmark_rounded,
                    isActive: _activeFilter == "toSee",
                    count: _toSee.length,
                    onTap: () => setState(() => _activeFilter = "toSee"),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: "À noter",
                    icon: Icons.rate_review_rounded,
                    isActive: _activeFilter == "seenNotRated",
                    count: _seenNotRated.length,
                    onTap: () => setState(() => _activeFilter = "seenNotRated"),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: "Notés",
                    icon: Icons.star_rounded,
                    isActive: _activeFilter == "rated",
                    count: _seen.where((m) => m.isRated).length,
                    onTap: () => setState(() => _activeFilter = "rated"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════════════════
            // GRILLE DE FILMS
            // ═══════════════════════════════════════════════════════════════════
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildMovieGrid(),
            ),
          ],
        ),
    );
  }

  String? _getSubtitle() {
    if (_sortBy != "date") {
      switch (_sortBy) {
        case 'rating':
          return "Tri par note";
        case 'title':
          return "Tri alphabétique";
        case 'vote':
          return "Tri par popularité";
        case 'year':
          return "Tri par année";
        case 'runtime':
          return "Tri par durée";
        case 'genre':
          return "Tri par genre";
      }
    }
    return null;
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'actor':
        return "Rechercher par acteur...";
      case 'director':
        return "Rechercher par réalisateur...";
      case 'genre':
        return "Rechercher par genre...";
      default:
        return "Rechercher un film...";
    }
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "${_toSee.length + _seen.length} films",
        style: AppTheme.caption.copyWith(
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
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
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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
            Text("Erreur de chargement", style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Une erreur est survenue",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ActionButton(
              label: "Réessayer",
              icon: Icons.refresh_rounded,
              onTap: _loadCollection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid() {
    final movies = _filteredMovies;

    if (movies.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCollection,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return _ModernMovieCard(
            movie: movies[index],
            showRating: _activeFilter == "rated",
            onTap: () => _openMovieDetail(movies[index]),
            onLongPress: () => _openRatingModal(movies[index]),
            onRateTap: () => _openRatingModal(movies[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_activeFilter) {
      case 'toSee':
        title = "Aucun film à voir";
        subtitle = "Likez des films pour les ajouter ici";
        icon = Icons.bookmark_outline_rounded;
        break;
      case 'seenNotRated':
        title = "Aucun film à noter";
        subtitle = "Les films marqués comme vus apparaîtront ici";
        icon = Icons.visibility_off_outlined;
        break;
      case 'rated':
        title = "Aucun film noté";
        subtitle = "Notez vos films vus pour les retrouver ici";
        icon = Icons.star_outline_rounded;
        break;
      default:
        title = _searchQuery.isNotEmpty ? "Aucun résultat" : "Collection vide";
        subtitle = _searchQuery.isNotEmpty
            ? "Essayez une autre recherche"
            : "Commencez à swiper pour remplir votre collection";
        icon = Icons.movie_filter_outlined;
    }

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
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// MODERN SEARCH BAR - Barre de recherche avec type selector
/// =============================================================================

class _ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onTypePressed;
  final String searchType;

  const _ModernSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onTypePressed,
    required this.searchType,
  });

  IconData get _typeIcon {
    switch (searchType) {
      case 'actor':
        return Icons.person_rounded;
      case 'director':
        return Icons.movie_creation_rounded;
      default:
        return Icons.movie_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Row(
            children: [
              // Type selector
              GestureDetector(
                onTap: onTypePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _typeIcon,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              // Search input
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
              // Clear button
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged("");
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textTertiary,
                      size: 20,
                    ),
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
/// FILTER CHIP - Chip de filtre moderne avec compteur
/// =============================================================================

class _FilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.count,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: AnimatedContainer(
          duration: AppTheme.durationMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.accent
                : AppTheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : AppTheme.border,
              width: 1,
            ),
            boxShadow: widget.isActive
                ? AppTheme.shadowAccent(AppTheme.accent)
                : AppTheme.shadowSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? Colors.white
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'RecoletaAlt',
                    color: widget.isActive
                        ? Colors.white
                        : AppTheme.accent,
                  ),
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
/// MODERN MOVIE CARD - Carte de film moderne avec glass effect
/// =============================================================================

class _ModernMovieCard extends StatefulWidget {
  final Movie movie;
  final bool showRating;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRateTap;

  const _ModernMovieCard({
    required this.movie,
    required this.showRating,
    required this.onTap,
    this.onLongPress,
    this.onRateTap,
  });

  @override
  State<_ModernMovieCard> createState() => _ModernMovieCardState();
}

class _ModernMovieCardState extends State<_ModernMovieCard> {
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
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: widget.movie.posterPath,
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
                      child: Icon(
                        Icons.movie_rounded,
                        size: 40,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ),

                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2D1F14).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // Titre
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    widget.movie.title.fr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Bouton noter visible
                if (widget.onRateTap != null)
                  Positioned(
                    bottom: 48,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onRateTap,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentDark.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.movie.isRated ? Icons.edit_rounded : Icons.star_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                // Badge note
                if (widget.showRating && widget.movie.isRated)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accent, AppTheme.accentDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.movie.userRating!.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'RecoletaAlt',
                                  fontSize: 13,
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
        ),
      ),
    );
  }
}

/// =============================================================================
/// ACTION BUTTON - Bouton d'action moderne
/// =============================================================================

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
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
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.accentDark],
            ),
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
/// SORT BUTTON - Bouton de tri moderne
/// =============================================================================

class _SortButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SortButton({required this.onTap});

  @override
  State<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<_SortButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
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
            Icons.sort_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// SORT MODAL - Modal de tri moderne
/// =============================================================================

class _SortModal extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const _SortModal({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.7; // 70% max de l'écran

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Trier par", style: AppTheme.titleLarge),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SortOption(
                      label: "Date d'ajout",
                      icon: Icons.calendar_today_rounded,
                      isSelected: currentSort == "date",
                      onTap: () {
                        onSortChanged("date");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Ma note",
                      icon: Icons.star_rounded,
                      isSelected: currentSort == "rating",
                      onTap: () {
                        onSortChanged("rating");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Popularité",
                      icon: Icons.trending_up_rounded,
                      isSelected: currentSort == "vote",
                      onTap: () {
                        onSortChanged("vote");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Titre (A-Z)",
                      icon: Icons.sort_by_alpha_rounded,
                      isSelected: currentSort == "title",
                      onTap: () {
                        onSortChanged("title");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Année de sortie",
                      icon: Icons.event_rounded,
                      isSelected: currentSort == "year",
                      onTap: () {
                        onSortChanged("year");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Durée",
                      icon: Icons.schedule_rounded,
                      isSelected: currentSort == "runtime",
                      onTap: () {
                        onSortChanged("runtime");
                        Navigator.pop(context);
                      },
                    ),
                    _SortOption(
                      label: "Genre",
                      icon: Icons.category_rounded,
                      isSelected: currentSort == "genre",
                      onTap: () {
                        onSortChanged("genre");
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentSoft
                    : AppTheme.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// SEARCH TYPE MODAL - Modal de type de recherche
/// =============================================================================

class _SearchTypeModal extends StatelessWidget {
  final String currentType;
  final Function(String) onTypeChanged;

  const _SearchTypeModal({
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("Rechercher par", style: AppTheme.titleLarge),
          const SizedBox(height: 20),
          _SortOption(
            label: "Titre du film",
            icon: Icons.movie_rounded,
            isSelected: currentType == "title",
            onTap: () {
              onTypeChanged("title");
              Navigator.pop(context);
            },
          ),
          _SortOption(
            label: "Acteur",
            icon: Icons.person_rounded,
            isSelected: currentType == "actor",
            onTap: () {
              onTypeChanged("actor");
              Navigator.pop(context);
            },
          ),
          _SortOption(
            label: "Réalisateur",
            icon: Icons.movie_creation_rounded,
            isSelected: currentType == "director",
            onTap: () {
              onTypeChanged("director");
              Navigator.pop(context);
            },
          ),
          _SortOption(
            label: "Genre",
            icon: Icons.category_rounded,
            isSelected: currentType == "genre",
            onTap: () {
              onTypeChanged("genre");
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
