import 'translatable_text.dart';

/// Film — modèle principal
class Movie {
  final int tmdbId;
  final TranslatableText title;
  final TranslatableText overview;
  final String posterPath;
  final List<String> genres;
  final double voteAverage;
  final int runtime;
  final String releaseDate;
  final List<String> actors;
  final List<String> originCountry;

  // Métadonnées personnelles (enrichies par le backend)
  final double? userRating;
  final String? userComment;
  final String? seenDate;
  final String? source; // 'match' | 'manual' | 'swipe'
  final String? userAction; // 'like' | 'dislike' | 'seen'
  final String? actionDate;

  const Movie({
    required this.tmdbId,
    required this.title,
    required this.overview,
    required this.posterPath,
    this.genres = const [],
    this.voteAverage = 0.0,
    this.runtime = 0,
    this.releaseDate = '',
    this.actors = const [],
    this.originCountry = const [],
    this.userRating,
    this.userComment,
    this.seenDate,
    this.source,
    this.userAction,
    this.actionDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final rawPoster = json['poster_path'] as String? ?? '';
    final posterPath = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500$rawPoster'
            : '';

    return Movie(
      tmdbId: _toInt(json['tmdb_id'] ?? json['id']),
      title: TranslatableText.fromJson(json['title'] ?? ''),
      overview: TranslatableText.fromJson(json['overview'] ?? ''),
      posterPath: posterPath,
      genres: _toStringList(json['genres']),
      voteAverage: _toDouble(json['vote_average']),
      runtime: _toInt(json['runtime']),
      releaseDate: json['release_date'] as String? ?? '',
      actors: _toStringList(json['actors']),
      originCountry: _toStringList(json['origin_country']),
      userRating: _toNullableDouble(json['user_rating']),
      userComment: json['user_comment'] as String?,
      seenDate: json['seen_date'] as String?,
      source: json['source'] as String?,
      userAction: json['user_action'] as String?,
      actionDate: json['action_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tmdb_id': tmdbId,
        'title': title.toJson(),
        'overview': overview.toJson(),
        'poster_path': posterPath,
        'genres': genres,
        'vote_average': voteAverage,
        'runtime': runtime,
        'release_date': releaseDate,
        'actors': actors,
        'origin_country': originCountry,
        if (userRating != null) 'user_rating': userRating,
        if (userComment != null) 'user_comment': userComment,
        if (seenDate != null) 'seen_date': seenDate,
        if (source != null) 'source': source,
      };

  // === Helpers ===

  String get formattedRuntime {
    if (runtime <= 0) return '';
    final h = runtime ~/ 60;
    final m = runtime % 60;
    if (h > 0 && m > 0) return '${h}h${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  String get year => releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

  bool get isRated => userRating != null && userRating! > 0;

  bool get hasPoster => posterPath.isNotEmpty;

  Movie copyWith({
    double? userRating,
    String? userComment,
    String? seenDate,
    String? source,
  }) {
    return Movie(
      tmdbId: tmdbId,
      title: title,
      overview: overview,
      posterPath: posterPath,
      genres: genres,
      voteAverage: voteAverage,
      runtime: runtime,
      releaseDate: releaseDate,
      actors: actors,
      originCountry: originCountry,
      userRating: userRating ?? this.userRating,
      userComment: userComment ?? this.userComment,
      seenDate: seenDate ?? this.seenDate,
      source: source ?? this.source,
      userAction: userAction,
      actionDate: actionDate,
    );
  }

  // === Type-safe parsers ===

  static int _toInt(dynamic value) => toIntStatic(value);
  static double _toDouble(dynamic value) => toDoubleStatic(value);
  static double? _toNullableDouble(dynamic value) => toNullableDoubleStatic(value);
  static List<String> _toStringList(dynamic value) => toStringListStatic(value);

  /// Parsers publics pour sous-classes (ex: MovieDetail)
  static int toIntStatic(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double toDoubleStatic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? toNullableDoubleStatic(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> toStringListStatic(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Movie && tmdbId == other.tmdbId;

  @override
  int get hashCode => tmdbId.hashCode;
}
