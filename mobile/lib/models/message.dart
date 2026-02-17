/// Message de chat
class ChatMessage {
  final String id;
  final String senderUsername;
  final String receiverUsername;
  final String content;
  final DateTime createdAt;
  final bool read;
  final int? movieId;
  final String? movieTitle;
  final String? moviePoster;

  const ChatMessage({
    this.id = '',
    required this.senderUsername,
    this.receiverUsername = '',
    required this.content,
    required this.createdAt,
    this.read = false,
    this.movieId,
    this.movieTitle,
    this.moviePoster,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Le backend peut renvoyer sender_username directement ou sender.username
    final senderUsername =
        json['sender_username'] as String? ??
        (json['sender'] as Map<String, dynamic>?)?['username'] as String? ??
        '';

    final receiverUsername =
        json['receiver_username'] as String? ??
        (json['receiver'] as Map<String, dynamic>?)?['username'] as String? ??
        '';

    return ChatMessage(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      senderUsername: senderUsername,
      receiverUsername: receiverUsername,
      content: json['content'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      read: json['read'] as bool? ?? false,
      movieId:
          json['movie_id'] as int? ?? (json['movie'] as Map?)?['id'] as int?,
      movieTitle:
          json['movie_title'] as String? ??
          (json['movie'] as Map?)?['title'] as String?,
      moviePoster: _buildPosterUrl(
        json['movie_poster'] as String? ??
            (json['movie'] as Map?)?['poster'] as String?,
      ),
    );
  }

  /// Message créé localement (envoi instantané)
  factory ChatMessage.local({
    required String content,
    required String senderUsername,
    required String receiverUsername,
    int? movieId,
    String? movieTitle,
    String? moviePoster,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'local_${now.microsecondsSinceEpoch}',
      senderUsername: senderUsername,
      receiverUsername: receiverUsername,
      content: content,
      createdAt: now,
      read: false,
      movieId: movieId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
    );
  }

  bool isSentBy(String myUsername) =>
      senderUsername == myUsername || senderUsername == 'me';

  bool isFrom(String otherUsername) => senderUsername == otherUsername;

  static String? _buildPosterUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://image.tmdb.org/t/p/w500$path';
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) {
      if (value.isUtc) return value.toLocal();
      // Backward compatibility: naive server timestamps are treated as UTC.
      return DateTime.utc(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      ).toLocal();
    }
    if (value is String) {
      var normalized = value.trim();
      final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
      if (!hasTimezone) {
        normalized = '${normalized}Z';
      }
      final parsed = DateTime.tryParse(normalized);
      return parsed?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Conversation (résumé pour la liste de chat)
class Conversation {
  final String username;
  final String? bio;
  final String lastMessageContent;
  final bool lastMessageIsSent;
  final DateTime lastMessageDate;
  final int unreadCount;

  const Conversation({
    required this.username,
    this.bio,
    required this.lastMessageContent,
    this.lastMessageIsSent = false,
    required this.lastMessageDate,
    this.unreadCount = 0,
  });

  static int _parseUnreadCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _extractUsername(
    Map<String, dynamic> json,
    Map<String, dynamic> user,
    Map<String, dynamic> lastMsg,
  ) {
    final userUsername = user['username']?.toString().trim();
    if (userUsername != null && userUsername.isNotEmpty) {
      return userUsername;
    }

    final fallbackUsername = json['username']?.toString().trim();
    if (fallbackUsername != null && fallbackUsername.isNotEmpty) {
      return fallbackUsername;
    }

    final sender = lastMsg['sender_username']?.toString().trim();
    if (sender != null && sender.isNotEmpty) return sender;

    final receiver = lastMsg['receiver_username']?.toString().trim();
    if (receiver != null && receiver.isNotEmpty) return receiver;

    return '';
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final user =
        (json['user'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ) ??
        <String, dynamic>{};
    final lastMsg =
        (json['last_message'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ) ??
        <String, dynamic>{};
    final username = _extractUsername(json, user, lastMsg);

    return Conversation(
      username: username,
      bio: user['bio']?.toString() ?? json['bio']?.toString(),
      lastMessageContent: lastMsg['content']?.toString() ?? '',
      lastMessageIsSent: lastMsg['is_sent'] as bool? ?? false,
      lastMessageDate: ChatMessage._parseDate(lastMsg['created_at']),
      unreadCount: _parseUnreadCount(json['unread_count']),
    );
  }

  bool get hasUnread => unreadCount > 0;

  String get initial => username.isNotEmpty ? username[0].toUpperCase() : 'U';
}
