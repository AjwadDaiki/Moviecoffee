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
/// Design moderne : fond creme/blanc, accents marron, typographie Outfit
/// =============================================================================

class StatsStoryScreen extends StatefulWidget {
  final String period; // 'week', 'alltime', or 'duo'
  final String? partnerName;

  const StatsStoryScreen({super.key, required this.period, this.partnerName});

  @override
  State<StatsStoryScreen> createState() => _StatsStoryScreenState();
}

enum _ShareTemplateFormat { story, twitter }

class _StatsStoryScreenState extends State<StatsStoryScreen> {
  final _apiService = ApiService();
  final List<GlobalKey> _duoStoryPageKeys = List.generate(
    2,
    (_) => GlobalKey(),
  );
  final GlobalKey _duoTwitterKey = GlobalKey();
  final List<GlobalKey> _storyPageKeys = List.generate(3, (_) => GlobalKey());
  final List<GlobalKey> _twitterPageKeys = List.generate(2, (_) => GlobalKey());
  AdvancedStats? _statsData;
  Map<String, dynamic>? _duoData;
  bool _isLoading = true;
  bool _isGenerating = false;
  int _currentStoryPage = 0;
  int _currentDuoStoryPage = 0;
  int _currentTwitterPage = 0;
  _ShareTemplateFormat _templateFormat = _ShareTemplateFormat.story;

