import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../api_service.dart';
import '../models/advanced_stats.dart';
import '../widgets/stats/share_platform_stub.dart'
    if (dart.library.io) '../widgets/stats/share_platform_io.dart'
    if (dart.library.html) '../widgets/stats/share_platform_web.dart'
    as platform;

/// =============================================================================
/// STATS STORY SCREEN - Partage de stats format Story (multi-pages)
/// Design moderne : fond crème/blanc, accents marron, typographie Outfit
/// =============================================================================

class StatsStoryScreen extends StatefulWidget {
  final String period; // 'week', 'alltime', or 'duo'
  final String? partnerName;

  const StatsStoryScreen({super.key, required this.period, this.partnerName});

  @override
  State<StatsStoryScreen> createState() => _StatsStoryScreenState();
}

class _StatsStoryScreenState extends State<StatsStoryScreen> {
  final _apiService = ApiService();
  final _storyKey = GlobalKey();
  AdvancedStats? _statsData;
  Map<String, dynamic>? _duoData;
  bool _isLoading = true;
  bool _isGenerating = false;
  int _currentStoryPage = 0;

  // Design tokens
  static const _bgCream = Color(0xFFF8F3ED);
  static const _cardWhite = Color(0xFFFFFFFF);
  static const _brownDark = Color(0xFF3E2723);
  static const _brownMedium = Color(0xFF5D4037);
  static const _brownLight = Color(0xFF6D4C41);
  static const _brownAccent = Color(0xFFA1887F);
  static const _caramel = Color(0xFFD4A574);
  static const _warmGold = Color(0xFFE8C99B);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final data = widget.period == 'week'
          ? await _apiService.getPeriodStats('week')
          : await _apiService.getAdvancedStats();

      Map<String, dynamic>? duoData;
      if (widget.period == 'duo') {
        if (widget.partnerName != null &&
            widget.partnerName!.trim().isNotEmpty) {
          duoData = await _apiService.getCompatibilityWith(
            widget.partnerName!.trim(),
          );
        } else {
          duoData = await _apiService.getPartnerStatus();
        }
      }

      if (mounted) {
        setState(() {
          _statsData = data;
          _duoData = duoData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _captureAndShare() async {
    setState(() => _isGenerating = true);

    try {
      final boundary =
          _storyKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final storyType = widget.period == 'duo' ? 'duo' : widget.period;
      final fileName =
          'moovie_story_${storyType}_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = widget.period == 'duo'
          ? 'Notre compatibilite cine sur MoovieCoffee'
          : 'Mes stats cine sur MoovieCoffee';

      await platform.shareOrDownload(pngBytes, fileName, shareText);

      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb ? 'Image telechargee !' : 'Story partagee !'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _brownDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.period == 'week'
              ? 'Stats de la semaine'
              : widget.period == 'duo'
              ? 'Story compatibilite'
              : 'Stats All Time',
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            color: _brownDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isGenerating ? null : _captureAndShare,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _brownMedium,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.share_rounded, color: _brownMedium),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brownMedium))
          : widget.period == 'duo'
          ? Center(
              child: SingleChildScrollView(
                child: RepaintBoundary(key: _storyKey, child: _buildDuoStory()),
              ),
            )
          : _buildMultiPageStory(),
    );
  }

  // ===========================================================================
  // MULTI-PAGE STORY
  // ===========================================================================

