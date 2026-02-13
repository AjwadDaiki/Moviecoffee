/// Types d'actions du feed social
enum ActivityType {
  rated,
  commented,
  matched,
  addedWatchlist,
  achieved,
  unknown;

  static ActivityType fromString(String? value) {
    switch (value) {
      case 'rated':
        return ActivityType.rated;
      case 'commented':
        return ActivityType.commented;
      case 'matched':
        return ActivityType.matched;
      case 'added_watchlist':
        return ActivityType.addedWatchlist;
      case 'achieved':
        return ActivityType.achieved;
      default:
        return ActivityType.unknown;
    }
  }
}

/// Engagement sur une activité (likes, commentaires)
class ActivityEngagement {
  final int likesCount;
  final int commentsCount;
  final bool userHasLiked;

  const ActivityEngagement({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userHasLiked = false,
  });

  factory ActivityEngagement.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ActivityEngagement();
    return ActivityEngagement(
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      userHasLiked: json['user_has_liked'] as bool? ?? false,
    );
  }

  ActivityEngagement copyWith({int? likesCount, bool? userHasLiked}) {
    return ActivityEngagement(
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      userHasLiked: userHasLiked ?? this.userHasLiked,
    );
  }
}

/// Activité du feed social
class FeedActivity {
  final String id;
  final String userId;
  final String username;
  final ActivityType actionType;
  final int? movieId;
  final String? movieTitle;
  final String? moviePoster;
  final double? rating;
  final String? comment;
  final String? achievementId;
  final String? matchedWith;
  final DateTime createdAt;
  final ActivityEngagement engagement;

  const FeedActivity({
    this.id = '',
    this.userId = '',
    required this.username,
    required this.actionType,
    this.movieId,
    this.movieTitle,
    this.moviePoster,
    this.rating,
    this.comment,
    this.achievementId,
    this.matchedWith,
    required this.createdAt,
    this.engagement = const ActivityEngagement(),
  });

  factory FeedActivity.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final movie = json['movie'] as Map<String, dynamic>?;

    final rawPoster = movie?['poster'] as String? ?? '';
    final poster = rawPoster.isEmpty
        ? null
        : rawPoster.startsWith('http')
        ? rawPoster
        : 'https://image.tmdb.org/t/p/w500$rawPoster';

    return FeedActivity(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      username: user['username'] as String? ?? '',
      actionType: ActivityType.fromString(json['action_type'] as String?),
      movieId: movie?['id'] as int?,
      movieTitle: movie?['title'] as String?,
      moviePoster: poster,
      rating: (json['rating'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      achievementId: json['achievement_id'] as String?,
      matchedWith: json['matched_with'] as String?,
      createdAt: _parseDate(json['created_at']),
      engagement: ActivityEngagement.fromJson(
        json['engagement'] as Map<String, dynamic>?,
      ),
    );
  }

  bool get hasMovie => movieId != null && movieTitle != null;

  bool get hasRating => rating != null && rating! > 0;

  String get initial => username.isNotEmpty ? username[0].toUpperCase() : 'U';

  FeedActivity copyWithEngagement(ActivityEngagement newEngagement) {
    return FeedActivity(
      id: id,
      userId: userId,
      username: username,
      actionType: actionType,
      movieId: movieId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      rating: rating,
      comment: comment,
      achievementId: achievementId,
      matchedWith: matchedWith,
      createdAt: createdAt,
      engagement: newEngagement,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
