/// Utilisateur — profil complet ou aperçu
class AppUser {
  final String id;
  final String username;
  final String email;
  final String bio;
  final String avatarUrl;

  // Stats rapides
  final int totalSeen;
  final int totalLiked;
  final int totalMinutes;
  final int level;
  final int xp;

  // Relations
  final bool isFriend;
  final bool requestSent;
  final bool requestReceived;

  const AppUser({
    this.id = '',
    this.username = '',
    this.email = '',
    this.bio = '',
    this.avatarUrl = '',
    this.totalSeen = 0,
    this.totalLiked = 0,
    this.totalMinutes = 0,
    this.level = 1,
    this.xp = 0,
    this.isFriend = false,
    this.requestSent = false,
    this.requestReceived = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      totalSeen: json['total_seen'] as int? ?? 0,
      totalLiked: json['total_liked'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      isFriend: json['is_friend'] as bool? ?? false,
      requestSent: json['request_sent'] as bool? ?? false,
      requestReceived: json['request_received'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'bio': bio,
        'avatar_url': avatarUrl,
        'total_seen': totalSeen,
        'level': level,
      };

  /// Initiale pour l'avatar
  String get initial => username.isNotEmpty ? username[0].toUpperCase() : 'U';

  bool get hasBio => bio.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && id == other.id && username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;
}
