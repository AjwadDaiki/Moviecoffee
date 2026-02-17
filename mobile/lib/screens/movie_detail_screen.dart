import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/coffee_colors.dart';
import '../services/app_preferences.dart';
import 'chat_detail_screen.dart';

/// =============================================================================
/// MOVIE DETAIL SCREEN - Page detail premium
/// =============================================================================

class MovieDetailScreen extends StatefulWidget {
  final int tmdbId;
  final String? posterUrl;
  final String? title;

  const MovieDetailScreen({
    super.key,
    required this.tmdbId,
    this.posterUrl,
    this.title,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _apiService = ApiService();
  MovieDetail? _movie;
  bool _isLoading = true;
  String? _error;
  String _preferredLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _loadUserLanguageAndMovie();
  }

  Future<void> _loadUserLanguageAndMovie() async {
    try {
      final lang = await AppPreferences.getPreferredLanguage();
      _preferredLanguage = lang.trim().isEmpty ? 'fr' : lang.trim();
    } catch (_) {}
    await _loadMovieDetail(languageCode: _preferredLanguage);
  }

  Future<void> _loadMovieDetail({String? languageCode}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getMovieDetail(
        widget.tmdbId,
        languageCode: languageCode,
      );
      if (result != null && mounted) {
        setState(() {
          _movie = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Impossible de charger les détails';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openTrailer() async {
    final trailer = _movie?.trailer;
    if (trailer == null || !trailer.isValid) return;

    final uri = Uri.parse(trailer.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatRuntime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  String _formatBudget(int amount) {
    if (amount == 0) return '';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(0)}M\$';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K\$';
    return '\$$amount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(loading: true),
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(loading: false),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 16),
                Text('Erreur de chargement', style: AppTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error ?? '', style: AppTheme.bodyMedium),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loadMovieDetail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Réessayer',
                      style: AppTheme.labelLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final m = _movie!;
    final localizedTitle = (m.localizedTitle ?? '').trim();
    final localizedOverview = (m.localizedOverview ?? '').trim();
    final title = localizedTitle.isNotEmpty
        ? localizedTitle
        : (m.title.display.isNotEmpty ? m.title.display : (widget.title ?? ''));
    final overview = localizedOverview.isNotEmpty
        ? localizedOverview
        : m.overview.display;
    final backdrop = m.backdropPath ?? '';
    final poster = m.posterPath.isNotEmpty
        ? m.posterPath
        : (widget.posterUrl ?? '');
    final tagline = m.tagline ?? '';
    final year = m.year;
    final budget = m.budget ?? 0;
    final revenue = m.revenue ?? 0;

    return CustomScrollView(
      slivers: [
        // --- HERO IMAGE ---
        _buildHeroAppBar(
          backdrop: backdrop,
          poster: poster,
          title: title,
          tagline: tagline,
          year: year,
          runtime: m.runtime,
          voteAvg: m.voteAverage,
          hasTrailer: m.hasTrailer,
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // --- STATUS UTILISATEUR ---
                if (m.isSeen || m.isLiked || m.userRating != null)
                  _buildUserStatus(
                    isSeen: m.isSeen,
                    isLiked: m.isLiked,
                    userRating: m.userRating,
                  ),

                // --- GENRES ---
                if (m.genres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildGenreChips(m.genres),
                ],

                // --- INFO BADGES ---
                if (m.runtime > 0 || year.isNotEmpty || m.voteAverage > 0) ...[
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    year: year,
                    runtime: m.runtime,
                    voteAvg: m.voteAverage,
                    budget: budget,
                    revenue: revenue,
                  ),
                ],

                const SizedBox(height: 18),
                _buildShareCallout(title: title),

                // --- SYNOPSIS ---
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Synopsis', style: AppTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    overview,
                    style: AppTheme.bodyLarge.copyWith(height: 1.6),
                  ),
                ],

                // --- REALISATEUR ---
                if (m.directors.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Réalisation', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildDirectors(m.directors),
                ],

                // --- CASTING ---
                if (m.cast.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Casting', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                ] else if (m.actors.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Acteurs', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: m.actors.map((a) => _buildChip(a)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        // --- CAST HORIZONTAL ---
        if (m.cast.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: m.cast.length,
                itemBuilder: (context, index) => _buildCastCard(m.cast[index]),
              ),
            ),
          ),

        // --- PLATEFORMES ---
        if (m.providers.hasAny)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Text('Où regarder', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildProviders(m.providers),
                ],
              ),
            ),
          ),

        // --- FILMS SIMILAIRES ---
        if (m.similar.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Films similaires', style: AppTheme.titleMedium),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: m.similar.length,
                    itemBuilder: (context, index) =>
                        _buildSimilarCard(m.similar[index]),
                  ),
                ),
              ],
            ),
          ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  // ===========================================================================
  // HERO APP BAR
  // ===========================================================================

  Widget _buildSliverAppBar({required bool loading}) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceDark,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: widget.posterUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.posterUrl!,
                fit: BoxFit.cover,
                color: Colors.black45,
                colorBlendMode: BlendMode.darken,
              )
            : Container(color: AppTheme.surfaceDark),
      ),
    );
  }

  Widget _buildHeroAppBar({
    required String backdrop,
    required String poster,
    required String title,
    required String tagline,
    required String year,
    required int runtime,
    required double voteAvg,
    required bool hasTrailer,
  }) {
    final heroImage = backdrop.isNotEmpty ? backdrop : poster;

    return SliverAppBar(
      expandedHeight: 380,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceDark,
      leading: _buildBackButton(),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => _showShareDialog(title),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (heroImage.isNotEmpty)
              CachedNetworkImage(
                imageUrl: heroImage,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppTheme.surfaceDark),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(
                    Icons.movie_outlined,
                    size: 60,
                    color: AppTheme.textTertiary,
                  ),
                ),
              )
            else
              Container(color: AppTheme.surfaceDark),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.surfaceDark.withValues(alpha: 0.4),
                    AppTheme.surfaceDark.withValues(alpha: 0.95),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Content at bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: Colors.white,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tagline
                  if (tagline.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      tagline,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Actions row
                  Row(
                    children: [
                      // Play trailer
                      if (hasTrailer)
                        GestureDetector(
                          onTap: _openTrailer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C7DA0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2C7DA0,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bande-annonce',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (hasTrailer) const SizedBox(width: 12),

                      // Quick info chips
                      if (year.isNotEmpty) _buildHeroChip(year),
                      if (runtime > 0) ...[
                        const SizedBox(width: 8),
                        _buildHeroChip(_formatRuntime(runtime)),
                      ],
                      if (voteAvg > 0) ...[
                        const SizedBox(width: 8),
                        _buildHeroChip(
                          '${voteAvg.toStringAsFixed(1)}',
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showShareDialog(String movieTitle) async {
    // Load friends list
    List<Friend> friends = [];
    try {
      final data = await _apiService.getFriendsList();
      if (data != null) friends = data.friends;
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(
                    Icons.send_rounded,
                    size: 22,
                    color: CoffeeColors.caramelBronze,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Envoyer à un ami',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                movieTitle,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CoffeeColors.espresso,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Ajoutez ce film au brouillon d'un chat puis envoyez avec votre message.",
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: CoffeeColors.moka,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: CoffeeColors.steamMilk,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun ami pour le moment',
                            style: GoogleFonts.dmSans(color: CoffeeColors.moka),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return _buildShareFriendTile(friend, movieTitle);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareFriendTile(Friend friend, String movieTitle) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close modal
        // Send the movie suggestion as a chat message
        _sendMovieSuggestion(friend.username, movieTitle, widget.tmdbId);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CoffeeColors.caramelBronze, CoffeeColors.espresso],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friend.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RecoletaAlt',
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.username,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                  if (friend.hasBio)
                    Text(
                      friend.bio!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: CoffeeColors.moka,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CoffeeColors.caramelBronze.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 18,
                color: CoffeeColors.caramelBronze,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMovieSuggestion(
    String username,
    String movieTitle,
    int movieId,
  ) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Film ajouté au brouillon de chat avec $username'),
        backgroundColor: CoffeeColors.caramelBronze,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          username: username,
          matchMovieId: movieId,
          matchMovieTitle: movieTitle,
          matchMoviePoster: widget.posterUrl,
        ),
      ),
    );
  }

  Widget _buildHeroChip(String text, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // USER STATUS
  // ===========================================================================

  Widget _buildUserStatus({
    required bool isSeen,
    required bool isLiked,
    double? userRating,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            isSeen ? Icons.visibility_rounded : Icons.bookmark_rounded,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSeen
                      ? 'Film vu'
                      : isLiked
                      ? 'Dans votre watchlist'
                      : '',
                  style: AppTheme.labelLarge.copyWith(fontSize: 13),
                ),
                if (userRating != null && userRating > 0)
                  Row(
                    children: [
                      Text('Votre note : ', style: AppTheme.caption),
                      ...List.generate(5, (i) {
                        final starValue = i + 1.0;
                        return Icon(
                          starValue <= userRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: starValue <= userRating
                              ? Colors.amber
                              : AppTheme.textTertiary,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        userRating.toStringAsFixed(1),
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GENRES
  // ===========================================================================

  Widget _buildGenreChips(List<String> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((g) => _buildChip(g)).toList(),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ===========================================================================
  // INFO ROW
  // ===========================================================================

  Widget _buildInfoRow({
    required String year,
    required int runtime,
    required double voteAvg,
    required int budget,
    required int revenue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(radius: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (year.isNotEmpty)
            _buildInfoItem(Icons.calendar_today_rounded, year, 'Sortie'),
          if (runtime > 0)
            _buildInfoItem(
              Icons.schedule_rounded,
              _formatRuntime(runtime),
              'Durée',
            ),
          if (voteAvg > 0)
            _buildInfoItem(
              Icons.star_rounded,
              voteAvg.toStringAsFixed(1),
              'Note',
              iconColor: Colors.amber,
            ),
          if (budget > 0)
            _buildInfoItem(
              Icons.monetization_on_rounded,
              _formatBudget(budget),
              'Budget',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppTheme.accent),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.labelLarge.copyWith(fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildShareCallout({required String title}) {
    return GestureDetector(
      onTap: () => _showShareDialog(title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CoffeeColors.caramelBronze.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2C7DA0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 22,
                color: Color(0xFF2C7DA0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Envoyer ce film à un ami',
                    style: AppTheme.labelLarge.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Proposez-le dans une conversation et regardez-le ensemble.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: CoffeeColors.moka,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DIRECTORS
  // ===========================================================================

  Widget _buildDirectors(List<Director> directors) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: directors.map((dir) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dir.profilePath != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: dir.profilePath!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppTheme.accent,
                ),
              ),
            const SizedBox(width: 10),
            Text(dir.name, style: AppTheme.labelLarge.copyWith(fontSize: 14)),
          ],
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // CAST CARDS
  // ===========================================================================

  Widget _buildCastCard(CastMember actor) {
    final photo = actor.profilePath;
    final name = actor.name;
    final character = actor.character;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: photo != null
                ? CachedNetworkImage(
                    imageUrl: photo,
                    width: 90,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 90,
                      height: 100,
                      color: AppTheme.accentSoft,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 100,
                      color: AppTheme.accentSoft,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppTheme.textTertiary,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (character.isNotEmpty)
            Text(
              character,
              style: AppTheme.caption.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROVIDERS
  // ===========================================================================

  Widget _buildProviders(ProvidersData providers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (providers.flatrate.isNotEmpty)
          _buildProviderRow('Streaming', providers.flatrate),
        if (providers.rent.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildProviderRow('Location', providers.rent),
        ],
        if (providers.buy.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildProviderRow('Achat', providers.buy),
        ],
      ],
    );
  }

  Widget _buildProviderRow(String label, List<StreamingProvider> providers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: providers.map((prov) {
              return Tooltip(
                message: prov.name,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: prov.logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: prov.logo,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          color: AppTheme.accentSoft,
                          child: Center(
                            child: Text(
                              prov.name.isNotEmpty ? prov.name[0] : '?',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SIMILAR MOVIES
  // ===========================================================================

  Widget _buildSimilarCard(SimilarMovie movie) {
    return GestureDetector(
      onTap: () {
        if (movie.tmdbId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(
                tmdbId: movie.tmdbId,
                posterUrl: movie.posterPath,
                title: movie.title,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: movie.hasPoster
                  ? CachedNetworkImage(
                      imageUrl: movie.posterPath,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 120,
                        height: 160,
                        color: AppTheme.accentSoft,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 120,
                        height: 160,
                        color: AppTheme.accentSoft,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 160,
                      color: AppTheme.accentSoft,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: AppTheme.textTertiary,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
