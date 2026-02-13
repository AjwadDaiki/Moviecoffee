/// Badge de gamification
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int target;
  final int progress;
  final bool unlocked;
  final double percentage;

  const Badge({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'emoji_events',
    this.target = 1,
    this.progress = 0,
    this.unlocked = false,
    this.percentage = 0.0,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      target: json['target'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Progression normalisée [0.0, 1.0]
  double get normalizedProgress => (percentage / 100).clamp(0.0, 1.0);
}

/// Données complètes de gamification
class GamificationData {
  final int xp;
  final int level;
  final int xpNextLevel;
  final int xpCurrentLevel;
  final int streak;
  final int longestStreak;
  final List<Badge> badges;
  final List<String> newUnlocks;
  final int totalBadges;
  final int unlockedBadges;

  const GamificationData({
    this.xp = 0,
    this.level = 1,
    this.xpNextLevel = 100,
    this.xpCurrentLevel = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    this.newUnlocks = const [],
    this.totalBadges = 0,
    this.unlockedBadges = 0,
  });

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    final badgesList = (json['badges'] as List<dynamic>? ?? [])
        .map((b) => Badge.fromJson(b as Map<String, dynamic>))
        .toList();

    final unlocksList = (json['new_unlocks'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return GamificationData(
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      xpNextLevel: json['xp_next_level'] as int? ?? 100,
      xpCurrentLevel: json['xp_current_level'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      badges: badgesList,
      newUnlocks: unlocksList,
      totalBadges: json['total_badges'] as int? ?? badgesList.length,
      unlockedBadges: json['unlocked_badges'] as int? ?? 0,
    );
  }

  /// Progression XP dans le niveau actuel [0.0, 1.0]
  double get levelProgress {
    final range = xpNextLevel - xpCurrentLevel;
    if (range <= 0) return 1.0;
    return ((xp - xpCurrentLevel) / range).clamp(0.0, 1.0);
  }

  bool get hasNewUnlocks => newUnlocks.isNotEmpty;

  List<Badge> get unlockedBadgesList =>
      badges.where((b) => b.unlocked).toList();

  List<Badge> get lockedBadgesList =>
      badges.where((b) => !b.unlocked).toList();
}
