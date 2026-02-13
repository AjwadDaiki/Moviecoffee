class Movie {
  final int tmdbId;
  final Title title;
  final Overview overview;
  final String posterPath;
  final List<String> genres;
  final double voteAverage;
  final int runtime;
  final String releaseDate;
  final List<String> actors;
  final List<String> originCountry;

  // Métadonnées personnelles (enrichies par le backend)
  double? userRating;
  String? userComment;
  String? seenDate;
  String? source; // 'match' | 'manual'

  Movie({
    required this.tmdbId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.genres,
    required this.voteAverage,
    required this.runtime,
    this.releaseDate = "",
    this.actors = const [],
    this.originCountry = const [],
    this.userRating,
    this.userComment,
    this.seenDate,
    this.source,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      tmdbId: json['tmdb_id'] ?? 0,
      title: Title.fromJson(json['title'] ?? {}),
      overview: Overview.fromJson(json['overview'] ?? {}),
      posterPath: json['poster_path'] != null && json['poster_path'].toString().isNotEmpty
          ? "https://image.tmdb.org/t/p/w500${json['poster_path']}"
          : "",
      genres: List<String>.from(json['genres'] ?? []),
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      runtime: json['runtime'] ?? 120,
      releaseDate: json['release_date'] ?? "",
      actors: List<String>.from(json['actors'] ?? []),
      originCountry: List<String>.from(json['origin_country'] ?? []),

      // Données perso (présentes uniquement dans /my-list pour les films vus)
      userRating: json['user_rating'] != null ? (json['user_rating'] as num).toDouble() : null,
      userComment: json['user_comment'],
      seenDate: json['seen_date'],
      source: json['source'],
    );
  }

  // Helper pour formater la durée
  String get formattedRuntime {
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0) {
      return "${hours}h${minutes}min";
    }
    return "${minutes}min";
  }

  // Helper pour savoir si le film a été noté
  bool get isRated => userRating != null && userRating! > 0;
}

class Title {
  final String fr;
  final String en;

  Title({required this.fr, this.en = ""});

  factory Title.fromJson(Map<String, dynamic> json) {
    return Title(
      fr: json['fr'] ?? json['en'] ?? "Titre inconnu",
      en: json['en'] ?? json['fr'] ?? "",
    );
  }
}

class Overview {
  final String fr;
  final String en;

  Overview({required this.fr, this.en = ""});

  factory Overview.fromJson(Map<String, dynamic> json) {
    return Overview(
      fr: json['fr'] ?? json['en'] ?? "Aucun résumé disponible.",
      en: json['en'] ?? json['fr'] ?? "",
    );
  }
}
