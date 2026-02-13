/// Profil public d'un utilisateur
class PublicProfile {
  final String username;
  final String? bio;
  final bool isFriend;
  final int compatibility;
  final ProfileStats stats;
  final List<CommonMovie> commonMovies;
  final List<RatedMovie> ratedMovies;

  const PublicProfile({
    required this.username,
    this.bio,
    this.isFriend = false,
    this.compatibility = 0,
    this.stats = const ProfileStats(),
    this.commonMovies = const [],
    this.ratedMovies = const [],
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final commonJson = json['common_movies'] as List? ?? [];
    final ratedJson = json['rated_movies'] as List? ?? [];

    return PublicProfile(
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      isFriend: json['is_friend'] as bool? ?? false,
      compatibility: json['compatibility'] as int? ?? 0,
      stats: ProfileStats.fromJson(statsJson),
      commonMovies: commonJson
          .map((m) => CommonMovie.fromJson(m as Map<String, dynamic>))
          .toList(),
      ratedMovies: ratedJson
          .map((m) => RatedMovie.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasBio => bio != null && bio!.isNotEmpty;
}

/// Stats du profil public
class ProfileStats {
  final int totalSeen;
  final double averageRating;
  final int level;
  final List<String> topGenres;

  const ProfileStats({
    this.totalSeen = 0,
    this.averageRating = 0.0,
    this.level = 1,
    this.topGenres = const [],
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalSeen: json['total_seen'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as int? ?? 1,
      topGenres: (json['top_genres'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Film en commun (aperçu léger)
class CommonMovie {
  final int? tmdbId;
  final String? title;
  final String poster;

  const CommonMovie({this.tmdbId, this.title, this.poster = ''});

  factory CommonMovie.fromJson(Map<String, dynamic> json) {
    final rawPoster = json['poster'] as String? ?? '';
    final poster = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500$rawPoster'
            : '';

    return CommonMovie(
      tmdbId: json['tmdb_id'] as int? ?? json['id'] as int?,
      title: json['title'] as String?,
      poster: poster,
    );
  }

  bool get hasPoster => poster.isNotEmpty;
}

/// Film noté avec commentaire
class RatedMovie {
  final int? tmdbId;
  final String title;
  final String poster;
  final double rating;
  final String comment;
  final String date;

  const RatedMovie({
    this.tmdbId,
    this.title = '',
    this.poster = '',
    this.rating = 0,
    this.comment = '',
    this.date = '',
  });

  factory RatedMovie.fromJson(Map<String, dynamic> json) {
    final rawPoster = json['poster'] as String? ?? '';
    final poster = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500$rawPoster'
            : '';

    return RatedMovie(
      tmdbId: json['tmdb_id'] as int?,
      title: json['title'] as String? ?? '',
      poster: poster,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  bool get hasComment => comment.isNotEmpty;
  bool get hasPoster => poster.isNotEmpty;
}
