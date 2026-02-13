/// Ami ou demande d'ami
class Friend {
  final String id;
  final String username;
  final String? bio;
  final int totalSeen;
  final int level;

  const Friend({
    this.id = '',
    required this.username,
    this.bio,
    this.totalSeen = 0,
    this.level = 0,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      totalSeen: json['total_seen'] as int? ?? 0,
      level: json['level'] as int? ?? 0,
    );
  }

  String get initial => username.isNotEmpty ? username[0].toUpperCase() : 'U';

  bool get hasBio => bio != null && bio!.isNotEmpty;
}

/// Données complètes de la liste d'amis
class FriendsData {
  final List<Friend> friends;
  final List<Friend> requestsReceived;
  final List<Friend> requestsSent;
  final int totalFriends;

  const FriendsData({
    this.friends = const [],
    this.requestsReceived = const [],
    this.requestsSent = const [],
    this.totalFriends = 0,
  });

  factory FriendsData.fromJson(Map<String, dynamic> json) {
    List<Friend> parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .map((e) => Friend.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FriendsData(
      friends: parseList(json['friends']),
      requestsReceived: parseList(json['requests_received']),
      requestsSent: parseList(json['requests_sent']),
      totalFriends: json['total_friends'] as int? ?? 0,
    );
  }

  bool get hasPendingRequests => requestsReceived.isNotEmpty;

  int get pendingCount => requestsReceived.length;
}
