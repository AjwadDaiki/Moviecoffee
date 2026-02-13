import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// =============================================================================
/// GAMIFICATION SCREEN - Badges, XP, Niveau, Streak
/// =============================================================================

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final _apiService = ApiService();
  GamificationData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getGamification();
      if (result != null && mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Gamification error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Map string icon name to IconData
  IconData _iconFromString(String name) {
    switch (name) {
      case 'movie': return Icons.movie_rounded;
      case 'local_movies': return Icons.local_movies_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'workspace_premium': return Icons.workspace_premium_rounded;
      case 'rate_review': return Icons.rate_review_rounded;
      case 'people': return Icons.people_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'explore': return Icons.explore_rounded;
      case 'wb_sunny': return Icons.wb_sunny_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'chat_bubble': return Icons.chat_bubble_rounded;
      case 'bookmark': return Icons.bookmark_rounded;
      default: return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Progression', style: AppTheme.titleMedium),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _data == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.accent,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text('Erreur de chargement', style: AppTheme.titleMedium),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Réessayer', style: AppTheme.labelLarge.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // === LEVEL & XP CARD ===
        _buildLevelCard(d.level, d.xp, d.xpNextLevel, d.xpCurrentLevel, d.levelProgress),

        const SizedBox(height: 16),

        // === STREAK CARD ===
        _buildStreakCard(d.streak, d.longestStreak),

        const SizedBox(height: 24),

        // === NEW UNLOCKS ===
        if (d.hasNewUnlocks) ...[
          _buildNewUnlocks(d.newUnlocks, d.badges),
          const SizedBox(height: 24),
        ],

        // === BADGES SECTION ===
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Badges', style: AppTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${d.unlockedBadges} / ${d.totalBadges}',
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'RecoletaAlt',
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Badge grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: d.badges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(d.badges[index]);
            },
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // ===========================================================================
  // LEVEL CARD
  // ===========================================================================

  Widget _buildLevelCard(int level, int xp, int xpNext, int xpCurrent, double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, AppTheme.accentDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.shadowAccent(AppTheme.accent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$level',
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'LVL',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _levelTitle(level),
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp XP',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // XP progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prochain niveau',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '$xp / $xpNext XP',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _levelTitle(int level) {
    switch (level) {
      case 1: return 'Spectateur';
      case 2: return 'Cinéphile';
      case 3: return 'Passionné';
      case 4: return 'Connaisseur';
      case 5: return 'Expert';
      case 6: return 'Virtuose';
      case 7: return 'Maître';
      case 8: return 'Légende';
      case 9: return 'Mythique';
      case 10: return 'Divin';
      default: return 'Novice';
    }
  }

  // ===========================================================================
  // STREAK CARD
  // ===========================================================================

  Widget _buildStreakCard(int streak, int longestStreak) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard(radius: 18),
      child: Row(
        children: [
          // Flame icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: streak > 0
                    ? [Colors.orange.shade400, Colors.red.shade400]
                    : [AppTheme.textTertiary, AppTheme.textTertiary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: streak > 0
                  ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0 ? '$streak jour${streak > 1 ? 's' : ''} de suite' : 'Pas de streak',
                  style: AppTheme.labelLarge,
                ),
                Text(
                  'Record : $longestStreak jour${longestStreak > 1 ? 's' : ''}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          // Streak flames
          if (streak > 0)
            Row(
              children: List.generate(
                streak.clamp(0, 5),
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: Colors.orange.shade400.withValues(alpha: 0.5 + (i * 0.1)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NEW UNLOCKS
  // ===========================================================================

  Widget _buildNewUnlocks(List<String> newUnlocks, List<Badge> badges) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration_rounded, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                'Nouveau${newUnlocks.length > 1 ? 'x' : ''} badge${newUnlocks.length > 1 ? 's' : ''} débloqué${newUnlocks.length > 1 ? 's' : ''} !',
                style: AppTheme.labelLarge.copyWith(color: Colors.amber.shade800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: newUnlocks.map((id) {
              final badge = badges.cast<Badge?>().firstWhere(
                (b) => b!.id == id,
                orElse: () => null,
              );
              return Chip(
                avatar: Icon(_iconFromString(badge?.icon ?? ''), size: 16),
                label: Text(badge?.name ?? id, style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
                backgroundColor: Colors.amber.shade200,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BADGE CARD
  // ===========================================================================

  Widget _buildBadgeCard(Badge badge) {
    final isUnlocked = badge.unlocked;
    final percentage = badge.percentage;
    final icon = _iconFromString(badge.icon);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? AppTheme.accentSoft : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.accent.withValues(alpha: 0.3)
              : AppTheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : AppTheme.shadowSmall,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark])
                  : null,
              color: isUnlocked ? null : AppTheme.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isUnlocked
                  ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Icon(
              icon,
              size: 22,
              color: isUnlocked ? Colors.white : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Progress bar
          if (!isUnlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 4,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${badge.progress}/${badge.target}',
              style: GoogleFonts.dmSans(fontSize: 9, color: AppTheme.textTertiary),
            ),
          ] else
            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.accent),
        ],
      ),
    );
  }
}
