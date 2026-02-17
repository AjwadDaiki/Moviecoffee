import 'movie.dart';
import 'translatable_text.dart';

/// Membre du casting
class CastMember {
  final String name;
  final String character;
  final String? profilePath;
  final int order;

  const CastMember({
    required this.name,
    this.character = '',
    this.profilePath,
    this.order = 0,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] as String? ?? '',
      character: json['character'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  bool get hasPhoto => profilePath != null && profilePath!.isNotEmpty;
}

/// Réalisateur
class Director {
  final String name;
  final String? profilePath;

  const Director({required this.name, this.profilePath});

  factory Director.fromJson(Map<String, dynamic> json) {
    return Director(
      name: json['name'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
    );
  }
}

/// Bande-annonce
class Trailer {
  final String key;
  final String name;
  final String url;

  const Trailer({required this.key, this.name = '', this.url = ''});

  factory Trailer.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    return Trailer(
      key: key,
      name: json['name'] as String? ?? '',
      url:
          json['url'] as String? ??
          (key.isNotEmpty ? 'https://www.youtube.com/watch?v=$key' : ''),
    );
  }

  bool get isValid => key.isNotEmpty;
}

/// Plateforme de streaming
class StreamingProvider {
  final String name;
  final String logo;

  const StreamingProvider({required this.name, this.logo = ''});

  factory StreamingProvider.fromJson(Map<String, dynamic> json) {
    return StreamingProvider(
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
    );
  }
}

/// Disponibilité streaming par type
class ProvidersData {
  final List<StreamingProvider> flatrate;
  final List<StreamingProvider> rent;
  final List<StreamingProvider> buy;
  final String? link;

  const ProvidersData({
    this.flatrate = const [],
    this.rent = const [],
    this.buy = const [],
    this.link,
  });

  factory ProvidersData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProvidersData();

    List<StreamingProvider> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .map((e) => StreamingProvider.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ProvidersData(
      flatrate: parseList(json['flatrate']),
      rent: parseList(json['rent']),
      buy: parseList(json['buy']),
      link: json['link'] as String?,
    );
  }

  bool get hasAny => flatrate.isNotEmpty || rent.isNotEmpty || buy.isNotEmpty;
}

/// Film similaire (aperçu léger)
class SimilarMovie {
  final int tmdbId;
  final String title;
  final String posterPath;
  final double voteAverage;
  final String releaseDate;

  const SimilarMovie({
    required this.tmdbId,
    this.title = '',
    this.posterPath = '',
    this.voteAverage = 0.0,
    this.releaseDate = '',
  });

  factory SimilarMovie.fromJson(Map<String, dynamic> json) {
    final rawPoster = json['poster_path'] as String? ?? '';
    final poster = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$rawPoster'
        : '';

    return SimilarMovie(
      tmdbId: json['tmdb_id'] as int? ?? json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      posterPath: poster,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] as String? ?? '',
    );
  }

  String get year => releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

  bool get hasPoster => posterPath.isNotEmpty;
}

/// Détail complet d'un film (enrichi par TMDB)
class MovieDetail extends Movie {
  final String? backdropPath;
  final String? tagline;
  final int? budget;
  final int? revenue;
  final String? status;
  final String? originalLanguage;
  final String? selectedLanguage;
  final String? localizedTitle;
  final String? localizedOverview;
  final Trailer? trailer;
  final List<CastMember> cast;
  final List<Director> directors;
  final ProvidersData providers;
  final List<SimilarMovie> similar;
  final bool isSeen;
  final bool isLiked;
  final bool isDisliked;

  const MovieDetail({
    required super.tmdbId,
    required super.title,
    required super.overview,
    required super.posterPath,
    super.genres,
    super.voteAverage,
    super.runtime,
    super.releaseDate,
    super.actors,
    super.originCountry,
    super.userRating,
    super.userComment,
    super.seenDate,
    super.source,
    this.backdropPath,
    this.tagline,
    this.budget,
    this.revenue,
    this.status,
    this.originalLanguage,
    this.selectedLanguage,
    this.localizedTitle,
    this.localizedOverview,
    this.trailer,
    this.cast = const [],
    this.directors = const [],
    this.providers = const ProvidersData(),
    this.similar = const [],
    this.isSeen = false,
    this.isLiked = false,
    this.isDisliked = false,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    final rawPoster = json['poster_path'] as String? ?? '';
    final posterPath = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$rawPoster'
        : '';

    final castList = (json['cast'] as List<dynamic>? ?? [])
        .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
        .toList();

    final directorsList = (json['directors'] as List<dynamic>? ?? [])
        .map((d) => Director.fromJson(d as Map<String, dynamic>))
        .toList();

    final similarList = (json['similar'] as List<dynamic>? ?? [])
        .map((s) => SimilarMovie.fromJson(s as Map<String, dynamic>))
        .toList();

    final trailerJson = json['trailer'] as Map<String, dynamic>?;

    return MovieDetail(
      tmdbId: Movie.toIntStatic(json['tmdb_id'] ?? json['id']),
      title: TranslatableText.fromJson(json['title'] ?? ''),
      overview: TranslatableText.fromJson(json['overview'] ?? ''),
      posterPath: posterPath,
      genres: Movie.toStringListStatic(json['genres']),
      voteAverage: Movie.toDoubleStatic(json['vote_average']),
      runtime: Movie.toIntStatic(json['runtime']),
      releaseDate: json['release_date'] as String? ?? '',
      actors: Movie.toStringListStatic(json['actors']),
      originCountry: Movie.toStringListStatic(json['origin_country']),
      userRating: Movie.toNullableDoubleStatic(json['user_rating']),
      userComment: json['user_comment'] as String?,
      seenDate: json['seen_date'] as String?,
      source: json['source'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      tagline: json['tagline'] as String?,
      budget: json['budget'] as int?,
      revenue: json['revenue'] as int?,
      status: json['status'] as String?,
      originalLanguage: json['original_language'] as String?,
      selectedLanguage: json['selected_language'] as String?,
      localizedTitle: json['localized_title'] as String?,
      localizedOverview: json['localized_overview'] as String?,
      trailer: trailerJson != null ? Trailer.fromJson(trailerJson) : null,
      cast: castList,
      directors: directorsList,
      providers: ProvidersData.fromJson(
        json['providers'] as Map<String, dynamic>?,
      ),
      similar: similarList,
      isSeen: json['is_seen'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      isDisliked: json['is_disliked'] as bool? ?? false,
    );
  }

  bool get hasTrailer => trailer != null && trailer!.isValid;

  bool get hasBackdrop => backdropPath != null && backdropPath!.isNotEmpty;

  String get directorsDisplay => directors.map((d) => d.name).join(', ');
}
