/// Statistiques avancées de l'utilisateur
class AdvancedStats {
  final int totalSeen;
  final int totalLiked;
  final int totalMinutes;
  final double averageRating;
  final double matchPercentage;
  final double collectionCompletionPercent;
  final int weeklyFilms;
  final int weeklyMinutes;
  final int monthlyFilms;
  final int ratedSeenCount;
  final int unratedSeenCount;
  final int commentedSeenCount;
  final List<GenreStats> genreDistribution;
  final FavoriteMovie? favoriteMovie;
  final FavoriteMovie? lastFavoriteMovie;
  final FavoriteInfo? favoriteActor;
  final FavoriteInfo? favoriteCountry;

  const AdvancedStats({
    this.totalSeen = 0,
    this.totalLiked = 0,
    this.totalMinutes = 0,
    this.averageRating = 0.0,
    this.matchPercentage = 0.0,
    this.collectionCompletionPercent = 0.0,
    this.weeklyFilms = 0,
    this.weeklyMinutes = 0,
    this.monthlyFilms = 0,
    this.ratedSeenCount = 0,
    this.unratedSeenCount = 0,
    this.commentedSeenCount = 0,
    this.genreDistribution = const [],
    this.favoriteMovie,
    this.lastFavoriteMovie,
    this.favoriteActor,
    this.favoriteCountry,
  });

  factory AdvancedStats.fromJson(Map<String, dynamic> json) {
    final totalSeen =
        json['total_seen'] as int? ?? json['total_films'] as int? ?? 0;
    final totalMinutes = json['total_minutes'] as int? ?? 0;
    final averageRating =
        (json['average_rating'] as num?)?.toDouble() ??
        (json['avg_rating'] as num?)?.toDouble() ??
        0.0;

    List<GenreStats> genreDistribution =
        (json['genre_distribution'] as List?)
            ?.map((g) => GenreStats.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];

    final periodGenres = (json['top_genres'] as List?) ?? const [];
    if (genreDistribution.isEmpty && periodGenres.isNotEmpty) {
      genreDistribution = periodGenres.map((entry) {
        final genre = entry as Map<String, dynamic>;
        final count = (genre['count'] as num?)?.toInt() ?? 0;
        final percentage = totalSeen > 0 ? (count / totalSeen) * 100 : 0.0;
        return GenreStats(
          genre: genre['genre'] as String? ?? '',
          count: count,
          percentage: percentage,
        );
      }).toList();
    }

    final period = json['period'] as String? ?? '';

    return AdvancedStats(
      totalSeen: totalSeen,
      totalLiked: json['total_liked'] as int? ?? 0,
      totalMinutes: totalMinutes,
      averageRating: averageRating,
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
      collectionCompletionPercent:
          (json['collection_completion_percent'] as num?)?.toDouble() ?? 0.0,
      weeklyFilms:
          json['weekly_films'] as int? ?? (period == 'week' ? totalSeen : 0),
      weeklyMinutes: json['weekly_minutes'] as int? ?? 0,
      monthlyFilms:
          json['monthly_films'] as int? ?? (period == 'month' ? totalSeen : 0),
      ratedSeenCount: json['rated_seen_count'] as int? ?? 0,
      unratedSeenCount: json['unrated_seen_count'] as int? ?? 0,
      commentedSeenCount: json['commented_seen_count'] as int? ?? 0,
      genreDistribution: genreDistribution,
      favoriteMovie: json['favorite_movie'] != null
          ? FavoriteMovie.fromJson(
              json['favorite_movie'] as Map<String, dynamic>,
            )
          : null,
      lastFavoriteMovie: json['last_favorite_movie'] != null
          ? FavoriteMovie.fromJson(
              json['last_favorite_movie'] as Map<String, dynamic>,
            )
          : null,
      favoriteActor: json['favorite_actor'] != null
          ? FavoriteInfo.fromJson(
              json['favorite_actor'] as Map<String, dynamic>,
            )
          : null,
      favoriteCountry: json['favorite_country'] != null
          ? FavoriteInfo.fromJson(
              json['favorite_country'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Distribution d'un genre
class GenreStats {
  final String genre;
  final int count;
  final double percentage;

  const GenreStats({
    required this.genre,
    this.count = 0,
    this.percentage = 0.0,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    return GenreStats(
      genre: json['genre'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Film favori dans les stats
class FavoriteMovie {
  final String title;
  final String posterPath;
  final double userRating;
  final int runtime;
  final List<String> genres;

  const FavoriteMovie({
    this.title = '',
    this.posterPath = '',
    this.userRating = 0.0,
    this.runtime = 0,
    this.genres = const [],
  });

  factory FavoriteMovie.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final title = rawTitle is String
        ? rawTitle
        : rawTitle is Map
        ? (rawTitle['fr'] ?? rawTitle['en'] ?? 'Inconnu') as String
        : 'Inconnu';

    final rawPoster =
        json['poster_path'] as String? ?? json['poster'] as String? ?? '';
    final poster = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$rawPoster'
        : '';

    return FavoriteMovie(
      title: title,
      posterPath: poster,
      userRating:
          (json['user_rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      runtime: json['runtime'] as int? ?? 0,
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
    );
  }

  bool get hasPoster => posterPath.isNotEmpty;

  String get formattedRuntime {
    final hours = runtime ~/ 60;
    final mins = runtime % 60;
    if (hours > 0) return '${hours}h${mins}min';
    return '${runtime}min';
  }
}

/// Info favori (acteur, pays)
class FavoriteInfo {
  final String name;
  final int count;

  const FavoriteInfo({this.name = '', this.count = 0});

  factory FavoriteInfo.fromJson(Map<String, dynamic> json) {
    return FavoriteInfo(
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  bool get isValid => name.isNotEmpty && name != 'Aucun' && name != 'Inconnu';
}
