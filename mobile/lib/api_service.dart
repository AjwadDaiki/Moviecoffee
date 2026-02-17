import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'models/models.dart';

class ApiService {
  static String get baseUrl => kIsWeb
      ? "http://127.0.0.1:8000"
      : (Platform.isAndroid ? "http://10.0.2.2:8000" : "http://127.0.0.1:8000");

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final _storage = const FlutterSecureStorage();

  Future<Options> _getAuthOptions() async {
    String? token = await _storage.read(key: 'jwt_token');
    return Options(headers: {"Authorization": "Bearer $token"});
  }

  // --- ERROR HANDLING WRAPPER ---
  Future<T?> _handleRequest<T>(
    Future<T> Function() request, {
    String? errorMessage,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      String message = errorMessage ?? _getDioErrorMessage(e);
      _logError(message, e);
      throw ApiException(message);
    } catch (e) {
      String message = errorMessage ?? "Une erreur inattendue s'est produite";
      _logError(message, e);
      throw ApiException(message);
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connexion au serveur trop lente";
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) return "Session expirée. Reconnectez-vous.";
        if (statusCode == 404) return "Ressource introuvable";
        if (statusCode == 500) return "Erreur serveur";
        return e.response?.data['detail'] ?? "Erreur HTTP $statusCode";
      case DioExceptionType.cancel:
        return "Requête annulée";
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return "Pas de connexion Internet";
        }
        return "Impossible de contacter le serveur";
      default:
        return "Erreur réseau";
    }
  }

  void _logError(String message, Object error) {
    if (kDebugMode) {
      print("❌ API Error: $message");
      print("   Details: $error");
    }
  }

  // --- ACTIONS (v3.0) ---
  Future<Map<String, dynamic>?> sendActionV3(
    int tmdbId,
    String action, {
    double? rating,
    String? comment,
  }) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/action/v3',
        data: {
          "movie_id": tmdbId,
          "action": action,
          if (rating != null) "rating": rating,
          if (comment != null) "comment": comment,
        },
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible d'enregistrer votre action");
  }

  // Rétro-compatibilité v2
  Future<bool> sendAction(
    int tmdbId,
    String action, {
    double? rating,
    String? comment,
  }) async {
    final result = await sendActionV3(
      tmdbId,
      action,
      rating: rating,
      comment: comment,
    );
    return result != null;
  }

  // --- PAIRING ---
  Future<Map<String, dynamic>?> linkPartner(String username) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/pair/link',
        data: {"username": username},
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de se lier à ce compte");
  }

  Future<bool> unlinkPartner() async {
    return await _handleRequest(() async {
          await _dio.post('/pair/unlink', options: await _getAuthOptions());
          return true;
        }, errorMessage: "Impossible de délier le partenaire") ??
        false;
  }

  Future<Map<String, dynamic>?> getPartnerStatus() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/pair/status',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de récupérer le statut");
  }

  Future<Map<String, dynamic>?> getCompatibilityWith(String username) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/pair/compatibility/$username',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de calculer la compatibilite");
  }

  // --- MATCH CHECK ---
  Future<Map<String, dynamic>?> checkMatch(int tmdbId) async {
    return await _handleRequest(
      () async {
        final response = await _dio.post(
          '/action/check-match',
          data: {"movie_id": tmdbId},
          options: await _getAuthOptions(),
        );
        return response.data as Map<String, dynamic>;
      },
      errorMessage: null, // Pas d'erreur affichée, juste return null
    );
  }

  // --- FEED ---
  Future<List<Movie>> fetchFeed({String? genre, int? year}) async {
    return await _handleRequest(() async {
          final queryParams = <String, dynamic>{};
          if (genre != null && genre != "Tous") queryParams['genre'] = genre;
          if (year != null) queryParams['year'] = year;

          final response = await _dio.get(
            '/feed',
            queryParameters: queryParams,
            options: await _getAuthOptions(),
          );
          return (response.data as List)
              .map((json) => Movie.fromJson(json))
              .toList();
        }, errorMessage: "Impossible de charger le feed") ??
        [];
  }

  // --- COLLECTION ---
  Future<Map<String, List<Movie>>> fetchMyList() async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/my-list',
            options: await _getAuthOptions(),
          );

          final toSee =
              (response.data['to_see'] as List?)
                  ?.map((j) => Movie.fromJson(j))
                  .toList() ??
              [];

          final seen =
              (response.data['seen'] as List?)
                  ?.map((j) => Movie.fromJson(j))
                  .toList() ??
              [];

          return {"to_see": toSee, "seen": seen};
        }, errorMessage: "Impossible de charger votre collection") ??
        {"to_see": [], "seen": []};
  }

  // --- PROFILE ---
  Future<Map<String, dynamic>?> getProfile() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/me/v2',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger votre profil");
  }

  // --- STATS ---
  Future<AdvancedStats?> getAdvancedStats() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/stats/advanced',
        options: await _getAuthOptions(),
      );
      return AdvancedStats.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger les statistiques");
  }

  // --- HEALTH CHECK ---
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- PASSWORD RESET ---
  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {"email": email},
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible d'envoyer le lien de réinitialisation");
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    return await _handleRequest(() async {
          await _dio.post(
            '/auth/reset-password',
            data: {"token": token, "new_password": newPassword},
          );
          return true;
        }, errorMessage: "Impossible de réinitialiser le mot de passe") ??
        false;
  }

  // ============================================================================
  // ROUTES SOCIALES (v3.0)
  // ============================================================================

  // --- AMIS ---
  Future<Map<String, dynamic>?> addFriend(String username) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/social/friends/add',
        data: {"target_username": username},
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible d'ajouter cet ami");
  }

  Future<Map<String, dynamic>?> acceptFriend(String userId) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/social/friends/accept/$userId',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible d'accepter cette demande");
  }

  Future<bool> removeFriend(String userId) async {
    return await _handleRequest(() async {
          await _dio.delete(
            '/social/friends/remove/$userId',
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de retirer cet ami") ??
        false;
  }

  Future<bool> declineFriend(String userId) async {
    return await _handleRequest(() async {
          await _dio.delete(
            '/social/friends/decline/$userId',
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de refuser cette demande") ??
        false;
  }

  Future<bool> followUser(String username) async {
    return await _handleRequest(() async {
          await _dio.post(
            '/social/follow/$username',
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de suivre cet utilisateur") ??
        false;
  }

  Future<bool> unfollowUser(String username) async {
    return await _handleRequest(() async {
          await _dio.delete(
            '/social/unfollow/$username',
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de ne plus suivre cet utilisateur") ??
        false;
  }

  Future<FriendsData?> getFriendsList() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/social/friends/list',
        options: await _getAuthOptions(),
      );
      return FriendsData.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger la liste d'amis");
  }

  Future<List<AppUser>> searchUsers(String query, {int limit = 20}) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/search',
            queryParameters: {'q': query, 'limit': limit},
            options: await _getAuthOptions(),
          );
          return ((response.data['users'] as List?) ?? [])
              .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
              .toList();
        }, errorMessage: "Impossible de rechercher des utilisateurs") ??
        [];
  }

  // --- PROFILS PUBLICS ---
  Future<PublicProfile?> getPublicProfile(String username) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/social/profile/$username',
        options: await _getAuthOptions(),
      );
      return PublicProfile.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger ce profil");
  }

  // --- FEED SOCIAL ---
  Future<List<FeedActivity>> getSocialFeed({
    int page = 1,
    int limit = 20,
  }) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/feed',
            queryParameters: {'page': page, 'limit': limit},
            options: await _getAuthOptions(),
          );
          final data = response.data as Map<String, dynamic>;
          return ((data['activities'] as List?) ?? [])
              .map((j) => FeedActivity.fromJson(j as Map<String, dynamic>))
              .toList();
        }, errorMessage: "Impossible de charger le feed social") ??
        [];
  }

  Future<bool> reactToActivity(
    String activityId,
    String reactionType, {
    String? commentText,
  }) async {
    return await _handleRequest(() async {
          await _dio.post(
            '/social/react',
            data: {
              "activity_id": activityId,
              "reaction_type": reactionType,
              if (commentText != null) "comment_text": commentText,
            },
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de réagir à cette activité") ??
        false;
  }

  Future<Map<String, dynamic>?> getActivityReactions(String activityId) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/social/activity/$activityId/reactions',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger les réactions");
  }

  // --- CHAT ---
  Future<List<ChatMessage>> getChatHistory(
    String username, {
    int page = 1,
    int limit = 50,
  }) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/chat/$username',
            queryParameters: {'page': page, 'limit': limit},
            options: await _getAuthOptions(),
          );
          final data = response.data as Map<String, dynamic>;
          return ((data['messages'] as List?) ?? [])
              .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
              .toList();
        }, errorMessage: "Impossible de charger l'historique de chat") ??
        [];
  }

  Future<bool> sendMessage(
    String receiverUsername,
    String content, {
    int? movieId,
  }) async {
    return await _handleRequest(() async {
          await _dio.post(
            '/social/chat/send',
            data: {
              "receiver_username": receiverUsername,
              "content": content,
              if (movieId != null) "movie_id": movieId,
            },
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible d'envoyer le message") ??
        false;
  }

  Future<List<Conversation>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/chat/conversations',
            queryParameters: {'page': page, 'limit': limit},
            options: await _getAuthOptions(),
          );
          final data = response.data as Map<String, dynamic>;
          return ((data['conversations'] as List?) ?? [])
              .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
              .toList();
        }, errorMessage: "Impossible de charger les conversations") ??
        [];
  }

  // --- MATCHS ---
  Future<List<MovieMatch>> getMatches({int page = 1, int limit = 20}) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/matches',
            queryParameters: {'page': page, 'limit': limit},
            options: await _getAuthOptions(),
          );
          final data = response.data as Map<String, dynamic>;
          return ((data['matches'] as List?) ?? [])
              .map((j) => MovieMatch.fromJson(j as Map<String, dynamic>))
              .toList();
        }, errorMessage: "Impossible de charger les matchs") ??
        [];
  }

  Future<int> getUnviewedMatchesCount() async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/social/matches/count',
            options: await _getAuthOptions(),
          );
          return response.data['unviewed_count'] as int? ?? 0;
        }, errorMessage: null) ??
        0;
  }

  // ============================================================================
  // ROUTE DÉTAIL FILM
  // ============================================================================

  Future<MovieDetail?> getMovieDetail(
    int tmdbId, {
    String? languageCode,
  }) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/movie/$tmdbId',
        queryParameters: languageCode != null && languageCode.trim().isNotEmpty
            ? {'lang': languageCode.trim().toLowerCase()}
            : null,
        options: await _getAuthOptions(),
      );
      return MovieDetail.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger les détails du film");
  }

  // ============================================================================
  // ROUTES SETTINGS / PROFIL
  // ============================================================================

  Future<Map<String, dynamic>?> updateProfile({
    String? bio,
    String? username,
    String? preferredLanguage,
    bool? askSeenRatingPrompt,
  }) async {
    return await _handleRequest(() async {
      final data = <String, dynamic>{};
      if (bio != null) data['bio'] = bio;
      if (username != null) data['username'] = username;
      if (preferredLanguage != null) {
        data['preferred_language'] = preferredLanguage;
      }
      if (askSeenRatingPrompt != null) {
        data['ask_seen_rating_prompt'] = askSeenRatingPrompt;
      }
      final response = await _dio.put(
        '/me/profile',
        data: data,
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de mettre à jour le profil");
  }

  Future<String?> uploadAvatar(String filePath) async {
    return await _handleRequest(() async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      });
      final response = await _dio.put(
        '/me/avatar',
        data: formData,
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return (data['avatar_url'] as String?) ?? '';
    }, errorMessage: "Impossible de mettre à jour la photo de profil");
  }

  Future<Map<String, dynamic>?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return await _handleRequest(() async {
      final response = await _dio.put(
        '/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de changer le mot de passe");
  }

  Future<bool> deleteAccount() async {
    return await _handleRequest(() async {
          await _dio.delete('/me/account', options: await _getAuthOptions());
          return true;
        }, errorMessage: "Impossible de supprimer le compte") ??
        false;
  }

  Future<Map<String, dynamic>?> requestEmailVerification() async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/auth/request-email-verification',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de lancer la verification email");
  }

  Future<Map<String, dynamic>?> verifyEmail(String token) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'token': token},
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de verifier l'email");
  }

  // ============================================================================
  // ROUTES INTEGRATIONS (LETTERBOXD + INGEST TMDB)
  // ============================================================================

  Future<Map<String, dynamic>?> getLetterboxdStatus() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/integrations/letterboxd/status',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger le statut Letterboxd");
  }

  Future<Map<String, dynamic>?> connectLetterboxd(String username) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/integrations/letterboxd/connect',
        data: {"username": username},
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de connecter Letterboxd");
  }

  Future<bool> disconnectLetterboxd() async {
    return await _handleRequest(() async {
          await _dio.delete(
            '/integrations/letterboxd/connect',
            options: await _getAuthOptions(),
          );
          return true;
        }, errorMessage: "Impossible de deconnecter Letterboxd") ??
        false;
  }

  Future<Map<String, dynamic>?> syncLetterboxd({
    int maxItems = 1200,
    bool includeWatchlist = true,
    int watchlistMaxItems = 1200,
  }) async {
    try {
      final response = await _dio.post(
        '/integrations/letterboxd/sync',
        data: {
          "max_items": maxItems,
          "include_watchlist": includeWatchlist,
          "watchlist_max_items": watchlistMaxItems,
        },
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        final raw = e.response?.data;
        final detail = raw is Map ? raw['detail'] : null;
        return {
          "status": "already_running",
          "detail": (detail ?? "Une synchronisation est deja en cours.")
              .toString(),
        };
      }
      final message = "Impossible de lancer la synchronisation Letterboxd";
      _logError(message, e);
      throw ApiException(message);
    } catch (e) {
      final message = "Impossible de lancer la synchronisation Letterboxd";
      _logError(message, e);
      throw ApiException(message);
    }
  }

  Future<Map<String, dynamic>?> getTmdbIngestStatus({
    required String adminToken,
  }) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/integrations/admin/tmdb/status',
        options: Options(headers: {"x-admin-token": adminToken}),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger le statut d'ingestion TMDB");
  }

  Future<Map<String, dynamic>?> startTmdbIngest({
    required String adminToken,
    int targetTotal = 40000,
    int startPage = 1,
    int maxPages = 2000,
  }) async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/integrations/admin/tmdb/start',
        data: {
          "target_total": targetTotal,
          "start_page": startPage,
          "max_pages": maxPages,
        },
        options: Options(headers: {"x-admin-token": adminToken}),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de lancer l'ingestion TMDB");
  }

  // ============================================================================
  // ROUTES GAMIFICATION
  // ============================================================================

  Future<GamificationData?> getGamification() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/gamification',
        options: await _getAuthOptions(),
      );
      return GamificationData.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger la gamification");
  }

  // ============================================================================
  // ROUTES STATS AVANCÉES (v3.0)
  // ============================================================================

  Future<Map<String, dynamic>?> getMyStats() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/stats/me',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger les statistiques");
  }

  Future<AdvancedStats?> getPeriodStats(String period) async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/stats/period',
        queryParameters: {'period': period},
        options: await _getAuthOptions(),
      );
      return AdvancedStats.fromJson(response.data as Map<String, dynamic>);
    }, errorMessage: "Impossible de charger les statistiques de période");
  }

  Future<Map<String, dynamic>?> getAllBadges() async {
    return await _handleRequest(() async {
      final response = await _dio.get(
        '/stats/badges',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de charger les badges");
  }

  Future<Map<String, dynamic>?> checkBadges() async {
    return await _handleRequest(() async {
      final response = await _dio.post(
        '/stats/badges/check',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: null);
  }

  // --- RECHERCHE ---
  Future<List<Movie>> searchMovies(String query, {int limit = 20}) async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/stats/search/movies',
            queryParameters: {'q': query, 'limit': limit},
            options: await _getAuthOptions(),
          );
          return ((response.data['movies'] as List?) ?? [])
              .map((j) => Movie.fromJson(j))
              .toList();
        }, errorMessage: "Impossible de rechercher des films") ??
        [];
  }

  // ============================================================================
  // ROUTES FEED AVANCÉES (v3.0)
  // ============================================================================

  Future<List<Movie>> fetchFeedAdvanced({
    String? genre,
    int? year,
    String? decade,
    int? runtimeMin,
    int? runtimeMax,
    String? country,
    double? minRating,
    String mode = "personalized",
    double exploratoryRatio = 0.22,
  }) async {
    return await _handleRequest(() async {
          final queryParams = <String, dynamic>{};
          if (genre != null && genre != "Tous") queryParams['genre'] = genre;
          if (year != null) queryParams['year'] = year;
          if (decade != null) queryParams['decade'] = decade;
          if (runtimeMin != null) queryParams['runtime_min'] = runtimeMin;
          if (runtimeMax != null) queryParams['runtime_max'] = runtimeMax;
          if (country != null) queryParams['country'] = country;
          if (minRating != null) queryParams['min_rating'] = minRating;
          queryParams['mode'] = mode;
          queryParams['exploratory_ratio'] = exploratoryRatio;

          final response = await _dio.get(
            '/feed/advanced',
            queryParameters: queryParams,
            options: await _getAuthOptions(),
          );
          return (response.data as List)
              .map((json) => Movie.fromJson(json))
              .toList();
        }, errorMessage: "Impossible de charger le feed") ??
        [];
  }

  Future<Map<String, dynamic>?> fetchSoloAiChoice({
    String source = "wishlist",
    String? mood,
    int? runtimeMax,
    String? era,
  }) async {
    return await _handleRequest(() async {
      final query = <String, dynamic>{"source": source};
      if (mood != null && mood.trim().isNotEmpty) query["mood"] = mood.trim();
      if (runtimeMax != null) query["runtime_max"] = runtimeMax;
      if (era != null && era.trim().isNotEmpty) query["era"] = era.trim();
      final response = await _dio.get(
        '/feed/solo-choice',
        queryParameters: query,
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    }, errorMessage: "Impossible de choisir un film avec l'IA");
  }

  // ============================================================================
  // ROUTES COLLECTION ÉTENDUES (v3.0)
  // ============================================================================

  Future<Map<String, List<Movie>>> fetchMyListV2() async {
    return await _handleRequest(() async {
          final response = await _dio.get(
            '/my-list/v2',
            options: await _getAuthOptions(),
          );

          final toSee =
              (response.data['to_see'] as List?)
                  ?.map((j) => Movie.fromJson(j))
                  .toList() ??
              [];

          final seen =
              (response.data['seen'] as List?)
                  ?.map((j) => Movie.fromJson(j))
                  .toList() ??
              [];

          final all =
              (response.data['all'] as List?)
                  ?.map((j) => Movie.fromJson(j))
                  .toList() ??
              [];

          return {"to_see": toSee, "seen": seen, "all": all};
        }, errorMessage: "Impossible de charger votre collection") ??
        {"to_see": [], "seen": [], "all": []};
  }
}

// --- CUSTOM EXCEPTION ---
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
