import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/stats/genre_donut_chart.dart';
import '../widgets/stats/watch_time_gauge.dart';
import '../widgets/stats/favorite_movie_card.dart';
import '../widgets/stats/match_compatibility_card.dart';
import '../widgets/stats/favorite_info_card.dart';
import '../widgets/stats/share_buttons.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../services/collection_notifier.dart';
import '../theme/coffee_colors.dart';
import 'stats_story_screen.dart';
import 'settings_screen.dart';

/// =============================================================================
/// STATS SCREEN 2026 - Design Moderne Premium
/// =============================================================================
/// Style : iOS Design Award / Glassmorphism / Fluid Animations
/// Features : MÃ©triques visuelles, Graphiques interactifs, Partage social
/// =============================================================================

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // Animation
  late AnimationController _refreshController;

  // DonnÃ©es des stats
  AdvancedStats? _stats;
  String? _partnerName;

  // Friends list for quick switcher
  List<Friend> _friends = [];
  String? _compatibilityTarget;
  Map<String, dynamic>? _compatibilityData;
  bool _isLoadingCompatibility = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadStats();
    _loadFriends();

    // Ã‰couter les changements de collection (depuis feed_screen)
    collectionNotifier.addListener(_onCollectionChanged);
  }

  void _onCollectionChanged() {
    _loadStats();
  }

  @override
  void dispose() {
    collectionNotifier.removeListener(_onCollectionChanged);
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.getAdvancedStats();

      if (data != null && mounted) {
        setState(() {
          _stats = data;
          _fetchPartnerName();
          _isLoading = false;
        });
      } else if (mounted) {
        // data is null - show empty state
        setState(() {
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      // Catch any other exceptions
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur de chargement des statistiques";
        });
        _showErrorSnackbar("Erreur: $e");
      }
    }
  }

  Future<void> _loadFriends() async {
    try {
      final data = await _api.getFriendsList();
      if (data != null && mounted) {
        setState(() => _friends = data.friends);

        if (_friends.isNotEmpty) {
          final preferred =
              (_partnerName != null &&
                  _partnerName != "Aucun" &&
                  _friends.any((f) => f.username == _partnerName))
              ? _partnerName
              : _friends.first.username;

          if (preferred != null && preferred != _compatibilityTarget) {
            _loadCompatibilityForFriend(preferred, showErrors: false);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPartnerName() async {
    try {
      final profile = await _api.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _partnerName = profile['user']?['partner'] as String?;
        });

        if (_partnerName != null &&
            _partnerName != "Aucun" &&
            _friends.any((f) => f.username == _partnerName) &&
            _compatibilityTarget == null) {
          _loadCompatibilityForFriend(_partnerName!, showErrors: false);
        }
      }
    } catch (e) {
      // Silencieux, pas critique
    }
  }

  Future<void> _loadCompatibilityForFriend(
    String username, {
    bool showErrors = true,
  }) async {
    if (_isLoadingCompatibility) return;

    setState(() {
      _compatibilityTarget = username;
      _isLoadingCompatibility = true;
    });

    try {
      final data = await _api.getCompatibilityWith(username);
      if (mounted) {
        setState(() {
          _compatibilityData = data;
          _isLoadingCompatibility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompatibility = false;
          _compatibilityData = null;
        });
        if (showErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible de charger la compatibilite: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() => _isRefreshing = true);
    _refreshController.repeat();
    await _loadStats();
    _refreshController.stop();
    _refreshController.reset();
    setState(() => _isRefreshing = false);
  }

  void _showErrorSnackbar(String message) {
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
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RÃ©essayer',
          textColor: AppTheme.accent,
          onPressed: _loadStats,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // HEADER SIMPLE - Titre + Refresh
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text("Statistiques", style: AppTheme.headerOnCoffee),
                ),
                Row(
                  children: [
                    _RefreshButton(
                      isRefreshing: _isRefreshing,
                      animation: _refreshController,
                      onTap: _handleRefresh,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // CONTENU
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          Expanded(child: _isLoading ? _buildLoadingState() : _buildContent()),
        ],
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
            "Chargement des statistiques...",
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final s = _stats;
    if (s == null || s.totalSeen == 0) {
      return _buildEmptyState();
    }

    final genreDataList = s.genreDistribution
        .map(
          (g) => GenreData(
            genre: g.genre,
            count: g.count,
            percentage: g.percentage,
          ),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 1 : Stats cette semaine (highlight)
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            _WeeklyHighlightCard(
              weeklyFilms: s.weeklyFilms,
              weeklyMinutes: s.weeklyMinutes,
              monthlyFilms: s.monthlyFilms,
            ),

            const SizedBox(height: 16),

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // PARTAGE STORY
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            Row(
              children: [
                Expanded(
                  child: _StoryButton(
                    label: 'Semaine',
                    icon: Icons.calendar_today,
                    buttonColor: const Color(0xFF2D8FD5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StatsStoryScreen(period: 'week'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StoryButton(
                    label: 'All Time',
                    icon: Icons.insights_rounded,
                    buttonColor: const Color(0xFFE07A5F),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StatsStoryScreen(period: 'alltime'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 2 : MÃ©triques principales (rectangles)
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            Row(
              children: [
                Expanded(
                  child: _RectMetricCard(
                    icon: Icons.movie_rounded,
                    value: "${s.totalSeen}",
                    label: "Films vus",
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RectMetricCard(
                    icon: Icons.bookmark_rounded,
                    value: "${s.totalLiked}",
                    label: "Watchlist",
                    color: const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RectMetricCard(
                    icon: Icons.star_rounded,
                    value: s.averageRating.toStringAsFixed(1),
                    label: "Note moyenne",
                    color: const Color(0xFFFFC107),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RectMetricCard(
                    icon: Icons.schedule_rounded,
                    value: "${(s.totalMinutes / 60).toStringAsFixed(0)}h",
                    label: "Temps total",
                    color: const Color(0xFF42A5F5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 2 : Film prÃ©fÃ©rÃ©
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            if (s.favoriteMovie != null) ...[
              const _SectionTitle(title: "Votre coup de cÅ“ur"),
              const SizedBox(height: 12),
              FavoriteMovieCard(
                title: s.favoriteMovie!.title,
                posterUrl: s.favoriteMovie!.posterPath,
                rating: s.favoriteMovie!.userRating,
                runtime: s.favoriteMovie!.formattedRuntime,
                genres: s.favoriteMovie!.genres.isNotEmpty
                    ? s.favoriteMovie!.genres
                    : null,
              ),
              const SizedBox(height: 24),
            ],

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 3 : Distribution des genres
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            if (genreDataList.isNotEmpty) ...[
              GenreDonutChart(
                genres: genreDataList,
                title: "Vos genres favoris",
              ),
              const SizedBox(height: 24),
            ],

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 4 : Temps de visionnage
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            WatchTimeGauge(
              totalMinutes: s.totalMinutes,
              title: "Temps de visionnage",
              maxMinutes: 10000,
            ),

            const SizedBox(height: 24),

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 5 : Tester la compatibilitÃ© avec...
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            _buildCompatibilitySection(),
            const SizedBox(height: 24),

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 7 : Favoris (Acteur, Pays)
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            if (s.favoriteActor != null && s.favoriteActor!.isValid) ...[
              const _SectionTitle(title: "Vos favoris"),
              const SizedBox(height: 12),
              FavoriteInfoCard(
                icon: Icons.person_rounded,
                title: "Acteur favori",
                value: s.favoriteActor!.name,
                count: s.favoriteActor!.count,
                iconColor: CoffeeColors.caramelBronze,
              ),
              const SizedBox(height: 12),
            ],
            if (s.favoriteCountry != null && s.favoriteCountry!.isValid) ...[
              FavoriteInfoCard(
                icon: Icons.public_rounded,
                title: "Pays d'origine favori",
                value: s.favoriteCountry!.name,
                count: s.favoriteCountry!.count,
                iconColor: CoffeeColors.terracotta,
              ),
              const SizedBox(height: 24),
            ],

            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            // SECTION 8 : Partage
            // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
            ShareButtons(
              topGenre: s.genreDistribution.isNotEmpty
                  ? s.genreDistribution.first.genre
                  : null,
              totalMinutes: s.totalMinutes,
              favoriteMovie: s.favoriteMovie?.title,
              partnerName: _partnerName,
              matchPercentage: s.matchPercentage,
              coupleGenre: s.genreDistribution.isNotEmpty
                  ? s.genreDistribution.first.genre
                  : null,
            ),
          ],
        ),
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
                Icons.analytics_outlined,
                size: 48,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text("Aucune statistique", style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Commencez Ã  noter des films pour voir vos statistiques",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
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
            Text("Erreur de chargement", style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Une erreur est survenue",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ActionButton(
              label: "RÃ©essayer",
              icon: Icons.refresh_rounded,
              onTap: _loadStats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection() {
    if (_friends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: "Tester la compatibilite"),
            const SizedBox(height: 8),
            Text(
              "Ajoutez des amis pour generer une story de compatibilite.",
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final selectedUsername = _compatibilityTarget;
    final data = _compatibilityData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Tester sa compatibilite avec..."),
        const SizedBox(height: 6),
        Text(
          "Choisissez un ami puis generez une story de compatibilite.",
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final friend = _friends[index];
              final isSelected = friend.username == selectedUsername;
              return _buildCompatibilityFriendChip(friend, isSelected);
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoadingCompatibility)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          )
        else if (selectedUsername != null && data != null) ...[
          MatchCompatibilityCard(
            key: ValueKey('compatibility_$selectedUsername'),
            matchPercentage: ((data['compatibility'] as num?) ?? 0).toDouble(),
            partnerName: selectedUsername,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompatibilityMetaCard(
                  label: "Films en commun",
                  value: "${(data['common_movies_count'] as int?) ?? 0}",
                  icon: Icons.movie_filter_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompatibilityMetaCard(
                  label: "Matchs ensemble",
                  value: "${(data['total_matches'] as int?) ?? 0}",
                  icon: Icons.favorite_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: "Generer la story compatibilite",
            icon: Icons.auto_stories_rounded,
            onTap: _openDuoStory,
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              "Selectionnez un ami pour calculer votre compatibilite.",
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompatibilityFriendChip(Friend friend, bool isSelected) {
    return GestureDetector(
      onTap: () => _loadCompatibilityForFriend(friend.username),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A3529) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friend.initial,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              friend.username,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityMetaCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDuoStory() {
    final selectedUsername = _compatibilityTarget;
    if (selectedUsername == null || selectedUsername.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StatsStoryScreen(period: 'duo', partnerName: selectedUsername),
      ),
    );
  }
}

/// =============================================================================
/// SECTION TITLE - Titre de section
/// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTheme.titleMedium);
  }
}

/// =============================================================================
/// REFRESH BUTTON - Bouton refresh animÃ©
/// =============================================================================

class _RefreshButton extends StatelessWidget {
  final bool isRefreshing;
  final AnimationController animation;
  final VoidCallback onTap;

  const _RefreshButton({
    required this.isRefreshing,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRefreshing ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4A3529),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3529).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: RotationTransition(
          turns: animation,
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// WEEKLY HIGHLIGHT CARD - Carte rÃ©sumÃ© de la semaine
/// =============================================================================

class _WeeklyHighlightCard extends StatelessWidget {
  final int weeklyFilms;
  final int weeklyMinutes;
  final int monthlyFilms;

  const _WeeklyHighlightCard({
    required this.weeklyFilms,
    required this.weeklyMinutes,
    required this.monthlyFilms,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyHours = weeklyMinutes ~/ 60;
    final weeklyMins = weeklyMinutes % 60;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4A3529),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A3529).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Cette semaine",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$monthlyFilms ce mois",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _WeeklyStatItem(
                      value: "$weeklyFilms",
                      label: "films vus",
                      icon: Icons.movie_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _WeeklyStatItem(
                      value: weeklyHours > 0
                          ? "${weeklyHours}h${weeklyMins.toString().padLeft(2, '0')}"
                          : "${weeklyMins}min",
                      label: "de visionnage",
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _WeeklyStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'RecoletaAlt',
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// =============================================================================
/// RECT METRIC CARD - Carte de mÃ©trique rectangulaire
/// =============================================================================

class _RectMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RectMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Row(
            children: [
              // IcÃ´ne
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RecoletaAlt',
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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
/// ACTION BUTTON - Bouton d'action
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
/// STORY BUTTON - Bouton pour partager en Story
/// =============================================================================

class _StoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color buttonColor;
  final VoidCallback onTap;

  const _StoryButton({
    required this.label,
    required this.icon,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'RecoletaAlt',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
