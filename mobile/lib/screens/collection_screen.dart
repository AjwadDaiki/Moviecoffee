import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/collection/edit_rating_modal.dart';
import '../api_service.dart';
import '../models/movie.dart';
import '../services/collection_notifier.dart';
import '../services/app_i18n.dart';
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
  bool _isAiPicking = false;
  String? _errorMessage;

  // Filtres
  String _activeFilter = "all"; // all, toSee, seenNotRated, rated
  String _searchQuery = "";
  String _searchType = "title"; // title, actor, director, genre
  String _sortBy = "date"; // date, rating, title, vote, year, runtime, genre
  String? _genreFilter;
  String? _yearFilter;
  final List<int> _aiRuntimeOptions = const [90, 110, 130, 150];

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
        sorter = (a, b) => a.title.display.compareTo(b.title.display);
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

    if (_genreFilter != null) {
      final selected = _genreFilter!.toLowerCase();
      movies = movies
          .where(
            (movie) =>
                movie.genres.any((genre) => genre.toLowerCase() == selected),
          )
          .toList();
    }

    if (_yearFilter != null) {
      movies = movies.where((movie) => movie.year == _yearFilter).toList();
    }

    // Appliquer la recherche
    if (_searchQuery.isEmpty) return movies;

    return movies.where((movie) {
      final query = _searchQuery.toLowerCase();
      switch (_searchType) {
        case 'actor':
          return movie.actors.any(
                (actor) => actor.toLowerCase().contains(query),
              ) ||
              movie.title.display.toLowerCase().contains(query);
        case 'director':
          // Note: directors n'est pas dans le modèle, on cherche dans le titre pour l'instant
          return movie.title.display.toLowerCase().contains(query);
        case 'genre':
          return movie.genres.any(
                (genre) => genre.toLowerCase().contains(query),
              ) ||
              movie.title.display.toLowerCase().contains(query);
        case 'title':
        default:
          return movie.title.display.toLowerCase().contains(query);
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
          title: movie.title.display,
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
      builder: (context) =>
          EditRatingModal(movie: movie, onUpdated: _loadCollection),
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

  List<String> get _availableGenres {
    final values = <String>{};
    for (final movie in [..._toSee, ..._seen]) {
      for (final genre in movie.genres) {
        final normalized = genre.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }
    final list = values.toList()..sort();
    return list;
  }

  List<String> get _availableYears {
    final values = <String>{};
    for (final movie in [..._toSee, ..._seen]) {
      final year = movie.year.trim();
      if (year.isNotEmpty) values.add(year);
    }
    final list = values.toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    return list;
  }

  bool get _hasAdvancedFilters => _genreFilter != null || _yearFilter != null;

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollectionFilterModal(
        genres: _availableGenres,
        years: _availableYears,
        currentGenre: _genreFilter,
        currentYear: _yearFilter,
        onApply: (genre, year) {
          setState(() {
            _genreFilter = genre;
            _yearFilter = year;
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

  Future<void> _pickCollectionWithAi({
    required String source,
    String? mood,
    int? runtimeMax,
    String? era,
  }) async {
    if (_isAiPicking) return;
    setState(() => _isAiPicking = true);
    try {
      final response = await _api.fetchSoloAiChoice(
        source: source,
        mood: mood,
        runtimeMax: runtimeMax,
        era: era,
      );
      if (!mounted) return;
      final movieJson = response?['movie'];
      if (movieJson is! Map<String, dynamic>) {
        setState(() => _isAiPicking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucun film trouve. Ajustez les options IA."),
          ),
        );
        return;
      }

      final movie = Movie.fromJson(movieJson);
      final reason = (response?['reason'] ?? "Reco basee sur vos likes")
          .toString();

      setState(() => _isAiPicking = false);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("IA: ${movie.title.display} | $reason"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A3529),
          duration: const Duration(seconds: 3),
        ),
      );
      _openMovieDetail(movie);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isAiPicking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAiPicking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erreur IA. Reessayez.")));
    }
  }

  void _showCollectionAiPickerModal() {
    if (_isAiPicking) return;
    String selectedSource = "collection";
    String? selectedMood;
    int? selectedRuntime;
    String? selectedEra;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                const SizedBox(height: 18),
                const Text(
                  "IA Collection",
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Laissez les options vides pour une reco basee sur vos likes.",
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text("Source", style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AiOptionChip(
                      label: "Collection",
                      isSelected: selectedSource == "collection",
                      onTap: () =>
                          setModalState(() => selectedSource = "collection"),
                    ),
                    _AiOptionChip(
                      label: "Watchlist",
                      isSelected: selectedSource == "wishlist",
                      onTap: () =>
                          setModalState(() => selectedSource = "wishlist"),
                    ),
                    _AiOptionChip(
                      label: "All Time",
                      isSelected: selectedSource == "alltime",
                      onTap: () =>
                          setModalState(() => selectedSource = "alltime"),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text("Genre (optionnel)", style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AiOptionChip(
                      label: "Aucun",
                      isSelected: selectedMood == null,
                      onTap: () => setModalState(() => selectedMood = null),
                    ),
                    ..._availableGenres
                        .take(8)
                        .map(
                          (genre) => _AiOptionChip(
                            label: genre,
                            isSelected: selectedMood == genre,
                            onTap: () => setModalState(
                              () => selectedMood = selectedMood == genre
                                  ? null
                                  : genre,
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 14),
                Text("Periode (optionnel)", style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AiOptionChip(
                      label: "Aucune",
                      isSelected: selectedEra == null,
                      onTap: () => setModalState(() => selectedEra = null),
                    ),
                    _AiOptionChip(
                      label: "Recent",
                      isSelected: selectedEra == "recent",
                      onTap: () => setModalState(
                        () => selectedEra = selectedEra == "recent"
                            ? null
                            : "recent",
                      ),
                    ),
                    _AiOptionChip(
                      label: "Retro",
                      isSelected: selectedEra == "retro",
                      onTap: () => setModalState(
                        () => selectedEra = selectedEra == "retro"
                            ? null
                            : "retro",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text("Duree max", style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AiOptionChip(
                      label: "Libre",
                      isSelected: selectedRuntime == null,
                      onTap: () => setModalState(() => selectedRuntime = null),
                    ),
                    ..._aiRuntimeOptions.map(
                      (runtime) => _AiOptionChip(
                        label: "Max $runtime min",
                        isSelected: selectedRuntime == runtime,
                        onTap: () =>
                            setModalState(() => selectedRuntime = runtime),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _ActionButton(
                    label: "Trouver avec IA",
                    icon: Icons.auto_awesome_rounded,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickCollectionWithAi(
                        source: selectedSource,
                        mood: selectedMood,
                        runtimeMax: selectedRuntime,
                        era: selectedEra,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
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
                    Text(
                      AppI18n.t('collection.title', fallback: 'Collection'),
                      style: TextStyle(
                        fontFamily: 'RecoletaAlt',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (_getSubtitle() != null)
                      Text(
                        _getSubtitle()!,
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE8E0D5),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CollectionAiButton(
                      onTap: _showCollectionAiPickerModal,
                      isLoading: _isAiPicking,
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    _CollectionFilterButton(
                      onTap: _showAdvancedFilters,
                      isActive: _hasAdvancedFilters,
                    ),
                    const SizedBox(width: 8),
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
          if (_hasAdvancedFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Filtres actifs: ${_genreFilter ?? 'Tous genres'}${_yearFilter != null ? ' / $_yearFilter' : ''}",
                      style: const TextStyle(
                        fontFamily: 'RecoletaAlt',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8E0D5),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _genreFilter = null;
                        _yearFilter = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Text(
                        'Effacer',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                  label: AppI18n.t('collection.tab.all', fallback: 'Tout'),
                  icon: Icons.grid_view_rounded,
                  isActive: _activeFilter == "all",
                  count: _toSee.length + _seen.length,
                  onTap: () => setState(() => _activeFilter = "all"),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: AppI18n.t('collection.tab.to_see', fallback: 'A voir'),
                  icon: Icons.bookmark_rounded,
                  isActive: _activeFilter == "toSee",
                  count: _toSee.length,
                  onTap: () => setState(() => _activeFilter = "toSee"),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: AppI18n.t(
                    'collection.tab.to_rate',
                    fallback: 'A noter',
                  ),
                  icon: Icons.rate_review_rounded,
                  isActive: _activeFilter == "seenNotRated",
                  count: _seenNotRated.length,
                  onTap: () => setState(() => _activeFilter = "seenNotRated"),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: AppI18n.t('collection.tab.rated', fallback: 'Notes'),
                  icon: Icons.star_rounded,
                  isActive: _activeFilter == "rated",
                  count: _seen.where((m) => m.isRated).length,
                  onTap: () => setState(() => _activeFilter = "rated"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.swipe_rounded,
                  size: 14,
                  color: Color(0xFFE8D7C4),
                ),
                const SizedBox(width: 6),
                Text(
                  "Glissez les onglets pour voir Notés",
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8D7C4),
                  ),
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
    if (_hasAdvancedFilters) {
      final genre = _genreFilter ?? 'Tous genres';
      final year = _yearFilter ?? 'Toutes annees';
      return "Filtres: $genre / $year";
    }

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
            onRateTap: _activeFilter == "all"
                ? null
                : () => _openRatingModal(movies[index]),
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
              child: Icon(icon, size: 48, color: AppTheme.accent),
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
                      Icon(_typeIcon, color: AppTheme.accent, size: 20),
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
                color: widget.isActive ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive ? Colors.white : AppTheme.textPrimary,
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
                    color: widget.isActive ? Colors.white : AppTheme.accent,
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

  void _openEditor() {
    if (widget.onRateTap == null) return;
    widget.onRateTap!.call();
  }

  String get _compactCommentPreview {
    final raw = (widget.movie.userComment ?? "").trim();
    if (raw.isEmpty) return "";
    final normalized = raw.replaceAll(RegExp(r"\s+"), " ");
    if (normalized.length <= 42) return normalized;
    return "${normalized.substring(0, 39)}...";
  }

  @override
  Widget build(BuildContext context) {
    final isRated = widget.movie.isRated;
    final compactComment = _compactCommentPreview;
    final actionBg = isRated
        ? const Color(0xFF4A3529).withValues(alpha: 0.84)
        : const Color(0xFF4A3529).withValues(alpha: 0.92);
    final actionTextColor = const Color(0xFFF6E9DC);

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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x001F140F),
                          Color(0x731F140F),
                          Color(0xD92D1F14),
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
                    widget.movie.title.display,
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
                    bottom: 52,
                    right: 10,
                    child: GestureDetector(
                      onTap: _openEditor,
                      child: Container(
                        padding: widget.movie.isRated
                            ? const EdgeInsets.all(9)
                            : const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                        decoration: BoxDecoration(
                          color: actionBg,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D1E16,
                              ).withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.movie.isRated
                                  ? Icons.edit_rounded
                                  : Icons.edit_note_rounded,
                              color: actionTextColor,
                              size: widget.movie.isRated ? 16 : 17,
                            ),
                            if (!widget.movie.isRated) ...[
                              const SizedBox(width: 5),
                              Text(
                                'Noter',
                                style: TextStyle(
                                  color: actionTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // Badge note + debut commentaire
                if (widget.showRating && widget.movie.isRated)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 182),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F221A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFD166),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.movie.userRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'RecoletaAlt',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (compactComment.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                compactComment,
                                style: const TextStyle(
                                  color: Color(0xFFF0E2D5),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10.5,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
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
            color: const Color(0xFF4A3529),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A3529).withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
/// IA BUTTON - Bouton IA collection
/// =============================================================================

class _CollectionAiButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _CollectionAiButton({required this.onTap, required this.isLoading});

  @override
  State<_CollectionAiButton> createState() => _CollectionAiButtonState();
}

class _CollectionAiButtonState extends State<_CollectionAiButton> {
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
            color: const Color(0xFF4A3529),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E2018).withValues(alpha: 0.24),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// FILTER BUTTON - Bouton filtre collection
/// =============================================================================

class _CollectionFilterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isActive;

  const _CollectionFilterButton({required this.onTap, required this.isActive});

  @override
  State<_CollectionFilterButton> createState() =>
      _CollectionFilterButtonState();
}

class _CollectionFilterButtonState extends State<_CollectionFilterButton> {
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
            color: widget.isActive
                ? const Color(0xFFFFEAD1)
                : const Color(0xFFF7ECDD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isActive
                  ? const Color(0xFFC48E55)
                  : const Color(0xFFE1CCB3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A4337).withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF5A4337),
                  size: 22,
                ),
              ),
              if (widget.isActive)
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC48E55),
                      shape: BoxShape.circle,
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
            color: const Color(0xFFF3E7D8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD8C2AA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A4337).withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.sort_rounded,
            color: Color(0xFF5A4337),
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// IA OPTION CHIP - Chip utilitaire pour modal IA
/// =============================================================================

class _AiOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AiOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A3529)
              : AppTheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A3529)
                : AppTheme.border.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontFamily: 'RecoletaAlt',
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// FILTER MODAL - Modal filtres avancés
/// =============================================================================

class _CollectionFilterModal extends StatefulWidget {
  final List<String> genres;
  final List<String> years;
  final String? currentGenre;
  final String? currentYear;
  final void Function(String? genre, String? year) onApply;

  const _CollectionFilterModal({
    required this.genres,
    required this.years,
    required this.currentGenre,
    required this.currentYear,
    required this.onApply,
  });

  @override
  State<_CollectionFilterModal> createState() => _CollectionFilterModalState();
}

class _CollectionFilterModalState extends State<_CollectionFilterModal> {
  String? _selectedGenre;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.currentGenre;
    _selectedYear = widget.currentYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
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
          Text(
            AppI18n.t(
              'collection.filter_title',
              fallback: 'Filtrer la collection',
            ),
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String?>(
            initialValue: _selectedGenre,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  AppI18n.t(
                    'collection.filter_all_genres',
                    fallback: 'Tous les genres',
                  ),
                ),
              ),
              ...widget.genres.map(
                (genre) =>
                    DropdownMenuItem<String?>(value: genre, child: Text(genre)),
              ),
            ],
            onChanged: (value) => setState(() => _selectedGenre = value),
            decoration: const InputDecoration(
              labelText: "Genre",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedYear,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  AppI18n.t(
                    'collection.filter_all_years',
                    fallback: 'Toutes les annees',
                  ),
                ),
              ),
              ...widget.years.map(
                (year) =>
                    DropdownMenuItem<String?>(value: year, child: Text(year)),
              ),
            ],
            onChanged: (value) => setState(() => _selectedYear = value),
            decoration: const InputDecoration(
              labelText: "Annee",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGenre = null;
                      _selectedYear = null;
                    });
                  },
                  child: Text(
                    AppI18n.t('action.reset', fallback: 'Reinitialiser'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedGenre, _selectedYear);
                    Navigator.pop(context);
                  },
                  child: Text(AppI18n.t('action.apply', fallback: 'Appliquer')),
                ),
              ),
            ],
          ),
        ],
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

  const _SortModal({required this.currentSort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.7; // 70% max de l'écran

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
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
            Text(
              AppI18n.t('collection.sort_title', fallback: 'Trier par'),
              style: AppTheme.titleLarge,
            ),
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
            bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
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
        24,
        24,
        24,
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
