import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/coffee_colors.dart';
import '../theme/app_theme.dart';
import '../services/app_i18n.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    const Duration(seconds: 20),
    (tick) => tick,
  );
  late final StreamSubscription<int> _refreshSubscription;
  bool _isRefreshing = false;
  bool _appIsActive = true;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();

    // Auto-refresh: uniquement quand l'ecran est visible et l'app active
    _refreshSubscription = _refreshTimer.listen((_) {
      final routeIsCurrent = mounted
          ? (ModalRoute.of(context)?.isCurrent ?? true)
          : false;
      if (mounted &&
          routeIsCurrent &&
          _appIsActive &&
          !_isRefreshing &&
          !_isLoading) {
        _silentRefresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      _refreshTick++;
      final fullRefresh = _refreshTick % 4 == 0;
      final activeTab = _tabController.index;

      if (fullRefresh) {
        await _refreshAllSections();
      } else if (activeTab == 0) {
        await _refreshFeedSection();
      } else if (activeTab == 1) {
        await _refreshMatchesSection();
      } else if (activeTab == 2) {
        await _refreshFriendsSection();
      } else {
        await _refreshChatSection();
      }
    } catch (_) {
      // Silencieux
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _refreshAllSections() async {
    final results = await Future.wait<dynamic>([
      _apiService.getMatches(limit: 20).catchError((_) => <MovieMatch>[]),
      _apiService.getFriendsList().catchError((_) => null),
      _apiService
          .getConversations(limit: 20)
          .catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
      _apiService
          .getSocialFeed(page: 1, limit: 24)
          .catchError((_) => <FeedActivity>[]),
    ]);

    if (!mounted) return;
    setState(() {
      _matches = results[0] as List<MovieMatch>;
      final friendsData = results[1] as FriendsData?;
      if (friendsData != null) {
        _friends = friendsData.friends;
        _friendRequestsReceived = friendsData.requestsReceived;
        _friendRequestsSent = friendsData.requestsSent;
      }
      _conversations = results[2] as List<Conversation>;
      _unviewedMatchesCount = results[3] as int;
      _feedActivities = results[4] as List<FeedActivity>;
    });
  }

  Future<void> _refreshFeedSection() async {
    final results = await Future.wait<dynamic>([
      _apiService
          .getSocialFeed(page: 1, limit: 24)
          .catchError((_) => <FeedActivity>[]),
      _apiService
          .getConversations(limit: 12)
          .catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
    ]);
    if (!mounted) return;
    setState(() {
      _feedActivities = results[0] as List<FeedActivity>;
      _conversations = results[1] as List<Conversation>;
      _unviewedMatchesCount = results[2] as int;
    });
  }

  Future<void> _refreshMatchesSection() async {
    final results = await Future.wait<dynamic>([
      _apiService.getMatches(limit: 20).catchError((_) => <MovieMatch>[]),
      _apiService
          .getConversations(limit: 12)
          .catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
    ]);
    if (!mounted) return;
    setState(() {
      _matches = results[0] as List<MovieMatch>;
      _conversations = results[1] as List<Conversation>;
      _unviewedMatchesCount = results[2] as int;
    });
  }

  Future<void> _refreshFriendsSection() async {
    final results = await Future.wait<dynamic>([
      _apiService.getFriendsList().catchError((_) => null),
      _apiService
          .getConversations(limit: 12)
          .catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
    ]);
    if (!mounted) return;
    setState(() {
      final friendsData = results[0] as FriendsData?;
      if (friendsData != null) {
        _friends = friendsData.friends;
        _friendRequestsReceived = friendsData.requestsReceived;
        _friendRequestsSent = friendsData.requestsSent;
      }
      _conversations = results[1] as List<Conversation>;
      _unviewedMatchesCount = results[2] as int;
    });
  }

  Future<void> _refreshChatSection() async {
    final results = await Future.wait<dynamic>([
      _apiService
          .getConversations(limit: 20)
          .catchError((_) => <Conversation>[]),
      _apiService.getUnviewedMatchesCount().catchError((_) => 0),
    ]);
    if (!mounted) return;
    setState(() {
      _conversations = results[0] as List<Conversation>;
      _unviewedMatchesCount = results[1] as int;
    });
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
          // Titre avec style unifiÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppI18n.t('community.title', fallback: 'Communaute'),
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
    final unreadMessages = _conversations.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTabChip(
            0,
            Icons.dynamic_feed_rounded,
            AppI18n.t('community.tab.feed', fallback: 'Feed'),
            _feedActivities.length,
          ),
          const SizedBox(width: 10),
          _buildTabChip(
            1,
            Icons.favorite_rounded,
            AppI18n.t('community.tab.matches', fallback: 'Matchs'),
            _matches.length,
          ),
          const SizedBox(width: 10),
          _buildTabChip(
            2,
            Icons.people_rounded,
            AppI18n.t('community.tab.friends', fallback: 'Amis'),
            _friends.length,
          ),
          const SizedBox(width: 10),
          _buildTabChip(
            3,
            Icons.chat_bubble_rounded,
            AppI18n.t('community.tab.messages', fallback: 'Messages'),
            _conversations.length,
            unreadIndicatorCount: unreadMessages,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(
    int index,
    IconData icon,
    String label,
    int count, {
    int unreadIndicatorCount = 0,
  }) {
    final isActive = _tabController.index == index;
    final showUnreadIndicator = unreadIndicatorCount > 0;

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
            if (showUnreadIndicator) ...[
              const SizedBox(width: 5),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
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

  Widget _buildAnimatedListEntry({required int index, required Widget child}) {
    final capped = index > 6 ? 6 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 220 + (capped * 55)),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, contentValue, content) {
        return Opacity(
          opacity: contentValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - contentValue) * 16),
            child: content,
          ),
        );
      },
    );
  }

  String _formatDecisionDurationLabel(int minutes) {
    return _formatDecisionDurationCompact(minutes);
  }

  String _formatDecisionDurationCompact(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$minutes min';
    if (mins == 0) return '${hours}h';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
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
        title: AppI18n.t(
          'community.empty_activity_title',
          fallback: 'Aucune activite',
        ),
        subtitle: AppI18n.t(
          'community.empty_activity_subtitle',
          fallback: 'Suivez des amis pour voir leur activite.',
        ),
        action: TextButton.icon(
          onPressed: _openSearch,
          icon: Icon(Icons.person_add, color: AppTheme.accent),
          label: Text(
            AppI18n.t('community.add_friends', fallback: 'Ajouter des amis'),
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
      );
    }

    final sourceActivities = _buildFeedSourceActivities();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          _buildNewsHeader(allActivities: sourceActivities),
          if (sourceActivities.isEmpty)
            _buildFilteredFeedEmptyState()
          else
            ..._buildFeedTimeline(sourceActivities),
        ],
      ),
    );
  }

  List<FeedActivity> _buildFeedSourceActivities() {
    final activities = _feedActivities.where((activity) {
      return activity.actionType == ActivityType.rated ||
          activity.actionType == ActivityType.commented ||
          activity.actionType == ActivityType.addedWatchlist;
    }).toList();
    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activities;
  }

  Widget _buildNewsHeader({required List<FeedActivity> allActivities}) {
    final now = DateTime.now();
    final recent24h = allActivities
        .where((activity) => now.difference(activity.createdAt).inHours < 24)
        .length;
    final activeUsers =
        allActivities
            .map((a) => a.username.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visibleUsers = activeUsers.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CoffeeColors.creamBorder),
          boxShadow: [
            BoxShadow(
              color: CoffeeColors.espresso.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppI18n.t(
                          'community.news_title',
                          fallback: 'Fil d actualite',
                        ),
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CoffeeColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppI18n.t(
                          'community.news_subtitle',
                          fallback:
                              'Les derniers films vus, notes et commentaires de vos amis.',
                        ),
                        style: TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CoffeeColors.moka,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3529).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF4A3529),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFeedStatPill(
                  icon: Icons.flash_on_rounded,
                  label:
                      '$recent24h ${AppI18n.t('community.recent_count', fallback: 'recents')}',
                ),
                const SizedBox(width: 8),
                _buildFeedStatPill(
                  icon: Icons.people_rounded,
                  label:
                      '${activeUsers.length} ${AppI18n.t('community.active_count', fallback: 'actifs')}',
                ),
              ],
            ),
            if (visibleUsers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleUsers.map((username) {
                  return _buildFeedFriendPill(username);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedStatPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5ECE2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4A3529)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedFriendPill(String username) {
    final palette = <Color>[
      const Color(0xFF7D5C4A),
      const Color(0xFF6A4D3E),
      const Color(0xFF8B6954),
      const Color(0xFF5E4438),
    ];
    final avatarColor = palette[username.hashCode.abs() % palette.length];

    return GestureDetector(
      onTap: () => _openProfile(username),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CoffeeColors.creamBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: avatarColor,
              child: Text(
                username[0].toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              username,
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedTimeline(List<FeedActivity> activities) {
    final widgets = <Widget>[];
    DateTime? lastDay;

    for (var i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final activityDay = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );

      if (lastDay == null || !_isSameDay(lastDay, activityDay)) {
        widgets.add(_buildTimelineDayDivider(activityDay));
        lastDay = activityDay;
      }

      widgets.add(
        _buildAnimatedListEntry(index: i, child: _buildFeedCard(activity)),
      );
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

    if (_isSameDay(day, today)) {
      return AppI18n.t('community.today', fallback: 'Aujourd hui');
    }
    if (_isSameDay(day, yesterday)) {
      return AppI18n.t('community.yesterday', fallback: 'Hier');
    }
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
            AppI18n.t(
              'community.no_recent_activity',
              fallback: 'Aucune activite recente',
            ),
            style: const TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppI18n.t(
              'community.no_recent_activity_subtitle',
              fallback:
                  'Le fil se remplit quand vos amis notent, commentent ou marquent des films vus.',
            ),
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
            child: Text(
              AppI18n.t(
                'community.refresh_feed',
                fallback: 'Actualiser le fil',
              ),
            ),
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
    final activityLabel = _activityLabel(activity);
    final hasRating = rating != null && rating > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CoffeeColors.creamBorder.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(username),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A4335),
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
                      const SizedBox(height: 2),
                      Text(
                        '$activityLabel - $timeAgo',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: CoffeeColors.moka,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F1E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CoffeeColors.creamBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: posterUrl == null
                          ? Container(
                              width: 92,
                              height: 132,
                              color: const Color(0xFFF1E7DD),
                              child: const Center(
                                child: Icon(
                                  Icons.movie_rounded,
                                  size: 38,
                                  color: CoffeeColors.moka,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: posterUrl,
                              width: 92,
                              height: 132,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              fadeInDuration: const Duration(milliseconds: 120),
                              placeholder: (_, __) => Container(
                                width: 92,
                                height: 132,
                                color: const Color(0xFFF1E7DD),
                                child: const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: CoffeeColors.moka,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 92,
                                height: 132,
                                color: const Color(0xFFF1E7DD),
                                child: const Center(
                                  child: Icon(
                                    Icons.movie_rounded,
                                    size: 38,
                                    color: CoffeeColors.moka,
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
                          Text(
                            movieTitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: CoffeeColors.espresso,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasRating) ...[
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  final starValue = i + 1;
                                  return Icon(
                                    starValue <= rating
                                        ? Icons.star_rounded
                                        : starValue - 0.5 <= rating
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: const Color(0xFFB7793D),
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${rating.toStringAsFixed(1)}/5',
                                  style: const TextStyle(
                                    fontFamily: 'RecoletaAlt',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: CoffeeColors.espresso,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (commentPreview.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(
                              '"$commentPreview"',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: CoffeeColors.moka,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFeedActionChip(
                  icon: hasLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _formatCount(engagement.likesCount),
                  highlight: hasLiked,
                  onTap: () => _likeActivity(activity.id),
                ),
                const SizedBox(width: 8),
                _buildFeedActionChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _formatCount(engagement.commentsCount),
                  onTap: () => _commentOnActivity(activity.id),
                ),
                const Spacer(),
                if (movieId > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A3529),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
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
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text(
                      'Voir la fiche',
                      style: TextStyle(
                        fontFamily: 'RecoletaAlt',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _activityLabel(FeedActivity activity) {
    if (activity.actionType == ActivityType.commented) return 'a commente';
    if (activity.actionType == ActivityType.addedWatchlist) {
      return 'a ajoute a sa watchlist';
    }
    if (activity.actionType == ActivityType.rated &&
        (activity.rating ?? 0) > 0) {
      return 'a note';
    }
    return 'a vu';
  }

  Widget _buildFeedActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF4A3529).withValues(alpha: 0.14)
              : const Color(0xFFF3EAE0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: highlight ? const Color(0xFF4A3529) : CoffeeColors.moka,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight ? const Color(0xFF4A3529) : CoffeeColors.moka,
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
    final index = _feedActivities.indexWhere((a) => a.id == activityId);
    ActivityEngagement? previous;
    if (index != -1) {
      final activity = _feedActivities[index];
      previous = activity.engagement;
      final hasLiked = activity.engagement.userHasLiked;
      final likesCount = activity.engagement.likesCount + (hasLiked ? -1 : 1);
      final updated = activity.copyWithEngagement(
        activity.engagement.copyWith(
          likesCount: likesCount < 0 ? 0 : likesCount,
          userHasLiked: !hasLiked,
        ),
      );
      setState(() {
        _feedActivities[index] = updated;
      });
    }

    try {
      await _apiService.reactToActivity(activityId, 'like');
    } catch (e) {
      if (index != -1 && previous != null && mounted) {
        final original = _feedActivities[index].copyWithEngagement(previous);
        setState(() {
          _feedActivities[index] = original;
        });
      }
    }
  }

  Future<void> _commentOnActivity(String? activityId) async {
    if (activityId == null || !mounted) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Reagir',
          style: TextStyle(
            fontFamily: 'RecoletaAlt',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Votre commentaire...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    final commentText = (text ?? '').trim();
    if (commentText.isEmpty) return;

    final index = _feedActivities.indexWhere((a) => a.id == activityId);
    ActivityEngagement? previous;
    if (index != -1) {
      previous = _feedActivities[index].engagement;
      final updated = _feedActivities[index].copyWithEngagement(
        _feedActivities[index].engagement.copyWith(
          commentsCount: _feedActivities[index].engagement.commentsCount + 1,
        ),
      );
      setState(() {
        _feedActivities[index] = updated;
      });
    }

    try {
      await _apiService.reactToActivity(
        activityId,
        'comment',
        commentText: commentText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commentaire ajoute')));
    } catch (e) {
      final previousEngagement = previous;
      if (index != -1 && previousEngagement != null && mounted) {
        setState(() {
          _feedActivities[index] = _feedActivities[index].copyWithEngagement(
            previousEngagement,
          );
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d envoyer le commentaire: $e')),
        );
      }
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
        title: AppI18n.t(
          'community.empty_matches_title',
          fallback: 'Aucun match pour l\'instant',
        ),
        subtitle: AppI18n.t(
          'community.empty_matches_subtitle',
          fallback: 'Likez des films pour matcher avec vos amis!',
        ),
      );
    }

    // Grouper les matchs par personne
    final matchesByUser = <String, List<MovieMatch>>{};
    for (final match in _matches) {
      matchesByUser.putIfAbsent(match.matchedWithUsername, () => []).add(match);
    }

    // Filtrer selon le partenaire sÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©lectionnÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©
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
          // Section: Partenaires cinÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â© (filtre cliquable)
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
              return _buildAnimatedListEntry(
                index: index,
                child: _buildModernMatchCard(filteredMatches[index], index),
              );
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
                    'Filtrer par duree et genre, ou lancer en full alea',
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
    _primeDecisionCache(matches);

    int? selectedDurationValue;
    bool durationIsMax = true;
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
      'Science-fiction',
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
                        'Choisis un type de duree (min ou max), un genre, ou active le mode full alea.',
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
                          'Ignore les filtres et pioche parmi tous vos matchs.',
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
                              selectedDurationValue = null;
                              durationIsMax = true;
                              selectedGenre = 'Toutes';
                            }
                          });
                        },
                      ),
                      if (!fullRandom) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Duree',
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
                              label: 'Maximum',
                              isSelected: durationIsMax,
                              onTap: () =>
                                  setModalState(() => durationIsMax = true),
                            ),
                            _buildDecisionChip(
                              label: 'Minimum',
                              isSelected: !durationIsMax,
                              onTap: () =>
                                  setModalState(() => durationIsMax = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildDecisionChip(
                              label: 'Sans filtre',
                              isSelected: selectedDurationValue == null,
                              onTap: () => setModalState(
                                () => selectedDurationValue = null,
                              ),
                            ),
                            ...durationOptions.map(
                              (duration) => _buildDecisionChip(
                                label: _formatDecisionDurationLabel(duration),
                                isSelected: selectedDurationValue == duration,
                                onTap: () => setModalState(
                                  () => selectedDurationValue = duration,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (selectedDurationValue != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            durationIsMax
                                ? 'Garde les films jusqu\'a ${_formatDecisionDurationCompact(selectedDurationValue!)}'
                                : 'Garde les films a partir de ${_formatDecisionDurationCompact(selectedDurationValue!)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: CoffeeColors.moka,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                                final selectedMinDuration =
                                    fullRandom ||
                                        selectedDurationValue == null ||
                                        durationIsMax
                                    ? null
                                    : selectedDurationValue;
                                final selectedMaxDuration =
                                    fullRandom ||
                                        selectedDurationValue == null ||
                                        !durationIsMax
                                    ? null
                                    : selectedDurationValue;

                                final result = await _pickMatchForDecision(
                                  matches,
                                  minDuration: selectedMinDuration,
                                  maxDuration: selectedMaxDuration,
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
                                    minDuration: selectedMinDuration,
                                    maxDuration: selectedMaxDuration,
                                    genre: selectedGenreValue,
                                  );
                                  return;
                                }

                                _showDecisionResultDialog(
                                  match: picked,
                                  sourceMatches: matches,
                                  candidateCount: candidateCount,
                                  fullRandom: fullRandom,
                                  minDuration: selectedMinDuration,
                                  maxDuration: selectedMaxDuration,
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
                                    'Trouver un film',
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

  void _primeDecisionCache(List<MovieMatch> matches) {
    final warmup = matches
        .where(
          (m) => m.movieId > 0 && !_matchDetailsCache.containsKey(m.movieId),
        )
        .take(14)
        .toList();
    if (warmup.isEmpty) return;
    unawaited(Future.wait(warmup.map(_getMatchDetail)));
  }

  Widget _buildDecisionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
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
    int? minDuration,
    int? maxDuration,
    String? genre,
    bool fullRandom = false,
  }) async {
    if (matches.isEmpty) {
      return {'match': null, 'pool': 0};
    }

    if (fullRandom ||
        (minDuration == null && maxDuration == null && genre == null)) {
      final picked =
          matches[DateTime.now().microsecondsSinceEpoch % matches.length];
      return {'match': picked, 'pool': matches.length};
    }

    const maxInspected = 40;
    final total = matches.length;
    final inspectCount = total <= maxInspected ? total : maxInspected;
    final start = DateTime.now().microsecondsSinceEpoch % total;

    Future<List<MovieMatch>> collectCandidates(List<MovieMatch> pool) async {
      final details = await Future.wait<MovieDetail?>(
        pool.map((match) async => _getMatchDetail(match)),
      );
      final result = <MovieMatch>[];
      for (var i = 0; i < pool.length; i++) {
        final detail = details[i];
        if (detail == null) continue;
        if (minDuration != null && detail.runtime < minDuration) {
          continue;
        }
        if (maxDuration != null && detail.runtime > maxDuration) {
          continue;
        }
        if (genre != null &&
            genre.isNotEmpty &&
            !_movieHasGenre(detail.genres, genre)) {
          continue;
        }
        result.add(pool[i]);
      }
      return result;
    }

    final inspected = List<MovieMatch>.generate(
      inspectCount,
      (i) => matches[(start + i) % total],
    );
    final candidates = await collectCandidates(inspected);
    if (candidates.isEmpty && inspectCount < total) {
      final remaining = List<MovieMatch>.generate(
        total - inspectCount,
        (i) => matches[(start + inspectCount + i) % total],
      );
      candidates.addAll(await collectCandidates(remaining));
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
    int? minDuration,
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
                  minDuration: minDuration,
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
    int? minDuration,
    int? maxDuration,
    String? genre,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun film avec ces filtres'),
        content: Text(
          'Aucun match ne correspond a ${_buildDecisionSummary(fullRandom: false, minDuration: minDuration, maxDuration: maxDuration, genre: genre, candidateCount: 0)}.',
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
            child: const Text('Mode full alea'),
          ),
        ],
      ),
    );
  }

  String _buildDecisionSummary({
    required bool fullRandom,
    int? minDuration,
    int? maxDuration,
    String? genre,
    required int candidateCount,
  }) {
    if (fullRandom) {
      return 'mode full alea (${candidateCount} film${candidateCount > 1 ? 's' : ''})';
    }

    final filters = <String>[];
    if (minDuration != null) {
      filters.add('duree min ${_formatDecisionDurationCompact(minDuration)}');
    }
    if (maxDuration != null) {
      filters.add('duree max ${_formatDecisionDurationCompact(maxDuration)}');
    }
    if (genre != null && genre.isNotEmpty) {
      filters.add('genre $genre');
    }

    final criteria = filters.isEmpty ? 'sans filtre' : filters.join(' | ');
    return '$criteria (${candidateCount} film${candidateCount > 1 ? 's' : ''})';
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
              // Poster du film (tappable -> dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©tail)
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

              // FlÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¨che action
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
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
          // SECTION: Demandes reÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ues (ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â  accepter)
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
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

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
          // SECTION: Demandes envoyÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©es (en attente)
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
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

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
          // SECTION: Mes amis confirmÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©s
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢Ãƒâ€šÃ‚Â
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

          // Liste amis ou ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©tat vide
          if (isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.people_outline,
                title: AppI18n.t(
                  'community.empty_friends_title',
                  fallback: 'Aucun ami',
                ),
                subtitle: AppI18n.t(
                  'community.empty_friends_subtitle',
                  fallback: 'Ajoutez des amis pour voir leurs activites.',
                ),
                action: TextButton.icon(
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                  label: Text(
                    AppI18n.t(
                      'community.search_friends',
                      fallback: 'Rechercher des amis',
                    ),
                  ),
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

  // Card pour une demande d'ami reÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ue (avec boutons accepter/refuser)
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

  // Card pour une demande envoyÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©e (en attente)
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
          // IcÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â´ne hourglass
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
      if (_friends.isNotEmpty) {
        return _buildStartConversationList();
      }
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: AppI18n.t(
          'community.empty_messages_title',
          fallback: 'Aucune conversation',
        ),
        subtitle: AppI18n.t(
          'community.empty_messages_subtitle',
          fallback: 'Envoyez un message a vos amis.',
        ),
        action: GestureDetector(
          onTap: _loadData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A3529),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppI18n.t('action.refresh', fallback: 'Actualiser'),
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
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
          // Header avec rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©sumÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©
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

              return _buildAnimatedListEntry(
                index: index,
                child: _buildConversationCard(
                  username: conv.username,
                  bio: conv.bio,
                  lastMessage: conv.lastMessageContent,
                  isSent: conv.lastMessageIsSent,
                  timestamp: conv.lastMessageDate,
                  unreadCount: conv.unreadCount,
                  onTap: () => _openChat(conv.username, userBio: conv.bio),
                ),
              );
            }, childCount: sortedConversations.length),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildStartConversationList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
        children: [
          const Text(
            'Demarrer une conversation',
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Vous n'avez pas encore de fil actif. Ecrivez a un ami pour lancer le chat.",
            style: TextStyle(
              fontFamily: 'RecoletaAlt',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CoffeeColors.moka,
            ),
          ),
          const SizedBox(height: 16),
          ..._friends.map(_buildStartConversationTile),
        ],
      ),
    );
  }

  Widget _buildStartConversationTile(Friend friend) {
    return GestureDetector(
      onTap: () => _openChat(friend.username, userBio: friend.bio),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4A3529),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friend.initial,
                  style: const TextStyle(
                    fontFamily: 'RecoletaAlt',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                    friend.username,
                    style: const TextStyle(
                      fontFamily: 'RecoletaAlt',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                  if (friend.hasBio)
                    Text(
                      friend.bio!,
                      style: const TextStyle(
                        fontFamily: 'RecoletaAlt',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CoffeeColors.moka,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: CoffeeColors.terracotta,
            ),
          ],
        ),
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

    // Couleurs d'avatar variÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©es par username
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
          color: hasUnread ? const Color(0xFFF6F0E7) : AppTheme.surface,
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontFamily: 'RecoletaAlt',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
