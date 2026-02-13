import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/coffee_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/community/friend_card.dart';
import 'chat_detail_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';
import 'movie_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();

  // Data
  List<MovieMatch> _matches = [];
  List<Friend> _friends = [];
  List<Friend> _friendRequestsReceived = [];
  List<Friend> _friendRequestsSent = [];
  List<Conversation> _conversations = [];
  List<FeedActivity> _feedActivities = [];
  final Map<int, MovieDetail> _matchDetailsCache = {};
  bool _isLoading = true;
  int _unviewedMatchesCount = 0;

  // Filtre matchs par partenaire
  String? _selectedMatchPartner; // null = tous

  // Auto-refresh
  late final Stream<int> _refreshTimer = Stream<int>.periodic(
    const Duration(seconds: 15),
    (tick) => tick,
  );
  late final StreamSubscription<int> _refreshSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();

    // Auto-refresh toutes les 15 secondes
    _refreshSubscription = _refreshTimer.listen((_) {
      if (mounted && !_isRefreshing && !_isLoading) {
        _silentRefresh();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Refresh silencieux (sans loader visible)
  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final results = await Future.wait<dynamic>([
        _apiService.getMatches(limit: 20).catchError((_) => <MovieMatch>[]),
        _apiService.getFriendsList().catchError((_) => null),
        _apiService.getConversations().catchError((_) => <Conversation>[]),
        _apiService.getUnviewedMatchesCount().catchError((_) => 0),
        _apiService
            .getSocialFeed(page: 1, limit: 30)
            .catchError((_) => <FeedActivity>[]),
      ]);

      final matches = results[0] as List<MovieMatch>;
      final friendsData = results[1] as FriendsData?;
      final conversations = results[2] as List<Conversation>;
      final unviewedCount = results[3] as int;
      final feedActivities = results[4] as List<FeedActivity>;

      if (mounted) {
        setState(() {
          _matches = matches;
          if (friendsData != null) {
            _friends = friendsData.friends;
            _friendRequestsReceived = friendsData.requestsReceived;
            _friendRequestsSent = friendsData.requestsSent;
          }
          _conversations = conversations;
          _unviewedMatchesCount = unviewedCount;
          _feedActivities = feedActivities;
        });
      }
    } catch (_) {
      // Silencieux
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait<dynamic>([
      _apiService.getMatches(limit: 20).catchError((_) => <MovieMatch>[]),
      _apiService.getFriendsList().catchError((_) => null),
      _apiService.getConversations().catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
      _apiService
          .getSocialFeed(page: 1, limit: 30)
          .catchError((_) => <FeedActivity>[]),
    ]);

    _matches = results[0] as List<MovieMatch>;
    final friendsData = results[1] as FriendsData?;
    _conversations = results[2] as List<Conversation>;
    _unviewedMatchesCount = results[3] as int;
    _feedActivities = results[4] as List<FeedActivity>;

    if (friendsData != null) {
      _friends = friendsData.friends;
      _friendRequestsReceived = friendsData.requestsReceived;
      _friendRequestsSent = friendsData.requestsSent;
    } else {
      _friends = [];
      _friendRequestsReceived = [];
      _friendRequestsSent = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Tabs chips
          _buildTabBar(),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTab(),
                _buildMatchesTab(),
                _buildFriendsTab(),
                _buildChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Titre avec style unifiÃƒÆ’Ã‚Â©
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Communaute',
                style: TextStyle(
                  fontFamily: 'RecoletaAlt',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_friends.length} amis / ${_matches.length} matchs',
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
            children: [
              // Badge notification matchs non vus
              if (_unviewedMatchesCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3529),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CoffeeColors.caramelBronze.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$_unviewedMatchesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Bouton recherche amis
              GestureDetector(
                onTap: _openSearch,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3529),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CoffeeColors.caramelBronze.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTabChip(
            0,
            Icons.dynamic_feed_rounded,
            'Feed',
            _feedActivities.length,
          ),
          const SizedBox(width: 10),
          _buildTabChip(1, Icons.favorite_rounded, 'Matchs', _matches.length),
          const SizedBox(width: 10),
          _buildTabChip(2, Icons.people_rounded, 'Amis', _friends.length),
          const SizedBox(width: 10),
          _buildTabChip(
            3,
            Icons.chat_bubble_rounded,
            'Chat',
            _conversations.length,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, IconData icon, String label, int count) {
    final isActive = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() => _tabController.animateTo(index));
      },
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? CoffeeColors.caramelBronze : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? CoffeeColors.caramelBronze : AppTheme.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: CoffeeColors.caramelBronze.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppTheme.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 1: FEED SOCIAL - Design moderne poster-centric
  // ============================================================================

  Widget _buildFeedTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_feedActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dynamic_feed_outlined,
        title: 'Aucune activite',
        subtitle: 'Suivez des amis pour voir leur activite!',
        action: TextButton.icon(
          onPressed: _openSearch,
          icon: Icon(Icons.person_add, color: AppTheme.accent),
          label: Text(
            'Ajouter des amis',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
      );
    }

    final timelineActivities = _buildTimelineActivities();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          _buildNewsHeader(timelineActivities),
          if (timelineActivities.isEmpty)
            _buildFilteredFeedEmptyState()
          else
            ..._buildFeedTimeline(timelineActivities),
        ],
      ),
    );
  }

  List<FeedActivity> _buildTimelineActivities() {
    final activities = _feedActivities.where((activity) {
      return activity.actionType == ActivityType.rated ||
          activity.actionType == ActivityType.commented;
    }).toList();

    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activities;
  }

  Widget _buildNewsHeader(List<FeedActivity> activities) {
    final now = DateTime.now();
    final todayCount = activities.where((activity) {
      final date = activity.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
    final thisWeekCount = activities.where((activity) {
      return now.difference(activity.createdAt).inDays < 7;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF5EEE4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3529),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fil d\'actualite cine',
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                  ),
                ),
              ),
              Text(
                '${activities.length} posts',
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CoffeeColors.moka,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildNewsMetricPill(
                icon: Icons.today_rounded,
                label: 'Aujourd\'hui',
                value: '$todayCount',
              ),
              const SizedBox(width: 8),
              _buildNewsMetricPill(
                icon: Icons.date_range_rounded,
                label: '7 jours',
                value: '$thisWeekCount',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsMetricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF7F1E8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoffeeColors.creamBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CoffeeColors.caramelBronze),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeedTimeline(List<FeedActivity> activities) {
    final widgets = <Widget>[];
    DateTime? currentDay;

    for (final activity in activities) {
      final day = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      if (currentDay == null || !_isSameDay(currentDay, day)) {
        widgets.add(_buildTimelineDayDivider(day));
        currentDay = day;
      }
      widgets.add(_buildFeedCard(activity));
    }

    return widgets;
  }

  Widget _buildTimelineDayDivider(DateTime day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: CoffeeColors.steamMilk.withValues(alpha: 0.45),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _formatTimelineDay(day),
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CoffeeColors.moka,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: CoffeeColors.steamMilk.withValues(alpha: 0.45),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimelineDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(day, today)) return 'Aujourd\'hui';
    if (_isSameDay(day, yesterday)) return 'Hier';
    return '${day.day}/${day.month}/${day.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildFilteredFeedEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CoffeeColors.steamMilk.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.new_releases_outlined,
            size: 30,
            color: CoffeeColors.moka,
          ),
          const SizedBox(height: 10),
          Text(
            'Aucune activite recente',
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Le fil va se remplir quand vos amis noteront ou commenteront des films.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 13,
              color: CoffeeColors.moka,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadData,
            child: const Text('Actualiser le fil'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(FeedActivity activity) {
    final username = activity.username.isNotEmpty
        ? activity.username
        : 'Utilisateur';
    final timeAgo = _formatTimeAgoDate(activity.createdAt);
    final posterUrl = activity.moviePoster;
    final movieId = activity.movieId ?? 0;
    final movieTitle = (activity.movieTitle ?? '').trim().isEmpty
        ? 'Film'
        : activity.movieTitle!.trim();
    final rating = activity.rating;
    final engagement = activity.engagement;
    final hasLiked = engagement.userHasLiked;
    final commentPreview = activity.comment?.trim() ?? '';

    // Action label
    String actionLabel = '';
    if (activity.actionType == ActivityType.rated && rating != null) {
      actionLabel = 'a note ${rating.toStringAsFixed(1)}/5';
    } else if (activity.actionType == ActivityType.commented) {
      actionLabel = 'a commente';
    } else if (activity.actionType == ActivityType.rated) {
      actionLabel = 'a vu';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFF3ECE3),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CoffeeColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header utilisateur
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openProfile(username),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5A4335), Color(0xFF3D2C21)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        username[0].toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openProfile(username),
                        child: Text(
                          username,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                      ),
                      if (actionLabel.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                fontFamily: 'RecoletaAlt',
                                fontSize: 12,
                                color: CoffeeColors.moka,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (rating != null) ...[
                              const SizedBox(width: 4),
                              ...List.generate(5, (i) {
                                final starVal = i + 1;
                                return Icon(
                                  starVal <= rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 12,
                                  color: starVal <= rating.round()
                                      ? const Color(0xFFFFC107)
                                      : CoffeeColors.steamMilk,
                                );
                              }),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 12,
                    color: CoffeeColors.moka,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Poster du film
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: movieId > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(
                            tmdbId: movieId,
                            posterUrl: posterUrl,
                            title: movieTitle,
                          ),
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: posterUrl != null
                    ? Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.8,
                            child: Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => Container(
                                color: CoffeeColors.steamMilk,
                                child: const Center(
                                  child: Icon(
                                    Icons.movie_rounded,
                                    size: 48,
                                    color: CoffeeColors.moka,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gradient bottom for title
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 88,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x001F140F),
                                    Color(0x801F140F),
                                    Color(0xE62D1F14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Movie title
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Text(
                              movieTitle,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CoffeeColors.latteCream,
                              CoffeeColors.milkFoam,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.movie_rounded,
                                size: 36,
                                color: CoffeeColors.moka,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                movieTitle,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: CoffeeColors.espresso,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Actions et extrait du commentaire
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFeedActionPill(
                      icon: hasLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: engagement.likesCount > 0
                          ? _formatCount(engagement.likesCount)
                          : 'J\'aime',
                      highlight: hasLiked,
                      onTap: () => _likeActivity(activity.id),
                    ),
                    const SizedBox(width: 8),
                    _buildFeedActionPill(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: engagement.commentsCount > 0
                          ? _formatCount(engagement.commentsCount)
                          : 'Commentaires',
                    ),
                    const Spacer(),
                    if (movieId > 0)
                      _buildFeedActionPill(
                        icon: Icons.open_in_new_rounded,
                        label: 'Voir la fiche',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(
                                tmdbId: movieId,
                                posterUrl: posterUrl,
                                title: movieTitle,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                if (commentPreview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          const Color(0xFFF8F2EA),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CoffeeColors.creamBorder),
                    ),
                    child: RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$username ',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: CoffeeColors.espresso,
                            ),
                          ),
                          TextSpan(
                            text: commentPreview,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: CoffeeColors.espresso,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildFeedActionPill({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    final iconColor = highlight
        ? CoffeeColors.caramelBronze
        : CoffeeColors.moka;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: highlight
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CoffeeColors.caramelBronze.withValues(alpha: 0.22),
                    CoffeeColors.caramelBronze.withValues(alpha: 0.1),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    const Color(0xFFF3EBDD),
                  ],
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight
                ? CoffeeColors.caramelBronze.withValues(alpha: 0.2)
                : CoffeeColors.creamBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgoDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day}/${date.month}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Future<void> _likeActivity(String? activityId) async {
    if (activityId == null) return;
    try {
      await _apiService.reactToActivity(activityId, 'like');
      _loadData(); // Recharger les donnees
    } catch (e) {
      // Silencieux
    }
  }

  // ============================================================================
  // TAB 2: MATCHS
  // ============================================================================

  Widget _buildMatchesTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_matches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun match pour l\'instant',
        subtitle: 'Likez des films pour matcher avec vos amis!',
      );
    }

    // Grouper les matchs par personne
    final matchesByUser = <String, List<MovieMatch>>{};
    for (final match in _matches) {
      matchesByUser.putIfAbsent(match.matchedWithUsername, () => []).add(match);
    }

    // Filtrer selon le partenaire sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â©
    final filteredMatches = _selectedMatchPartner == null
        ? _matches
        : _matches
              .where((m) => m.matchedWithUsername == _selectedMatchPartner)
              .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Section: Partenaires cinÃƒÆ’Ã‚Â© (filtre cliquable)
          _buildMatchPartnersFilter(matchesByUser),
          const SizedBox(height: 16),

          // Assistant de decision
          if (filteredMatches.isNotEmpty)
            _buildDecisionHelperButton(filteredMatches),
          const SizedBox(height: 20),

          // Titre section
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedMatchPartner == null
                      ? 'Tous vos matchs'
                      : 'Matchs avec $_selectedMatchPartner',
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                  ),
                ),
              ),
              if (_selectedMatchPartner != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedMatchPartner = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredMatches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Aucun match avec cette personne',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(filteredMatches.length, (index) {
              return _buildModernMatchCard(filteredMatches[index], index);
            }),
        ],
      ),
    );
  }

  /// Assistant de decision pour choisir un film de match
  Widget _buildDecisionHelperButton(List<MovieMatch> matches) {
    return GestureDetector(
      onTap: () => _showDecisionHelperSheet(matches),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4A3529),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CoffeeColors.caramelBronze.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aider a se decider',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Duree max, categorie ou full alea',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${matches.length} films',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDecisionHelperSheet(List<MovieMatch> matches) {
    int? selectedMaxDuration;
    String selectedGenre = 'Toutes';
    bool fullRandom = false;
    bool isPicking = false;

    const durationOptions = [90, 110, 130, 150, 180];
    const genreOptions = [
      'Toutes',
      'Action',
      'Aventure',
      'Animation',
      'Comedie',
      'Documentaire',
      'Drame',
      'Fantastique',
      'Horreur',
      'Romance',
      'Science Fiction',
      'Thriller',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Aider a se decider',
                            style: const TextStyle(
                              fontFamily: 'RecoletaAlt',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: CoffeeColors.espresso,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choisis des filtres ou active le mode full alea.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: CoffeeColors.moka,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: CoffeeColors.caramelBronze,
                        title: Text(
                          'Mode full alea',
                          style: const TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                        subtitle: Text(
                          'Ignore les filtres et tire parmi tous les matchs.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: CoffeeColors.moka,
                          ),
                        ),
                        value: fullRandom,
                        onChanged: (value) {
                          setModalState(() {
                            fullRandom = value;
                            if (fullRandom) {
                              selectedMaxDuration = null;
                              selectedGenre = 'Toutes';
                            }
                          });
                        },
                      ),
                      if (!fullRandom) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Duree max',
                          style: const TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildDecisionChip(
                              label: 'Sans limite',
                              isSelected: selectedMaxDuration == null,
                              onTap: () => setModalState(
                                () => selectedMaxDuration = null,
                              ),
                            ),
                            ...durationOptions.map(
                              (duration) => _buildDecisionChip(
                                label: '<= ${duration}min',
                                isSelected: selectedMaxDuration == duration,
                                onTap: () => setModalState(
                                  () => selectedMaxDuration = duration,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Categorie',
                          style: const TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: genreOptions
                              .map(
                                (genre) => _buildDecisionChip(
                                  label: genre,
                                  isSelected: selectedGenre == genre,
                                  onTap: () => setModalState(
                                    () => selectedGenre = genre,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: isPicking
                            ? null
                            : () async {
                                final navigator = Navigator.of(sheetContext);
                                setModalState(() => isPicking = true);
                                final selectedGenreValue =
                                    (!fullRandom && selectedGenre != 'Toutes')
                                    ? selectedGenre
                                    : null;
                                final selectedDurationValue = fullRandom
                                    ? null
                                    : selectedMaxDuration;

                                final result = await _pickMatchForDecision(
                                  matches,
                                  maxDuration: selectedDurationValue,
                                  genre: selectedGenreValue,
                                  fullRandom: fullRandom,
                                );

                                if (!mounted) return;
                                navigator.pop();

                                final picked = result['match'] as MovieMatch?;
                                final candidateCount =
                                    result['pool'] as int? ?? 0;

                                if (picked == null) {
                                  _showNoDecisionResultDialog(
                                    sourceMatches: matches,
                                    maxDuration: selectedDurationValue,
                                    genre: selectedGenreValue,
                                  );
                                  return;
                                }

                                _showDecisionResultDialog(
                                  match: picked,
                                  sourceMatches: matches,
                                  candidateCount: candidateCount,
                                  fullRandom: fullRandom,
                                  maxDuration: selectedDurationValue,
                                  genre: selectedGenreValue,
                                );
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3529),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: isPicking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Lancer la suggestion',
                                    style: TextStyle(
                                      fontFamily: 'RecoletaAlt',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDecisionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? CoffeeColors.caramelBronze
              : CoffeeColors.latteCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CoffeeColors.caramelBronze
                : CoffeeColors.steamMilk.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : CoffeeColors.espresso,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _pickMatchForDecision(
    List<MovieMatch> matches, {
    int? maxDuration,
    String? genre,
    bool fullRandom = false,
  }) async {
    if (matches.isEmpty) {
      return {'match': null, 'pool': 0};
    }

    if (fullRandom || (maxDuration == null && genre == null)) {
      final picked =
          matches[DateTime.now().microsecondsSinceEpoch % matches.length];
      return {'match': picked, 'pool': matches.length};
    }

    final details = await Future.wait<MovieDetail?>(
      matches.map((match) async {
        return _getMatchDetail(match);
      }),
    );

    final candidates = <MovieMatch>[];
    for (var i = 0; i < matches.length; i++) {
      final detail = details[i];
      if (detail == null) continue;

      if (maxDuration != null && detail.runtime > maxDuration) {
        continue;
      }
      if (genre != null && genre.isNotEmpty) {
        if (!_movieHasGenre(detail.genres, genre)) {
          continue;
        }
      }

      candidates.add(matches[i]);
    }

    if (candidates.isEmpty) {
      return {'match': null, 'pool': 0};
    }

    final picked =
        candidates[DateTime.now().microsecondsSinceEpoch % candidates.length];
    return {'match': picked, 'pool': candidates.length};
  }

  Future<MovieDetail?> _getMatchDetail(MovieMatch match) async {
    if (match.movieId <= 0) {
      return null;
    }

    final cached = _matchDetailsCache[match.movieId];
    if (cached != null) {
      return cached;
    }

    try {
      final detail = await _apiService.getMovieDetail(match.movieId);
      if (detail != null) {
        _matchDetailsCache[match.movieId] = detail;
      }
      return detail;
    } catch (_) {
      return null;
    }
  }

  bool _movieHasGenre(List<String> genres, String selectedGenre) {
    final selected = selectedGenre.toLowerCase().replaceAll('-', ' ').trim();
    for (final genre in genres) {
      final current = genre.toLowerCase().replaceAll('-', ' ').trim();
      if (current == selected ||
          current.contains(selected) ||
          selected.contains(current)) {
        return true;
      }
    }
    return false;
  }

  void _showDecisionResultDialog({
    required MovieMatch match,
    required List<MovieMatch> sourceMatches,
    required int candidateCount,
    required bool fullRandom,
    int? maxDuration,
    String? genre,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.shadowLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: CoffeeColors.caramelBronze,
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggestion du moment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CoffeeColors.espresso,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _buildDecisionSummary(
                  fullRandom: fullRandom,
                  maxDuration: maxDuration,
                  genre: genre,
                  candidateCount: candidateCount,
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CoffeeColors.moka,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (match.movieId > 0) {
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          tmdbId: match.movieId,
                          posterUrl: match.hasPoster ? match.moviePoster : null,
                          title: match.movieTitle,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Column(
                      children: [
                        if (match.hasPoster)
                          Image.network(
                            match.moviePoster,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: AppTheme.accentSoft,
                              child: const Center(
                                child: Icon(
                                  Icons.movie_rounded,
                                  size: 48,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          color: AppTheme.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.movieTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Match avec ${match.matchedWithUsername}',
                                style: TextStyle(
                                  fontSize: 13,
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
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showDecisionHelperSheet(sourceMatches);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Refaire',
                            style: TextStyle(
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
                        Navigator.pop(context);
                        _openChat(
                          match.matchedWithUsername,
                          matchMovieId: match.movieId,
                          matchMovieTitle: match.movieTitle,
                          matchMoviePoster: match.hasPoster
                              ? match.moviePoster
                              : null,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3529),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Proposer',
                            style: TextStyle(
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
        ),
      ),
    );
  }

  void _showNoDecisionResultDialog({
    required List<MovieMatch> sourceMatches,
    int? maxDuration,
    String? genre,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun film pour ces filtres'),
        content: Text(
          'Aucun match ne correspond a ${_buildDecisionSummary(fullRandom: false, maxDuration: maxDuration, genre: genre, candidateCount: 0)}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDecisionHelperSheet(sourceMatches);
            },
            child: const Text('Modifier'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final picked =
                  sourceMatches[DateTime.now().microsecondsSinceEpoch %
                      sourceMatches.length];
              _showDecisionResultDialog(
                match: picked,
                sourceMatches: sourceMatches,
                candidateCount: sourceMatches.length,
                fullRandom: true,
              );
            },
            child: const Text('Full alea'),
          ),
        ],
      ),
    );
  }

  String _buildDecisionSummary({
    required bool fullRandom,
    int? maxDuration,
    String? genre,
    required int candidateCount,
  }) {
    if (fullRandom) {
      return 'Mode full alea / $candidateCount film${candidateCount > 1 ? 's' : ''} possible${candidateCount > 1 ? 's' : ''}';
    }

    final filters = <String>[];
    if (maxDuration != null) {
      filters.add('<= $maxDuration min');
    }
    if (genre != null && genre.isNotEmpty) {
      filters.add(genre);
    }

    final criteria = filters.isEmpty ? 'sans filtre' : filters.join(' / ');
    return '$criteria / $candidateCount film${candidateCount > 1 ? 's' : ''}';
  }

  Widget _buildMatchPartnersFilter(
    Map<String, List<MovieMatch>> matchesByUser,
  ) {
    final isAllSelected = _selectedMatchPartner == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vos partenaires cine',
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CoffeeColors.espresso,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matchesByUser.length + 1, // +1 pour le chip "Tous"
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              // Premier chip = "Tous"
              if (index == 0) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedMatchPartner = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAllSelected
                          ? const Color(0xFF4A3529)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: isAllSelected
                          ? null
                          : Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 32,
                          color: isAllSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tous',
                          style: TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isAllSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_matches.length}',
                          style: TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 10,
                            color: isAllSelected
                                ? Colors.white70
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final username = matchesByUser.keys.elementAt(index - 1);
              final matches = matchesByUser[username]!;
              final isSelected = _selectedMatchPartner == username;

              return GestureDetector(
                onTap: () => setState(() => _selectedMatchPartner = username),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A3529)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(color: AppTheme.border),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CoffeeColors.caramelBronze.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            username[0].toUpperCase(),
                            style: GoogleFonts.dmSans(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${matches.length} match${matches.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Carte de match moderne
  Widget _buildModernMatchCard(MovieMatch match, int index) {
    final username = match.matchedWithUsername;
    final movieTitle = match.movieTitle;
    final moviePoster = match.moviePoster;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFF2EBE1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.creamBorder),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openChat(
          username,
          matchMovieId: match.movieId,
          matchMovieTitle: movieTitle,
          matchMoviePoster: match.hasPoster ? moviePoster : null,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Poster du film (tappable -> dÃƒÆ’Ã‚Â©tail)
              GestureDetector(
                onTap: () {
                  if (match.movieId > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(
                          tmdbId: match.movieId,
                          posterUrl: match.hasPoster ? match.moviePoster : null,
                          title: movieTitle,
                        ),
                      ),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: match.hasPoster
                      ? Image.network(
                          moviePoster,
                          width: 60,
                          height: 85,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderPoster(),
                        )
                      : _buildPlaceholderPoster(),
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Match
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3529),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Match!',
                            style: TextStyle(
                              fontFamily: 'RecoletaAlt',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Titre du film
                    Text(
                      movieTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Avec qui
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF5A4335), Color(0xFF3D2C21)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Avec $username',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // FlÃƒÆ’Ã‚Â¨che action
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF564133), Color(0xFF35261D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 60,
      height: 85,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.movie_rounded, color: AppTheme.accent, size: 24),
    );
  }

  // ============================================================================
  // TAB 2: AMIS
  // ============================================================================

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasRequests = _friendRequestsReceived.isNotEmpty;
    final hasSentRequests = _friendRequestsSent.isNotEmpty;
    final hasFriends = _friends.isNotEmpty;
    final isEmpty = !hasRequests && !hasSentRequests && !hasFriends;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          // SECTION: Demandes reÃƒÆ’Ã‚Â§ues (ÃƒÆ’Ã‚Â  accepter)
          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          if (hasRequests) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Demandes recues',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_friendRequestsReceived.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final request = _friendRequestsReceived[index];
                return _buildFriendRequestCard(request);
              }, childCount: _friendRequestsReceived.length),
            ),
          ],

          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          // SECTION: Demandes envoyÃƒÆ’Ã‚Â©es (en attente)
          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          if (hasSentRequests) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CoffeeColors.latteCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: CoffeeColors.moka,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'En attente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CoffeeColors.moka,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_friendRequestsSent.length})',
                      style: TextStyle(
                        fontSize: 14,
                        color: CoffeeColors.steamMilk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final request = _friendRequestsSent[index];
                return _buildPendingRequestCard(request);
              }, childCount: _friendRequestsSent.length),
            ),
          ],

          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          // SECTION: Mes amis confirmÃƒÆ’Ã‚Â©s
          // ÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚ÂÃƒÂ¢Ã¢â‚¬Â¢Ã‚Â
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Mes amis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_friends.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: CoffeeColors.moka,
                    ),
                  ),
                  const Spacer(),
                  // Bouton rechercher
                  GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CoffeeColors.caramelBronze,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste amis ou ÃƒÆ’Ã‚Â©tat vide
          if (isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.people_outline,
                title: 'Aucun ami',
                subtitle: 'Ajoutez des amis pour voir leurs activites!',
                action: TextButton.icon(
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher des amis'),
                ),
              ),
            )
          else if (!hasFriends)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Text(
                  'Acceptez des demandes pour avoir des amis!',
                  style: TextStyle(
                    color: CoffeeColors.moka,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final friend = _friends[index];
                return FriendCard(
                  username: friend.username,
                  bio: friend.bio,
                  totalSeen: friend.totalSeen,
                  level: friend.level,
                  isFriend: true,
                  onTap: () {
                    // Voir profil
                    _openProfile(friend.username);
                  },
                );
              }, childCount: _friends.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // Card pour une demande d'ami reÃƒÆ’Ã‚Â§ue (avec boutons accepter/refuser)
  Widget _buildFriendRequestCard(Friend request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFF6EFE4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5A4335), Color(0xFF3D2C21)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.initial,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CoffeeColors.espresso,
                  ),
                ),
                if (request.hasBio)
                  Text(
                    request.bio!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CoffeeColors.moka,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Boutons Accepter/Refuser
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accepter
              GestureDetector(
                onTap: () => _acceptFriendRequest(request.id),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Refuser
              GestureDetector(
                onTap: () => _declineFriendRequest(request.id),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CoffeeColors.stoneGrey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card pour une demande envoyÃƒÆ’Ã‚Â©e (en attente)
  Widget _buildPendingRequestCard(Friend request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.latteCream, const Color(0xFFEFE5D9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CoffeeColors.moka.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.initial,
                style: GoogleFonts.dmSans(
                  color: CoffeeColors.moka,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CoffeeColors.espresso,
                  ),
                ),
                Text(
                  'En attente de reponse...',
                  style: TextStyle(
                    fontSize: 12,
                    color: CoffeeColors.moka,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // IcÃƒÆ’Ã‚Â´ne hourglass
          Icon(Icons.hourglass_empty, color: CoffeeColors.moka, size: 20),
        ],
      ),
    );
  }

  Future<void> _acceptFriendRequest(String userId) async {
    try {
      await _apiService.acceptFriend(userId);
      _loadData(); // Recharger les donnees
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ami ajoute!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _declineFriendRequest(String userId) async {
    try {
      await _apiService.declineFriend(userId);
      _loadData(); // Recharger les donnees
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // ============================================================================
  // TAB 3: CHAT
  // ============================================================================

  Widget _buildChatTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Aucune conversation',
        subtitle: 'Envoyez un message a vos amis!',
      );
    }

    // Trier : non lus en premier, puis par date
    final sortedConversations = List<Conversation>.from(_conversations);
    sortedConversations.sort((a, b) {
      if (a.hasUnread && !b.hasUnread) return -1;
      if (!a.hasUnread && b.hasUnread) return 1;
      return b.lastMessageDate.compareTo(a.lastMessageDate);
    });

    final totalUnread = sortedConversations.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Header avec rÃƒÆ’Ã‚Â©sumÃƒÆ’Ã‚Â©
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3529),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CoffeeColors.caramelBronze.withValues(
                            alpha: 0.24,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CoffeeColors.espresso,
                          ),
                        ),
                        Text(
                          '${sortedConversations.length} conversation${sortedConversations.length > 1 ? 's' : ''}'
                          '${totalUnread > 0 ? ' / $totalUnread non lu${totalUnread > 1 ? 's' : ''}' : ''}',
                          style: const TextStyle(
                            fontFamily: 'RecoletaAlt',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CoffeeColors.moka,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des conversations
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final conv = sortedConversations[index];

              return _buildConversationCard(
                username: conv.username,
                bio: conv.bio,
                lastMessage: conv.lastMessageContent,
                isSent: conv.lastMessageIsSent,
                timestamp: conv.lastMessageDate,
                unreadCount: conv.unreadCount,
                onTap: () => _openChat(conv.username, userBio: conv.bio),
              );
            }, childCount: sortedConversations.length),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildConversationCard({
    required String username,
    String? bio,
    required String lastMessage,
    required bool isSent,
    required DateTime timestamp,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    final hasUnread = unreadCount > 0;
    final timeText = _formatTimeAgoDate(timestamp);

    // Couleurs d'avatar variÃƒÆ’Ã‚Â©es par username
    final avatarColors = [
      [CoffeeColors.terracotta, CoffeeColors.caramelBronze],
      [const Color(0xFF967468), const Color(0xFF765446)],
      [const Color(0xFF8B6A5E), const Color(0xFF6A4A3F)],
      [const Color(0xFFA28074), const Color(0xFF7E5D51)],
    ];
    final colorIndex = username.hashCode.abs() % avatarColors.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasUnread
                ? [const Color(0xFFF6F0E7), const Color(0xFFEFE2D5)]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xFFF4EDE3),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: hasUnread
                ? AppTheme.accent.withValues(alpha: 0.2)
                : AppTheme.border.withValues(alpha: 0.5),
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : AppTheme.shadowSmall,
        ),
        child: Row(
          children: [
            // Avatar avec gradient
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    avatarColors[colorIndex][0],
                    avatarColors[colorIndex][1],
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColors[colorIndex][0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      // Timestamp
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style:
                              const TextStyle(
                                fontFamily: 'RecoletaAlt',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ).copyWith(
                                color: hasUnread
                                    ? AppTheme.accent
                                    : AppTheme.textTertiary,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isSent)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.done_rounded,
                            size: 14,
                            color: hasUnread
                                ? AppTheme.accent
                                : AppTheme.textTertiary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTheme.bodyMedium.copyWith(
                            color: hasUnread
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Badge non lu ou chevron
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3529),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CoffeeColors.caramelBronze.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: CoffeeColors.steamMilk),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CoffeeColors.moka,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  void _openChat(
    String username, {
    String? userBio,
    int? matchMovieId,
    String? matchMovieTitle,
    String? matchMoviePoster,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          username: username,
          userBio: userBio,
          matchMovieId: matchMovieId,
          matchMovieTitle: matchMovieTitle,
          matchMoviePoster: matchMoviePoster,
        ),
      ),
    );
  }

  void _openProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SearchScreen(usersOnly: true), // Seulement utilisateurs
      ),
    );
  }
}