  // Design tokens
  static const _bgCream = Color(0xFFF8F3ED);
  static const _cardWhite = Color(0xFFFFFFFF);
  static const _brownDark = Color(0xFF3E2723);
  static const _brownMedium = Color(0xFF5D4037);
  static const _brownLight = Color(0xFF6D4C41);
  static const _brownAccent = Color(0xFFA1887F);
  static const _caramel = Color(0xFF9B7766);
  static const _warmGold = Color(0xFFC1A293);
  static const _storyWidth = 360.0; // 9:16
  static const _storyHeight = 640.0; // 9:16
  static const _twitterWidth = 640.0; // 16:9
  static const _twitterHeight = 360.0; // 16:9
  bool get _isTwitterFormat => _templateFormat == _ShareTemplateFormat.twitter;
  double get _activeStoryWidth =>
      _isTwitterFormat ? _twitterWidth : _storyWidth;
  double get _activeStoryHeight =>
      _isTwitterFormat ? _twitterHeight : _storyHeight;

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
      final safeStoryPage = _currentStoryPage.clamp(
        0,
        _storyPageKeys.length - 1,
      );
      final safeDuoPage = _currentDuoStoryPage.clamp(
        0,
        _duoStoryPageKeys.length - 1,
      );
      final safeTwitterPage = _currentTwitterPage.clamp(
        0,
        _twitterPageKeys.length - 1,
      );
      final targetKey = widget.period == 'duo'
          ? (_isTwitterFormat ? _duoTwitterKey : _duoStoryPageKeys[safeDuoPage])
          : _isTwitterFormat
          ? _twitterPageKeys[safeTwitterPage]
          : _storyPageKeys[safeStoryPage];
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = targetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError("Story indisponible pour la capture.");
      }
      final boundary = renderObject;
      if (boundary.size.width <= 0 || boundary.size.height <= 0) {
        throw StateError("Story non prete pour la capture.");
      }
      final pixelRatio = 1080 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError("Impossible de generer l'image de la story.");
      }
      final pngBytes = byteData.buffer.asUint8List();

      final storyType = widget.period == 'duo' ? 'duo' : widget.period;
      final formatType = _isTwitterFormat ? 'twitter' : 'story';
      final fileName =
          'moovie_story_${storyType}_${formatType}_${DateTime.now().millisecondsSinceEpoch}.png';
      final shareText = widget.period == 'duo'
          ? (_isTwitterFormat
                ? 'Notre compatibilite cine en format 16:9 sur MoovieCoffee'
                : 'Notre compatibilite cine sur MoovieCoffee')
          : _isTwitterFormat
          ? 'Mes stats cine en format 16:9 sur MoovieCoffee'
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
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _brownMedium),
      );
    }

    return Column(
      children: [
        _buildFormatSwitcher(),
        Expanded(
          child: widget.period == 'duo'
              ? (_isTwitterFormat
                    ? _buildDuoTwitterSinglePage()
                    : _buildDuoMultiPage())
              : (_isTwitterFormat
                    ? _buildTwitterMultiPage()
                    : _buildMultiPageStory()),
        ),
      ],
    );
  }

  Widget _buildFormatSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _brownAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFormatOption(
                label: '9:16',
                isActive: _templateFormat == _ShareTemplateFormat.story,
                onTap: () {
                  setState(() {
                    _templateFormat = _ShareTemplateFormat.story;
                    _currentStoryPage = 0;
                    _currentDuoStoryPage = 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildFormatOption(
                label: '16:9',
                isActive: _templateFormat == _ShareTemplateFormat.twitter,
                onTap: () {
                  setState(() {
                    _templateFormat = _ShareTemplateFormat.twitter;
                    _currentTwitterPage = 0;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _brownMedium : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : _brownMedium,
            ),
          ),
        ),
      ),
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
                child: RepaintBoundary(
                  key: _storyPageKeys[0],
                  child: _buildStoryPage1(),
                ),
              ),
              Center(
                child: RepaintBoundary(
                  key: _storyPageKeys[1],
                  child: _buildStoryPage2(),
                ),
              ),
              Center(
                child: RepaintBoundary(
                  key: _storyPageKeys[2],
                  child: _buildStoryPage3(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoMultiPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentDuoStoryPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentDuoStoryPage == i
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
            onPageChanged: (i) => setState(() => _currentDuoStoryPage = i),
            children: [
              Center(
                child: RepaintBoundary(
                  key: _duoStoryPageKeys[0],
                  child: _buildDuoStory(),
                ),
              ),
              Center(
                child: RepaintBoundary(
                  key: _duoStoryPageKeys[1],
                  child: _buildDuoStoryPage2(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoTwitterSinglePage() {
    return Center(
      child: RepaintBoundary(
        key: _duoTwitterKey,
        child: _buildDuoTwitterPage(),
      ),
    );
  }

  Widget _buildTwitterMultiPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentTwitterPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentTwitterPage == i
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
            onPageChanged: (i) => setState(() => _currentTwitterPage = i),
            children: [
              Center(
                child: RepaintBoundary(
                  key: _twitterPageKeys[0],
                  child: _buildTwitterPage1(),
                ),
              ),
              Center(
                child: RepaintBoundary(
                  key: _twitterPageKeys[1],
                  child: _buildTwitterPage2(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTwitterPage1() {
    final stats = _statsData ?? const AdvancedStats();
    final favoriteMovie = stats.lastFavoriteMovie ?? stats.favoriteMovie;
    final topGenres = stats.genreDistribution.take(2).toList();
    final topGenrePcts = _buildStablePercentages(topGenres);
    final isWeek = widget.period == 'week';
    final watchedCount = isWeek ? stats.weeklyFilms : stats.totalSeen;
    final periodMinutes = isWeek ? stats.weeklyMinutes : stats.totalMinutes;
    final watchedHours = periodMinutes ~/ 60;
    final watchedMins = periodMinutes % 60;
    final watchTime = watchedHours > 0
        ? '${watchedHours}h${watchedMins.toString().padLeft(2, '0')}'
        : '${watchedMins}min';
    final periodLabel = isWeek ? 'Semaine' : 'All Time';

    return _buildStoryContainer(
      toneColor: isWeek ? const Color(0xFF6F8FAF) : const Color(0xFF8A7160),
      children: [
        _buildStoryHeader(compact: true),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTwitterHeaderChip(
              icon: Icons.insights_rounded,
              label: periodLabel,
              strong: true,
            ),
            const SizedBox(width: 8),
            _buildTwitterHeaderChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Highlights',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildTwitterHeroPanel(
                        title: isWeek
                            ? 'Resume de la semaine'
                            : 'Resume global',
                        primaryValue: watchedCount.toString(),
                        primaryLabel: 'films vus',
                        secondaryLabel: 'temps de visionnage',
                        secondaryValue: watchTime,
                        accent: isWeek
                            ? const Color(0xFF4E739A)
                            : const Color(0xFF785A49),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTwitterMetric(
                            icon: Icons.star_rounded,
                            value: stats.averageRating.toStringAsFixed(1),
                            label: 'Moyenne',
                            highlight: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTwitterMetric(
                            icon: Icons.favorite_rounded,
                            value: stats.totalLiked.toString(),
                            label: 'Watchlist',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 9,
                child: favoriteMovie != null
                    ? _buildTwitterFavoriteMovieRow(favoriteMovie)
                    : _buildTwitterInfoCard(
                        title: 'Dernier coup de coeur',
                        value: 'Aucun film 4.5+ ou 5 pour le moment',
                        icon: Icons.favorite_outline_rounded,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (topGenres.isNotEmpty) ...[
          _buildTwitterGenreStrip(
            topGenres: topGenres,
            topGenrePcts: topGenrePcts,
          ),
        ] else ...[
          _buildTwitterInfoCard(
            title: 'Genres',
            value: 'Pas assez de donnees pour afficher un top genre.',
            icon: Icons.theater_comedy_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildTwitterPage2() {
    final stats = _statsData ?? const AdvancedStats();
    final isWeek = widget.period == 'week';
    final topGenres = stats.genreDistribution.take(2).toList();
    final topGenrePcts = _buildStablePercentages(topGenres);
    final periodMinutes = isWeek ? stats.weeklyMinutes : stats.totalMinutes;
    final totalHours = periodMinutes ~/ 60;
    final totalMins = periodMinutes % 60;
    final watchTime = totalHours > 0
        ? '${totalHours}h${totalMins.toString().padLeft(2, '0')}'
        : '${totalMins}min';
    final actorLabel = stats.favoriteActor?.isValid == true
        ? stats.favoriteActor!.name
        : 'A determiner';
    final countryLabel = stats.favoriteCountry?.isValid == true
        ? stats.favoriteCountry!.name
        : 'A determiner';
    final profileSignature = '$actorLabel - $countryLabel';

    return _buildStoryContainer(
      toneColor: isWeek ? const Color(0xFF6A9A8C) : const Color(0xFF8A6857),
      children: [
        _buildStoryHeader(compact: true),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTwitterHeaderChip(
              icon: Icons.analytics_rounded,
              label: isWeek ? 'Semaine' : 'All Time',
              strong: true,
            ),
            const SizedBox(width: 8),
            _buildTwitterHeaderChip(
              icon: Icons.person_search_rounded,
              label: 'Profil cine',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: _buildTwitterGenreBoard(
                  topGenres: topGenres,
                  topGenrePcts: topGenrePcts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 9,
                child: _buildTwitterDepthBoard(
                  rated: stats.ratedSeenCount,
                  unrated: stats.unratedSeenCount,
                  comments: stats.commentedSeenCount,
                  watchTime: watchTime,
                  accent: isWeek
                      ? const Color(0xFF4D7D70)
                      : const Color(0xFF715646),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildTwitterInfoCard(
          title: 'Signature cine',
          value: profileSignature,
          icon: Icons.auto_awesome_rounded,
        ),
      ],
    );
  }

  Widget _buildDuoTwitterPage() {
    final partner = widget.partnerName ?? 'Ami';
    final shortPartner = partner.length > 14
        ? '${partner.substring(0, 14)}...'
        : partner;
    final compatibilityValue = ((_duoData?['compatibility'] as num?) ?? 0)
        .toDouble()
        .clamp(0.0, 100.0);
    final compatibility = compatibilityValue.round().clamp(0, 100);
    final commonMovies =
        ((_duoData?['duo_common_seen_count'] as num?)?.toInt() ?? 0).clamp(
          0,
          99999,
        );
    final totalMatches = ((_duoData?['total_matches'] as num?)?.toInt() ?? 0)
        .clamp(0, 99999);
    final duoTotalMinutes =
        ((_duoData?['duo_total_minutes'] as num?)?.toInt() ?? 0).clamp(
          0,
          9999999,
        );
    final totalHours = duoTotalMinutes ~/ 60;
    final totalMins = duoTotalMinutes % 60;
    final duoTime = totalHours > 0
        ? '${totalHours}h${totalMins.toString().padLeft(2, '0')}'
        : '${totalMins}min';
    final rawBreakdown = _duoData?['score_breakdown'];
    final breakdown = rawBreakdown is Map
        ? rawBreakdown.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final ratingAlignment =
        ((breakdown['rating_alignment'] as num?)?.toDouble() ??
                compatibilityValue)
            .clamp(0.0, 100.0);
    final genreAlignment =
        ((breakdown['genre_alignment'] as num?)?.toDouble() ??
                compatibilityValue)
            .clamp(0.0, 100.0);
    final headline = _compatibilityHeadline(compatibilityValue);

    return _buildStoryContainer(
      toneColor: const Color(0xFF6C85A2),
      children: [
        _buildStoryHeader(compact: true),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTwitterHeaderChip(
              icon: Icons.groups_rounded,
              label: 'Duo',
              strong: true,
            ),
            const SizedBox(width: 8),
            _buildTwitterHeaderChip(
              icon: Icons.favorite_rounded,
              label: 'Moi + $shortPartner',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3529),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3529).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compatibilite cine',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$compatibility%',
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                      ),
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDuoCompactStat(
                              value: '$commonMovies',
                              label: 'Vus a 2',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDuoCompactStat(
                              value: '$totalMatches',
                              label: 'Matchs',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 9,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _brownAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume duo',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDuoCompactRow(
                        icon: Icons.schedule_rounded,
                        label: 'Temps duo',
                        value: duoTime,
                      ),
                      const SizedBox(height: 6),
                      _buildDuoCompactRow(
                        icon: Icons.star_rate_rounded,
                        label: 'Alignement notes',
                        value: '${ratingAlignment.round()}%',
                      ),
                      const SizedBox(height: 6),
                      _buildDuoCompactRow(
                        icon: Icons.theater_comedy_rounded,
                        label: 'Alignement genres',
                        value: '${genreAlignment.round()}%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoCompactStat({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuoCompactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _brownAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _brownMedium),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: _brownDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: _brownDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterGenreBoard({
    required List<GenreStats> topGenres,
    required List<int> topGenrePcts,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brownAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genres dominants',
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              color: _brownDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (topGenres.isEmpty)
            Text(
              'Pas assez de donnees pour les genres.',
              style: GoogleFonts.dmSans(
                color: _brownAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...topGenres.asMap().entries.map((entry) {
              final i = entry.key;
              final genre = entry.value;
              final pct = i < topGenrePcts.length ? topGenrePcts[i] : 0;
              final accent = i == 0
                  ? const Color(0xFF8A5A44)
                  : const Color(0xFF6E8AA0);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == topGenres.length - 1 ? 0 : 8,
                ),
                child: _buildTwitterGenreProgress(
                  rank: i + 1,
                  genre: genre.genre,
                  percentage: pct,
                  accent: accent,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTwitterDepthBoard({
    required int rated,
    required int unrated,
    required int comments,
    required String watchTime,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rythme cine',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            watchTime,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          Text(
            'temps de visionnage',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTwitterDepthRow(
            icon: Icons.star_rate_rounded,
            label: 'Notes',
            value: '$rated',
          ),
          const SizedBox(height: 6),
          _buildTwitterDepthRow(
            icon: Icons.edit_note_rounded,
            label: 'A noter',
            value: '$unrated',
          ),
          const SizedBox(height: 6),
          _buildTwitterDepthRow(
            icon: Icons.comment_rounded,
            label: 'Commentaires',
            value: '$comments',
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterDepthRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Page 1: Resume general + dernier coup de coeur
  Widget _buildStoryPage1() {
    final stats = _statsData ?? const AdvancedStats();
    final favoriteMovie = stats.lastFavoriteMovie ?? stats.favoriteMovie;

    return _buildStoryContainer(
      toneColor: const Color(0xFF7B5A46),
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildPeriodBadge(),
        const SizedBox(height: 24),

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
                icon: Icons.edit_note_rounded,
                value: stats.unratedSeenCount.toString(),
                label: 'A noter',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.comment_rounded,
                value: stats.commentedSeenCount.toString(),
                label: 'Commentaires',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (favoriteMovie != null) ...[
          _buildSectionTitle('Dernier coup de coeur'),
          const SizedBox(height: 12),
          _buildFavoriteMovieCard(favoriteMovie),
        ],
      ],
    );
  }

  List<int> _buildStablePercentages(List<GenreStats> genres) {
    if (genres.isEmpty) return const [];
    final total = genres.fold<int>(0, (sum, g) => sum + g.count);
    if (total <= 0) return List<int>.filled(genres.length, 0);

    final raw = genres.map((g) => (g.count * 100) / total).toList();
    final floorVals = raw.map((v) => v.floor()).toList();
    var remainder = 100 - floorVals.fold<int>(0, (sum, v) => sum + v);

    final rankedRemainders =
        raw
            .asMap()
            .entries
            .map((e) => MapEntry(e.key, e.value - floorVals[e.key]))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    var idx = 0;
    while (remainder > 0 && rankedRemainders.isNotEmpty) {
      final target = rankedRemainders[idx % rankedRemainders.length].key;
      floorVals[target] += 1;
      remainder--;
      idx++;
    }

    return floorVals;
  }

  /// Page 2: Genres avec barres + Acteur/Pays en hero cards
  Widget _buildStoryPage2() {
    final stats = _statsData ?? const AdvancedStats();
    final isAllTime = widget.period == 'alltime';
    final maxBars = 3;
    final topGenres = stats.genreDistribution.take(maxBars).toList();
    final normalizedGenrePercentages = _buildStablePercentages(topGenres);
    final accentCardColor = isAllTime
        ? const Color(0xFF4E7C8A)
        : const Color(0xFF5A7FB0);
    final countryCardColor = isAllTime
        ? const Color(0xFF6F8E68)
        : const Color(0xFF7E6A9A);
    final badgeColor = isAllTime
        ? const Color(0xFF5D7D68)
        : const Color(0xFF607FAE);
    final toneColor = isAllTime
        ? const Color(0xFF9DBD8E)
        : const Color(0xFF97B6D6);
    final primaryGenreName = topGenres.isNotEmpty
        ? topGenres.first.genre
        : 'Aucun';
    final primaryGenrePct = normalizedGenrePercentages.isNotEmpty
        ? normalizedGenrePercentages.first
        : 0;

    return _buildStoryContainer(
      toneColor: toneColor,
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 12),
        _buildBadge('Mes gouts', color: badgeColor),
        const SizedBox(height: 8),

        if (topGenres.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brownAccent.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: badgeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Genre #1: $primaryGenreName ($primaryGenrePct%)',
                    style: GoogleFonts.dmSans(
                      color: _brownDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (topGenres.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${topGenres.length - 1}',
                      style: GoogleFonts.dmSans(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_rounded,
                value: stats.totalSeen.toString(),
                label: isAllTime ? 'Total vus' : 'Cette sem.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Note moy.',
                highlight: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                value: '${(stats.totalMinutes / 60).round()}h',
                label: 'Visionnage',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isAllTime)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: stats.ratedSeenCount.toString(),
                  label: 'Notes',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.edit_note_rounded,
                  value: stats.unratedSeenCount.toString(),
                  label: 'A noter',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.comment_rounded,
                  value: stats.commentedSeenCount.toString(),
                  label: 'Commentaires',
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_month_rounded,
                  value: stats.weeklyFilms.toString(),
                  label: 'Cette sem.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up_rounded,
                  value: stats.monthlyFilms.toString(),
                  label: 'Ce mois',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  value: stats.totalLiked.toString(),
                  label: 'Watchlist',
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),

        // Actor & Country hero cards
        if (stats.favoriteActor != null && stats.favoriteActor!.isValid) ...[
          _buildHeroInfoCard(
            icon: Icons.person_rounded,
            label: 'Acteur le plus vu',
            value: stats.favoriteActor!.name,
            count: stats.favoriteActor!.count,
            cardColor: accentCardColor,
            compact: isAllTime,
          ),
          const SizedBox(height: 6),
        ],

        if (stats.favoriteCountry != null &&
            stats.favoriteCountry!.isValid) ...[
          _buildHeroInfoCard(
            icon: Icons.public_rounded,
            label: 'Pays favori',
            value: stats.favoriteCountry!.name,
            count: stats.favoriteCountry!.count,
            cardColor: countryCardColor,
          ),
          const SizedBox(height: 8),
        ],

        if (topGenres.isNotEmpty) ...[
          _buildSectionTitle('Repartition'),
          const SizedBox(height: 6),
          ...topGenres.asMap().entries.map((entry) {
            final i = entry.key;
            final genre = entry.value;
            final normalizedPercentage = normalizedGenrePercentages[i];
            final barFraction = (normalizedPercentage / 100).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildGenreBarItem(
                rank: i + 1,
                genre: genre.genre,
                percentage: normalizedPercentage.toDouble(),
                count: genre.count,
                barFraction: barFraction,
                isTop: i == 0,
                compact: isAllTime,
              ),
            );
          }),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Top ${topGenres.length} genres = 100%',
              style: GoogleFonts.dmSans(
                color: _brownAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Page 3: Mon profil cine - temps + rythme + records
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
      toneColor: const Color(0xFF8FAF9D),
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Mon profil cine', color: const Color(0xFF7EA89A)),
        const SizedBox(height: 14),

        // Big time stat - hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF7A9FB1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A9FB1).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.schedule_rounded, color: _warmGold, size: 24),
              const SizedBox(height: 6),
              Text(
                '${totalHours}h',
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'de visionnage ($totalDays jours)',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _buildSectionTitle('Mon activite'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_rounded,
                value: stats.totalSeen.toString(),
                label: 'Films vus',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_rounded,
                value: stats.totalLiked.toString(),
                label: 'Watchlist',
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 10),

        _buildSectionTitle('Mon rythme'),
        const SizedBox(height: 8),
        if (widget.period == 'alltime')
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: stats.ratedSeenCount.toString(),
                  label: 'Notes',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.edit_note_rounded,
                  value: stats.unratedSeenCount.toString(),
                  label: 'A noter',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_outlined,
                  value: avgFilmHours > 0
                      ? '${avgFilmHours}h${avgFilmMins.toString().padLeft(2, '0')}'
                      : '${avgFilmMins}min',
                  label: 'Duree moy.',
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  value: stats.weeklyFilms.toString(),
                  label: 'Films/sem.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_outlined,
                  value: avgFilmHours > 0
                      ? '${avgFilmHours}h${avgFilmMins.toString().padLeft(2, '0')}'
                      : '${avgFilmMins}min',
                  label: 'Duree moy.',
                ),
              ),
            ],
          ),

        if (widget.period == 'week' && stats.weeklyMinutes > 0) ...[
          const SizedBox(height: 10),
          _buildSectionTitle('Cette semaine'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7EA89A).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7EA89A).withValues(alpha: 0.35),
              ),
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
                          fontSize: 24,
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
                  height: 30,
                  color: const Color(0xFF7EA89A).withValues(alpha: 0.4),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stats.weeklyMinutes ~/ 60}h${(stats.weeklyMinutes % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 24,
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
    final duoName = 'Moi et $partner';
    final compatibilityValue = ((_duoData?['compatibility'] as num?) ?? 0)
        .toDouble();
    final compatibility = compatibilityValue.round().clamp(0, 100);
    final commonMovies = _duoData?['common_movies_count'] ?? 0;
    final totalMatches = _duoData?['total_matches'] ?? 0;
    final rawBreakdown = _duoData?['score_breakdown'];
    final breakdown = rawBreakdown is Map
        ? rawBreakdown.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final ratingAlignment =
        ((breakdown['rating_alignment'] as num?)?.toDouble() ??
                compatibilityValue)
            .clamp(0.0, 100.0);
    final genreAlignment =
        ((breakdown['genre_alignment'] as num?)?.toDouble() ??
                compatibilityValue)
            .clamp(0.0, 100.0);
    final historyAlignment =
        ((breakdown['history_alignment'] as num?)?.toDouble() ??
                compatibilityValue)
            .clamp(0.0, 100.0);

    final sharedGenresRaw = (_duoData?['shared_genres'] as List?) ?? const [];
    final sharedGenres = sharedGenresRaw
        .whereType<Map>()
        .map((item) {
          final name = item['genre']?.toString() ?? '';
          final pct = (item['percentage'] as num?)?.toInt() ?? 0;
          return MapEntry(name, pct.clamp(0, 100));
        })
        .where((entry) => entry.key.isNotEmpty)
        .take(2)
        .toList();

    final fallbackGenres = stats.genreDistribution.take(2).toList();
    final fallbackPercentages = _buildStablePercentages(fallbackGenres);
    final displayGenres = sharedGenres.isNotEmpty
        ? sharedGenres
        : fallbackGenres.asMap().entries.map((entry) {
            final i = entry.key;
            final genre = entry.value.genre;
            final pct = i < fallbackPercentages.length
                ? fallbackPercentages[i]
                : 0;
            return MapEntry(genre, pct);
          }).toList();

    final duoUniqueSeen =
        ((_duoData?['duo_unique_seen_count'] as num?)?.toInt() ?? commonMovies)
            .clamp(0, 99999);
    final duoCommonSeen =
        ((_duoData?['duo_common_seen_count'] as num?)?.toInt() ?? commonMovies)
            .clamp(0, 99999);
    final userSeen = ((_duoData?['user_seen_count'] as num?)?.toInt() ?? 0)
        .clamp(0, 99999);
    final partnerSeen =
        ((_duoData?['partner_seen_count'] as num?)?.toInt() ?? 0).clamp(
          0,
          99999,
        );
    final duoTotalMinutes =
        ((_duoData?['duo_total_minutes'] as num?)?.toInt() ??
                (stats.totalMinutes * 2))
            .clamp(0, 9999999);
    final duoTotalHours = duoTotalMinutes ~/ 60;
    final duoTimeLabel = duoTotalHours > 0
        ? '${duoTotalHours}h'
        : '${duoTotalMinutes}min';
    final compatibilityLabel = _compatibilityHeadline(compatibilityValue);
    const ringSize = 132.0;
    const innerRingSize = 90.0;

    return _buildStoryContainer(
      toneColor: const Color(0xFF6F89A8),
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Story compatibilite', color: const Color(0xFF4C6A83)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _brownAccent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: _brownMedium, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  duoName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'DUO',
                style: GoogleFonts.dmSans(
                  color: _brownAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A3529),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                          ),
                          CircularProgressIndicator(
                            value: compatibility / 100,
                            strokeWidth: 13,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4B6A6),
                            ),
                          ),
                          Container(
                            width: innerRingSize,
                            height: innerRingSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3C2B21),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$compatibility%',
                                style: const TextStyle(
                                  fontFamily: 'RecoletaAlt',
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      compatibilityLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildDuoMetricTile(
                      icon: Icons.movie_filter_rounded,
                      value: '$duoUniqueSeen',
                      label: 'Films vus a 2',
                    ),
                    const SizedBox(height: 8),
                    _buildDuoMetricTile(
                      icon: Icons.favorite_rounded,
                      value: '$totalMatches',
                      label: 'Matchs ensemble',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Score detaille'),
        const SizedBox(height: 8),
        _buildDuoBreakdownBar(
          label: 'Notes proches',
          score: ratingAlignment,
          color: const Color(0xFF7FA9C6),
        ),
        const SizedBox(height: 6),
        _buildDuoBreakdownBar(
          label: 'Genres communs',
          score: genreAlignment,
          color: const Color(0xFF9BBE8F),
        ),
        const SizedBox(height: 6),
        _buildDuoBreakdownBar(
          label: 'Historique partage',
          score: historyAlignment,
          color: const Color(0xFFD0A991),
        ),
        const SizedBox(height: 10),
        if (displayGenres.isNotEmpty) ...[
          _buildSectionTitle('Genres en duo'),
          const SizedBox(height: 8),
          ...displayGenres.asMap().entries.map((entry) {
            final i = entry.key;
            final genre = entry.value.key;
            final percentage = entry.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: i == 0
                        ? _caramel.withValues(alpha: 0.5)
                        : _brownAccent.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _caramel.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.dmSans(
                            color: _brownDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        genre,
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownDark,
                          fontSize: 13,
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
                        '$percentage%',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: _brownMedium,
                          fontSize: 12,
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
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.groups_rounded,
                value: '$duoCommonSeen',
                label: 'En commun',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                value: duoTimeLabel,
                label: 'Temps total duo',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.person_rounded,
                value: '$userSeen/$partnerSeen',
                label: 'Moi / Ami',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDuoStoryPage2() {
    final partner = widget.partnerName ?? 'Ami';
    final shortPartner = partner.length > 12
        ? '${partner.substring(0, 12)}...'
        : partner;
    final userSeen = ((_duoData?['user_seen_count'] as num?)?.toInt() ?? 0)
        .clamp(0, 99999);
    final partnerSeen =
        ((_duoData?['partner_seen_count'] as num?)?.toInt() ?? 0).clamp(
          0,
          99999,
        );
    final duoCombinedSeen =
        ((_duoData?['duo_combined_seen_count'] as num?)?.toInt() ??
                (userSeen + partnerSeen))
            .clamp(0, 99999);
    final duoUniqueSeen =
        ((_duoData?['duo_unique_seen_count'] as num?)?.toInt() ?? 0).clamp(
          0,
          99999,
        );
    final duoTotalMinutes =
        ((_duoData?['duo_total_minutes'] as num?)?.toInt() ?? 0).clamp(
          0,
          9999999,
        );
    final duoUniqueMinutes =
        ((_duoData?['duo_unique_total_minutes'] as num?)?.toInt() ?? 0).clamp(
          0,
          9999999,
        );
    final ratedCommon =
        ((_duoData?['rated_common_movies_count'] as num?)?.toInt() ?? 0).clamp(
          0,
          99999,
        );
    final confidence = ((_duoData?['confidence'] as num?)?.toDouble() ?? 0.0)
        .clamp(0.0, 100.0);

    String formatMinutes(int minutes) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (hours > 0) return '${hours}h${mins.toString().padLeft(2, '0')}';
      return '${mins}min';
    }

    return _buildStoryContainer(
      toneColor: const Color(0xFF7D9A8A),
      children: [
        _buildStoryHeader(),
        const SizedBox(height: 16),
        _buildBadge('Stats duo +', color: const Color(0xFF5D7D68)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _brownAccent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: _brownMedium,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Projection duo: vous + $partner',
                  style: GoogleFonts.dmSans(
                    color: _brownDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.movie_creation_rounded,
                value: '$duoCombinedSeen',
                label: 'Vus cumules',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.groups_rounded,
                value: '$duoUniqueSeen',
                label: 'Vus a deux',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule_rounded,
                value: formatMinutes(duoTotalMinutes),
                label: 'Temps duo',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.person_rounded,
                value: '$userSeen',
                label: 'Moi',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.person_outline_rounded,
                value: '$partnerSeen',
                label: shortPartner,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.compare_arrows_rounded,
                value: '$ratedCommon',
                label: 'Notes comparees',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brownAccent.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Confiance du score',
                  style: GoogleFonts.dmSans(
                    color: _brownDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                  '${confidence.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brownAccent.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Temps unique a deux',
                  style: GoogleFonts.dmSans(
                    color: _brownDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMinutes(duoUniqueMinutes),
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  color: _brownDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoMetricTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterMetric({
    required IconData icon,
    required String value,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? _brownMedium : _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? null
            : Border.all(color: _brownAccent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15, color: highlight ? _warmGold : _brownLight),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              color: highlight ? Colors.white : _brownDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: highlight
                  ? Colors.white.withValues(alpha: 0.85)
                  : _brownAccent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterHeaderChip({
    IconData? icon,
    required String label,
    bool strong = false,
  }) {
    final color = strong ? _brownMedium : _brownAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: strong
            ? _brownMedium.withValues(alpha: 0.14)
            : _cardWhite.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterHeroPanel({
    required String title,
    required String primaryValue,
    required String primaryLabel,
    required String secondaryValue,
    required String secondaryLabel,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            primaryValue,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          Text(
            primaryLabel,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    secondaryLabel,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  secondaryValue,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterGenreStrip({
    required List<GenreStats> topGenres,
    required List<int> topGenrePcts,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brownAccent.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topGenres.asMap().entries.map((entry) {
          final i = entry.key;
          final genre = entry.value.genre;
          final pct = i < topGenrePcts.length ? topGenrePcts[i] : 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: i == 0
                  ? _brownMedium.withValues(alpha: 0.12)
                  : _brownAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$genre $pct%',
              style: GoogleFonts.dmSans(
                color: _brownDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTwitterGenreProgress({
    required int rank,
    required String genre,
    required int percentage,
    required Color accent,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            '$rank',
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              color: _brownMedium,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: _brownDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: accent.withValues(alpha: 0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              color: _brownDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwitterInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brownAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _brownAccent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: _brownMedium),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: _brownAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterFavoriteMovieRow(FavoriteMovie movie) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _caramel.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie.posterPath,
              width: 58,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 84,
                decoration: BoxDecoration(
                  color: _brownAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.movie_rounded,
                  color: _brownLight,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dernier coup de coeur',
                  style: GoogleFonts.dmSans(
                    color: _brownAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (movie.runtime > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.formattedRuntime,
                    style: GoogleFonts.dmSans(
                      color: _brownAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8A5A44).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF8A5A44),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  movie.userRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Color(0xFF5A3F34),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuoBreakdownBar({
    required String label,
    required double score,
    required Color color,
  }) {
    final clamped = score.clamp(0.0, 100.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brownAccent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: _brownDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 7,
                backgroundColor: color.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${clamped.round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                color: _brownMedium,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compatibilityHeadline(double score) {
    if (score >= 80) return 'duo ultra compatible';
    if (score >= 60) return 'duo solide';
    if (score >= 40) return 'duo complementaire';
    return 'duo a decouvrir';
  }

  // ===========================================================================
  // SHARED BUILDING BLOCKS
  // ===========================================================================

  Widget _buildStoryContainer({
    required List<Widget> children,
    String? footerSubtitle,
    Color? toneColor,
  }) {
    final tone = toneColor ?? _caramel;
    const radius = 24.0;
    const sidePadding = 20.0;
    const topPadding = 16.0;
    const bottomPadding = 12.0;
    const waveHeight = 126.0;
    const topCircleSize = 120.0;
    const bottomCircleSize = 100.0;
    final aspectRatio = _activeStoryWidth / _activeStoryHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _activeStoryWidth;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _activeStoryHeight;

        var width = _activeStoryWidth;
        var height = _activeStoryHeight;

        if (width > maxWidth) {
          width = maxWidth;
          height = width / aspectRatio;
        }
        if (height > maxHeight) {
          height = maxHeight;
          width = height * aspectRatio;
        }

        final contentWidth = width - (sidePadding * 2);
        final effectiveWaveHeight = _isTwitterFormat ? 86.0 : waveHeight;

        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _bgCream,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tone.withValues(alpha: 0.18)),
          ),
          child: Stack(
            children: [
              // Subtle decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: topCircleSize,
                  height: topCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: -40,
                child: Container(
                  width: bottomCircleSize,
                  height: bottomCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Decorative wave at bottom (wider and lower)
              Positioned(
                bottom: -14,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
                  child: CustomPaint(
                    size: Size(width, effectiveWaveHeight),
                    painter: _ModernWavePainter(
                      color: tone.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  topPadding,
                  sidePadding,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, contentConstraints) {
                          if (_isTwitterFormat) {
                            return SizedBox(
                              width: contentWidth,
                              height: contentConstraints.maxHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children,
                              ),
                            );
                          }
                          final content = SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            ),
                          );
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: content,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStoryFooter(
                      subtitle: footerSubtitle,
                      compact: _isTwitterFormat,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryHeader({bool compact = false}) {
    final isCompact = compact;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logoB.svg',
            height: isCompact ? 24 : 32,
            colorFilter: const ColorFilter.mode(_brownMedium, BlendMode.srcIn),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Text(
            'MoovieCoffee',
            style: TextStyle(
              fontFamily: 'HolyCream',
              color: _brownDark,
              fontSize: isCompact ? 19 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBadge() {
    return _buildBadge(
      widget.period == 'week' ? 'Cette semaine' : 'All Time',
      color: widget.period == 'week'
          ? const Color(0xFF2F7F93)
          : const Color(0xFF8A5A44),
    );
  }

  Widget _buildBadge(String text, {Color? color}) {
    final badgeColor = color ?? _brownMedium;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.2),
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
    required Color cardColor,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 18 : 24),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    fontSize: compact ? 14 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count films',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: compact ? 11 : 12,
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
    bool compact = false,
  }) {
    final rankLabel = '$rank.';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
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
                  fontSize: compact ? 12 : (rank <= 3 ? 16 : 13),
                  color: _brownDark,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  genre,
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: _brownDark,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'RecoletaAlt',
                  color: _brownMedium,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(
                '($count)',
                style: GoogleFonts.dmSans(
                  color: _brownAccent,
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barFraction.clamp(0.0, 1.0),
              minHeight: compact ? 5 : 6,
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
                    color: const Color(0xFF8A5A44).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8A5A44).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF8A5A44),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.userRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          color: const Color(0xFF5A3F34),
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

  Widget _buildStoryFooter({String? subtitle, bool compact = false}) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 6 : 8,
        ),
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
              height: compact ? 14 : 16,
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
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
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
    path.lineTo(0, size.height * 0.58);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.36,
      size.width * 0.5,
      size.height * 0.52,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.72,
      size.width,
      size.height * 0.52,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
