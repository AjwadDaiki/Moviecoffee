import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/coffee_colors.dart';
import 'chat_detail_screen.dart';

/// =============================================================================
/// USER PROFILE SCREEN - Profil public d'un utilisateur
/// =============================================================================

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _apiService = ApiService();
  PublicProfile? _profile;
  bool _isLoading = true;
  String _ratedSort = 'rating'; // 'rating' ou 'date'

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getPublicProfile(widget.username);
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          username: widget.username,
          userBio: _profile?.bio,
        ),
      ),
    );
  }

  List<RatedMovie> get _sortedRatedMovies {
    final movies = List<RatedMovie>.from(_profile?.ratedMovies ?? []);
    if (_ratedSort == 'date') {
      movies.sort((a, b) => b.date.compareTo(a.date));
    }
    // Default is already sorted by rating from backend
    return movies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CoffeeColors.caramelBronze))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_profile == null) {
      return const Center(child: Text('Profil introuvable'));
    }

    final stats = _profile!.stats;
    final commonMovies = _profile!.commonMovies;
    final ratedMovies = _sortedRatedMovies;

    return CustomScrollView(
      slivers: [
        // App Bar - clean light header matching body
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppTheme.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowSmall,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: CoffeeColors.espresso, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppTheme.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    // Decorative glow behind avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft circle glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                CoffeeColors.caramelBronze.withValues(alpha: 0.15),
                                CoffeeColors.caramelBronze.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                        // Avatar with subtle gradient
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [CoffeeColors.caramelBronze, Color(0xFF8D6E63)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CoffeeColors.caramelBronze.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'RecoletaAlt',
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Username with Poppins
                    Text(
                      widget.username,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_profile!.hasBio) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _profile!.bio!,
                          style: TextStyle(
                            color: CoffeeColors.moka.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Quick Stats - modern cards with shadows and icon circles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.movie_rounded,
                      iconColor: const Color(0xFF8D6E63),
                      value: stats.totalSeen.toString(),
                      label: 'Films vus',
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFD4A056),
                      value: stats.averageRating.toStringAsFixed(1),
                      label: 'Note moyenne',
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.emoji_events_rounded,
                      iconColor: CoffeeColors.caramelBronze,
                      value: 'Niv. ${stats.level}',
                      label: 'Niveau',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Compatibility - with percentage ring and thicker bar
              if (_profile!.isFriend && _profile!.compatibility > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: Row(
                      children: [
                        // Percentage ring
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CustomPaint(
                            painter: _CompatibilityRingPainter(
                              progress: _profile!.compatibility / 100,
                              backgroundColor: CoffeeColors.creamBorder,
                              foregroundColor: CoffeeColors.caramelBronze,
                              strokeWidth: 5,
                            ),
                            child: Center(
                              child: Text(
                                '${_profile!.compatibility}%',
                                style: const TextStyle(
                                  fontFamily: 'RecoletaAlt',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: CoffeeColors.caramelBronze,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Compatibilite',
                                style: TextStyle(
                                  fontFamily: 'RecoletaAlt',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: CoffeeColors.espresso,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _profile!.compatibility / 100,
                                  minHeight: 10,
                                  backgroundColor: CoffeeColors.creamBorder,
                                  valueColor: const AlwaysStoppedAnimation(CoffeeColors.caramelBronze),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Top Genres
              if (stats.topGenres.isNotEmpty) ...[
                _buildSectionTitle('Genres preferes'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats.topGenres.take(5).map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Films notes
              if (ratedMovies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Films notes',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CoffeeColors.espresso,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CoffeeColors.caramelBronze,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ratedMovies.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Sort toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _ratedSort = _ratedSort == 'rating' ? 'date' : 'rating';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.shadowSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _ratedSort == 'rating' ? Icons.star_rounded : Icons.schedule_rounded,
                                size: 14,
                                color: CoffeeColors.caramelBronze,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _ratedSort == 'rating' ? 'Par note' : 'Par date',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CoffeeColors.espresso,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...ratedMovies.take(10).map((movie) => _RatedMovieCard(movie: movie)),
                if (ratedMovies.length > 10) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        '+${ratedMovies.length - 10} autres films',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CoffeeColors.moka,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Common Movies
              if (commonMovies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Films en commun',
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CoffeeColors.espresso,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CoffeeColors.caramelBronze,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${commonMovies.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: commonMovies.length,
                    itemBuilder: (context, index) {
                      final movie = commonMovies[index];
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            movie.poster,
                            width: 90,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.movie_rounded, color: CoffeeColors.moka),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Button - full-width gradient Message button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _openChat,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [CoffeeColors.caramelBronze, Color(0xFF8D6E63)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: CoffeeColors.caramelBronze.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Envoyer un message',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'RecoletaAlt',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: CoffeeColors.espresso,
        ),
      ),
    );
  }
}

/// =============================================================================
/// COMPATIBILITY RING PAINTER - Circular progress indicator
/// =============================================================================

class _CompatibilityRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  _CompatibilityRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompatibilityRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// =============================================================================
/// RATED MOVIE CARD
/// =============================================================================

class _RatedMovieCard extends StatelessWidget {
  final RatedMovie movie;

  const _RatedMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with subtle shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CoffeeColors.espresso.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: movie.hasPoster
                  ? Image.network(
                      movie.poster,
                      width: 55,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _posterPlaceholder(),
                    )
                  : _posterPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Stars with warm gold color
                Row(
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return Icon(
                      starValue <= movie.rating
                          ? Icons.star_rounded
                          : starValue - 0.5 <= movie.rating
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded,
                      size: 18,
                      color: const Color(0xFFD4A056),
                    );
                  }),
                ),
                if (movie.hasComment) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      movie.comment,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: CoffeeColors.moka,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 55,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.movie_rounded, color: CoffeeColors.moka, size: 24),
    );
  }
}

/// =============================================================================
/// STAT CARD - Modern with icon background circle and shadow
/// =============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          children: [
            // Rounded icon with colored background circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: CoffeeColors.espresso,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CoffeeColors.moka,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
