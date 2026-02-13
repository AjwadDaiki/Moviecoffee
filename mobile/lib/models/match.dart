/// Match cinématographique entre deux utilisateurs
class MovieMatch {
  final String id;
  final String matchedWithUsername;
  final int movieId;
  final String movieTitle;
  final String moviePoster;
  final DateTime createdAt;

  const MovieMatch({
    this.id = '',
    required this.matchedWithUsername,
    this.movieId = 0,
    this.movieTitle = '',
    this.moviePoster = '',
    required this.createdAt,
  });

  factory MovieMatch.fromJson(Map<String, dynamic> json) {
    final matchedWith = json['matched_with'] as Map<String, dynamic>? ?? {};
    final movie = json['movie'] as Map<String, dynamic>? ?? {};

    final rawPoster = movie['poster'] as String? ?? '';
    final poster = rawPoster.startsWith('http')
        ? rawPoster
        : rawPoster.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$rawPoster'
        : '';

    return MovieMatch(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      matchedWithUsername: matchedWith['username'] as String? ?? '',
      movieId: movie['id'] as int? ?? 0,
      movieTitle: movie['title'] as String? ?? '',
      moviePoster: poster,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get initial => matchedWithUsername.isNotEmpty
      ? matchedWithUsername[0].toUpperCase()
      : 'U';

  bool get hasPoster => moviePoster.isNotEmpty;

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