  Widget _buildMultiPageStory() {
    return Column(
      children: [
        // Modern page indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentStoryPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentStoryPage == i
                      ? _brownMedium
                      : _brownAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: PageView(
            onPageChanged: (i) => setState(() => _currentStoryPage = i),
            children: [
              Center(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _storyKey,
                    child: _buildStoryPage1(),
                  ),
                ),
              ),
              Center(child: SingleChildScrollView(child: _buildStoryPage2())),
              Center(child: SingleChildScrollView(child: _buildStoryPage3())),
            ],
          ),
        ),
      ],
    );
  }

  /// Page 1: Résumé général + Film coup de coeur
  Widget _buildStoryPage1() {
    final stats = _statsData ?? const AdvancedStats();
    final favoriteMovie = stats.favoriteMovie;

    return _buildStoryContainer(
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildPeriodBadge(),
        const SizedBox(height: 24),

        // Main stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_rounded,
                value: stats.totalSeen.toString(),
                label: 'Films vus',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                value: '${(stats.totalMinutes / 60).toStringAsFixed(0)}h',
                label: 'Visionnage',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Moyenne',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Secondary stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_rounded,
                value: stats.totalLiked.toString(),
                label: 'Watchlist',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_month_rounded,
                value: stats.weeklyFilms.toString(),
                label: 'Cette sem.',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                value: stats.monthlyFilms.toString(),
                label: 'Ce mois',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (favoriteMovie != null) ...[
          _buildSectionTitle('Film coup de coeur'),
          const SizedBox(height: 12),
          _buildFavoriteMovieCard(favoriteMovie),
        ],
      ],
    );
  }

  /// Page 2: Genres avec barres + Acteur/Pays en hero cards
  Widget _buildStoryPage2() {
    final stats = _statsData ?? const AdvancedStats();
    final topGenres = stats.genreDistribution.take(5).toList();
    final maxPercentage = topGenres.isNotEmpty
        ? topGenres.first.percentage
        : 100.0;

    return _buildStoryContainer(
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Mes goûts'),
        const SizedBox(height: 24),

        // Actor & Country hero cards
        if (stats.favoriteActor != null && stats.favoriteActor!.isValid) ...[
          _buildHeroInfoCard(
            icon: Icons.person_rounded,
            label: 'Acteur le plus vu',
            value: stats.favoriteActor!.name,
            count: stats.favoriteActor!.count,
            gradient: [_brownMedium, _brownLight],
          ),
          const SizedBox(height: 10),
        ],

        if (stats.favoriteCountry != null &&
            stats.favoriteCountry!.isValid) ...[
          _buildHeroInfoCard(
            icon: Icons.public_rounded,
            label: 'Pays favori',
            value: stats.favoriteCountry!.name,
            count: stats.favoriteCountry!.count,
            gradient: [const Color(0xFF6D4C41), _brownAccent],
          ),
          const SizedBox(height: 20),
        ],

        if (topGenres.isNotEmpty) ...[
          _buildSectionTitle('Top genres'),
          const SizedBox(height: 12),
          ...topGenres.asMap().entries.map((entry) {
            final i = entry.key;
            final genre = entry.value;
            final barFraction = maxPercentage > 0
                ? genre.percentage / maxPercentage
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildGenreBarItem(
                rank: i + 1,
                genre: genre.genre,
                percentage: genre.percentage,
                count: genre.count,
                barFraction: barFraction,
                isTop: i == 0,
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Page 3: Mon profil ciné - temps + rythme + records
  Widget _buildStoryPage3() {
    final stats = _statsData ?? const AdvancedStats();
    final totalHours = stats.totalMinutes ~/ 60;
    final totalDays = (stats.totalMinutes / 1440).toStringAsFixed(1);
    final avgFilmLength = stats.totalSeen > 0
        ? (stats.totalMinutes / stats.totalSeen).round()
        : 0;
    final avgFilmHours = avgFilmLength ~/ 60;
    final avgFilmMins = avgFilmLength % 60;

    return _buildStoryContainer(
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Mon profil ciné'),
        const SizedBox(height: 24),

        // Big time stat - hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_brownMedium, _brownLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _brownMedium.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.schedule_rounded, color: _warmGold, size: 32),
              const SizedBox(height: 8),
              Text(
                '${totalHours}h',
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'de visionnage ($totalDays jours)',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Mon activité'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_rounded,
                value: stats.totalSeen.toString(),
                label: 'Films vus',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_rounded,
                value: stats.totalLiked.toString(),
                label: 'Watchlist',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Note moy.',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Mon rythme'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_rounded,
                value: stats.weeklyFilms.toString(),
                label: 'Films/sem.',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.date_range_rounded,
                value: stats.monthlyFilms.toString(),
                label: 'Films/mois',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_outlined,
                value: avgFilmHours > 0
                    ? '${avgFilmHours}h${avgFilmMins.toString().padLeft(2, '0')}'
                    : '${avgFilmMins}min',
                label: 'Durée moy.',
              ),
            ),
          ],
        ),

        if (stats.weeklyMinutes > 0) ...[
          const SizedBox(height: 20),
          _buildSectionTitle('Cette semaine'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _caramel.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _caramel.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        stats.weeklyFilms.toString(),
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'films',
                        style: GoogleFonts.dmSans(
                          color: _brownAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: _caramel.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stats.weeklyMinutes ~/ 60}h${(stats.weeklyMinutes % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'visionnage',
                        style: GoogleFonts.dmSans(
                          color: _brownAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // DUO STORY
  // ===========================================================================

  Widget _buildDuoStory() {
    final stats = _statsData ?? const AdvancedStats();
    final partner = widget.partnerName ?? 'Ami';
    final compatibility = _duoData?['compatibility'] ?? 0;
    final commonMovies = _duoData?['common_movies_count'] ?? 0;
    final totalMatches = _duoData?['total_matches'] ?? 0;
    final topGenres = stats.genreDistribution.take(3).toList();

    return _buildStoryContainer(
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Compatibilite duo'),
        const SizedBox(height: 24),

        // Avatars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDuoAvatar('Moi', true),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _caramel.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: _brownMedium,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            _buildDuoAvatar(partner, false),
          ],
        ),
        const SizedBox(height: 20),

        // Compatibility circle
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_brownMedium, _brownLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: _brownMedium.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$compatibility%',
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'compatibilité',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Duo stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_rounded,
                value: '$commonMovies',
                label: 'En commun',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$totalMatches',
                label: 'Matchs',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Moyenne',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Shared genres
        if (topGenres.isNotEmpty) ...[
          _buildSectionTitle('Nos genres en commun'),
          const SizedBox(height: 12),
          ...topGenres.asMap().entries.map((entry) {
            final i = entry.key;
            final genre = entry.value;
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == 0
                        ? _caramel.withValues(alpha: 0.5)
                        : _brownAccent.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Text(medals[i], style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        genre.genre,
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _brownMedium.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${genre.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownMedium,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
      footerSubtitle: 'Notre passion du cinema',
    );
  }

  // ===========================================================================
  // SHARED BUILDING BLOCKS
  // ===========================================================================

  Widget _buildStoryContainer({
    required List<Widget> children,
    String? footerSubtitle,
  }) {
    return Container(
      width: 390,
      constraints: const BoxConstraints(minHeight: 700),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _brownAccent.withValues(alpha: 0.15)),
      ),
      child: Stack(
        children: [
          // Subtle decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _caramel.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brownLight.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Subtle wave at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: CustomPaint(
                size: const Size(390, 80),
                painter: _ModernWavePainter(
                  color: _caramel.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...children,
                const SizedBox(height: 32),
                _buildStoryFooter(subtitle: footerSubtitle),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryHeader() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logoB.svg',
            height: 32,
            colorFilter: const ColorFilter.mode(_brownMedium, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Text(
            'MoovieCoffee',
            style: TextStyle(
              fontFamily: 'HolyCream',
              color: _brownDark,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBadge() {
    return _buildBadge(widget.period == 'week' ? 'Cette semaine' : 'All Time');
  }

  Widget _buildBadge(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _brownMedium,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _brownMedium.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _caramel,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            color: _brownDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? _brownMedium : _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? null
            : Border.all(color: _brownAccent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: (highlight ? _brownMedium : Colors.black).withValues(
              alpha: highlight ? 0.2 : 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? _warmGold : _brownLight, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              color: highlight ? Colors.white : _brownDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: highlight
                  ? Colors.white.withValues(alpha: 0.8)
                  : _brownAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required int count,
    required List<Color> gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count films',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreBarItem({
    required int rank,
    required String genre,
    required double percentage,
    required int count,
    required double barFraction,
    bool isTop = false,
  }) {
    final medals = ['🥇', '🥈', '🥉'];
    final rankLabel = rank <= 3 ? medals[rank - 1] : '$rank.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop
              ? _caramel.withValues(alpha: 0.5)
              : _brownAccent.withValues(alpha: 0.12),
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: _caramel.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rankLabel,
                style: TextStyle(
                  fontSize: rank <= 3 ? 16 : 13,
                  color: _brownDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  genre,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  color: _brownMedium,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: GoogleFonts.dmSans(color: _brownAccent, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barFraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _brownAccent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTop ? _caramel : _brownLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteMovieCard(FavoriteMovie movie) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _caramel.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _caramel.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              movie.posterPath,
              width: 56,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 84,
                decoration: BoxDecoration(
                  color: _brownAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.movie_rounded,
                  color: _brownLight,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.userRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: Colors.amber.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryFooter({String? subtitle}) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _brownMedium.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _brownAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/logoB.svg',
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    _brownMedium,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MoovieCoffee',
                  style: TextStyle(
                    fontFamily: 'HolyCream',
                    color: _brownMedium,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? 'Partagez votre passion du cinéma',
            style: GoogleFonts.dmSans(
              color: _brownAccent.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuoAvatar(String label, bool isMe) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? [_brownMedium, _brownLight]
                  : [_caramel, _brownAccent],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: _cardWhite, width: 3),
            boxShadow: [
              BoxShadow(
                color: _brownMedium.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label[0].toUpperCase(),
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: _brownDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Modern subtle wave painter
class _ModernWavePainter extends CustomPainter {
  final Color color;

  _ModernWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
