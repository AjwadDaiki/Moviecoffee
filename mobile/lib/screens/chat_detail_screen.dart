import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/coffee_colors.dart';
import 'user_profile_screen.dart';
import 'movie_detail_screen.dart';
import 'search_screen.dart';

/// =============================================================================
/// CHAT DETAIL SCREEN - Conversation 1-on-1 (Premium Design)
/// =============================================================================

class ChatDetailScreen extends StatefulWidget {
  final String username;
  final String? userBio;
  final int? matchMovieId;
  final String? matchMovieTitle;
  final String? matchMoviePoster;

  const ChatDetailScreen({
    super.key,
    required this.username,
    this.userBio,
    this.matchMovieId,
    this.matchMovieTitle,
    this.matchMoviePoster,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _apiService = ApiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _currentPage = 1;
  bool _hasMore = true;
  static const _pageSize = 50;
  int? _draftMovieId;
  String? _draftMovieTitle;
  String? _draftMoviePoster;

  // Auto-refresh timer
  late final Stream<int> _refreshTimer = Stream<int>.periodic(
    const Duration(seconds: 5),
    (tick) => tick,
  );
  late final StreamSubscription<int> _refreshSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _draftMovieId = widget.matchMovieId;
    _draftMovieTitle = widget.matchMovieTitle;
    _draftMoviePoster = widget.matchMoviePoster;
    _loadMessages();
    _scrollController.addListener(_onScroll);

    // Auto-refresh toutes les 5 secondes
    _refreshSubscription = _refreshTimer.listen((_) {
      if (mounted && !_isRefreshing && !_isSending) {
        _refreshMessages();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Refresh silencieux des messages (sans loader)
  Future<void> _refreshMessages() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final newMessages = await _apiService.getChatHistory(
        widget.username,
        page: 1,
        limit: _pageSize,
      );
      final merged = _mergeMessages(_messages, newMessages);
      final hasChanged = _hasMessageListChanged(_messages, merged);

      if (mounted && hasChanged) {
        setState(() {
          _messages = merged;
        });

        // Auto-scroll si prÃ¨s du bas
        if (_scrollController.hasClients) {
          final position = _scrollController.position;
          if (position.maxScrollExtent - position.pixels < 100) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }
    } catch (_) {
      // Silencieux
    } finally {
      _isRefreshing = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) {
      if (!_isLoading && _hasMore) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _apiService.getChatHistory(
        widget.username,
        page: 1,
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _messages = _sortMessagesChronologically(messages);
          _hasMore = messages.length >= _pageSize;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    setState(() => _isLoading = true);

    try {
      final older = await _apiService.getChatHistory(
        widget.username,
        page: _currentPage + 1,
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _messages = _mergeMessages(_messages, older);
          _hasMore = older.length >= _pageSize;
          _currentPage++;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          final delta = newMaxExtent - previousMaxExtent;
          if (delta > 0) {
            _scrollController.jumpTo(_scrollController.position.pixels + delta);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ChatMessage> _sortMessagesChronologically(
    Iterable<ChatMessage> messages,
  ) {
    final sorted = messages.toList()
      ..sort((a, b) {
        final dateCmp = a.createdAt.compareTo(b.createdAt);
        if (dateCmp != 0) return dateCmp;
        if (a.id.isEmpty || b.id.isEmpty) return 0;
        return a.id.compareTo(b.id);
      });
    return sorted;
  }

  String _messageIdentity(ChatMessage message) {
    if (message.id.isNotEmpty) {
      return 'id:${message.id}';
    }
    return 'local:${message.senderUsername}:${message.receiverUsername}:${message.createdAt.millisecondsSinceEpoch}:${message.content}:${message.movieId ?? 0}';
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final mergedByKey = <String, ChatMessage>{};

    for (final message in current) {
      mergedByKey[_messageIdentity(message)] = message;
    }
    for (final message in incoming) {
      mergedByKey[_messageIdentity(message)] = message;
    }

    final sorted = _sortMessagesChronologically(mergedByKey.values);
    final deduped = <ChatMessage>[];

    for (final message in sorted) {
      if (!message.id.startsWith('local_')) {
        deduped.add(message);
        continue;
      }

      final localFromMe =
          message.senderUsername.toLowerCase() != widget.username.toLowerCase();
      final duplicateOnServer = sorted.any((other) {
        if (other.id.startsWith('local_')) return false;
        final otherFromMe =
            other.senderUsername.toLowerCase() != widget.username.toLowerCase();
        if (!localFromMe || !otherFromMe) return false;
        if (other.content != message.content) return false;
        if ((other.movieId ?? 0) != (message.movieId ?? 0)) return false;
        return (other.createdAt.difference(message.createdAt).inSeconds)
                .abs() <=
            20;
      });

      if (!duplicateOnServer) {
        deduped.add(message);
      }
    }

    return deduped;
  }

  bool _hasMessageListChanged(
    List<ChatMessage> before,
    List<ChatMessage> after,
  ) {
    if (before.length != after.length) return true;
    for (var i = 0; i < before.length; i++) {
      final a = before[i];
      final b = after[i];
      if (_messageIdentity(a) != _messageIdentity(b)) return true;
      if (a.read != b.read) return true;
    }
    return false;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final hasAttachedMovie = _draftMovieId != null && _draftMovieId! > 0;
    if ((text.isEmpty && !hasAttachedMovie) || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final content = text.isNotEmpty
          ? text
          : (_draftMovieTitle?.trim().isNotEmpty == true
                ? _draftMovieTitle!.trim()
                : 'Regarde ce film !');
      final sentMovieId = _draftMovieId;
      final sentMovieTitle = _draftMovieTitle;
      final sentMoviePoster = _draftMoviePoster;

      final success = await _apiService.sendMessage(
        widget.username,
        content,
        movieId: sentMovieId,
      );

      if (success && mounted) {
        // Ajouter le message localement pour feedback instantanÃ©
        setState(() {
          _messages.add(
            ChatMessage.local(
              content: content,
              senderUsername: 'me',
              receiverUsername: widget.username,
              movieId: sentMovieId,
              movieTitle: sentMovieTitle,
              moviePoster: sentMoviePoster,
            ),
          );
          _draftMovieId = null;
          _draftMovieTitle = null;
          _draftMoviePoster = null;
          _isSending = false;
        });

        // Scroll vers le bas
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() => _isSending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Couleur avatar basÃ©e sur le username
  void _attachMovieToDraft({
    required int movieId,
    required String movieTitle,
    String? moviePoster,
  }) {
    if (!mounted || movieId <= 0) return;
    setState(() {
      _draftMovieId = movieId;
      _draftMovieTitle = movieTitle;
      _draftMoviePoster = moviePoster;
    });
  }

  void _clearDraftMovie() {
    if (!mounted) return;
    setState(() {
      _draftMovieId = null;
      _draftMovieTitle = null;
      _draftMoviePoster = null;
    });
  }

  List<Color> get _avatarGradient {
    final gradients = [
      [CoffeeColors.terracotta, CoffeeColors.caramelBronze],
      [const Color(0xFF9E7E73), const Color(0xFF7D5D52)],
      [const Color(0xFFA48275), const Color(0xFF89685D)],
      [const Color(0xFFB08D81), const Color(0xFF8F6D62)],
    ];
    final index = widget.username.hashCode.abs() % gradients.length;
    return gradients[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? _buildShimmerLoading()
                : _buildMessageList(),
          ),

          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const Spacer(),
          // Simulate chat bubbles skeleton
          _shimmerBubble(isRight: false, width: 180),
          const SizedBox(height: 8),
          _shimmerBubble(isRight: false, width: 140),
          const SizedBox(height: 12),
          _shimmerBubble(isRight: true, width: 200),
          const SizedBox(height: 8),
          _shimmerBubble(isRight: true, width: 120),
          const SizedBox(height: 12),
          _shimmerBubble(isRight: false, width: 160),
          const SizedBox(height: 8),
          _shimmerBubble(isRight: true, width: 180),
        ],
      ),
    );
  }

  Widget _shimmerBubble({required bool isRight, required double width}) {
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 42,
        margin: EdgeInsets.only(
          left: isRight ? 52 : (isRight ? 0 : 38),
          right: isRight ? 0 : 52,
        ),
        decoration: BoxDecoration(
          color: isRight
              ? CoffeeColors.caramelBronze.withValues(alpha: 0.15)
              : CoffeeColors.steamMilk.withValues(alpha: 0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isRight ? 18 : 4),
            bottomRight: Radius.circular(isRight ? 4 : 18),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserProfileScreen(username: widget.username),
            ),
          );
        },
        child: Row(
          children: [
            // Avatar dans l'appbar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _avatarGradient[0],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _avatarGradient[0].withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.username.isNotEmpty
                      ? widget.username[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (widget.userBio != null)
                    Text(
                      widget.userBio!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.person_outline_rounded,
            color: AppTheme.textSecondary,
            size: 22,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfileScreen(username: widget.username),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.border.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppTheme.accent.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Commencez la conversation',
              style: TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyez un message a ${widget.username}',
              style: const TextStyle(
                fontFamily: 'RecoletaAlt',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading && _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator en haut si chargement pagination
        if (index == 0 && _isLoading && _hasMore) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        }

        final messageIndex = _isLoading && _hasMore ? index - 1 : index;
        final message = _messages[messageIndex];

        // DÃ©terminer si le message est envoyÃ© par moi
        final isSentByMe =
            message.senderUsername.toLowerCase() !=
            widget.username.toLowerCase();

        // VÃ©rifier si on doit afficher le sÃ©parateur de date
        bool showDateSeparator = false;
        if (messageIndex == 0) {
          showDateSeparator = true;
        } else {
          final prevMessage = _messages[messageIndex - 1];
          showDateSeparator =
              prevMessage.createdAt.day != message.createdAt.day ||
              prevMessage.createdAt.month != message.createdAt.month ||
              prevMessage.createdAt.year != message.createdAt.year;
        }

        // VÃ©rifier si on affiche l'avatar (premier msg ou changement de sender)
        bool showAvatar = !isSentByMe;
        if (!isSentByMe && messageIndex > 0) {
          final prevMessage = _messages[messageIndex - 1];
          final prevIsSentByMe =
              prevMessage.senderUsername.toLowerCase() !=
              widget.username.toLowerCase();
          if (!prevIsSentByMe) showAvatar = false; // Suite du mÃªme sender
        }
        if (messageIndex == 0 && !isSentByMe) showAvatar = true;

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.createdAt),
            _MessageBubble(
              content: message.content,
              isSentByMe: isSentByMe,
              timestamp: message.createdAt,
              movieId: message.movieId,
              movieTitle: message.movieTitle,
              moviePoster: message.moviePoster,
              otherUsername: widget.username,
              showAvatar: showAvatar,
              avatarGradient: _avatarGradient,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final dayDiff = today.difference(messageDay).inDays;
    String label;

    if (dayDiff <= 0) {
      label = "Aujourd'hui";
    } else if (dayDiff == 1) {
      label = 'Hier';
    } else if (dayDiff < 7) {
      const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      label = jours[date.weekday - 1];
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'RecoletaAlt',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.border, thickness: 0.5)),
        ],
      ),
    );
  }

  Future<void> _shareMovie() async {
    final selectedMovie = await Navigator.push<Movie>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SearchScreen(initialTab: 0, selectMovieMode: true),
      ),
    );

    if (selectedMovie == null || selectedMovie.tmdbId <= 0 || !mounted) {
      return;
    }

    final title = selectedMovie.title.fr.isNotEmpty
        ? selectedMovie.title.fr
        : 'Film';
    _attachMovieToDraft(
      movieId: selectedMovie.tmdbId,
      movieTitle: title,
      moviePoster: selectedMovie.posterPath,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        10,
        10,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: CoffeeColors.latteCream,
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_draftMovieId != null && _draftMovieId! > 0) ...[
            _buildDraftMoviePreview(),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _shareMovie,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: CoffeeColors.milkFoam,
                    shape: BoxShape.circle,
                    border: Border.all(color: CoffeeColors.creamBorder),
                  ),
                  child: const Icon(
                    Icons.movie_rounded,
                    color: CoffeeColors.caramelBronze,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: CoffeeColors.steamMilk,
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _draftMovieId != null && _draftMovieId! > 0
                          ? 'Ajoutez un message (optionnel)...'
                          : 'Votre message...',
                      hintStyle: const TextStyle(
                        fontFamily: 'RecoletaAlt',
                        color: CoffeeColors.steamMilk,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.dmSans(
                      color: CoffeeColors.espresso,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? CoffeeColors.steamMilk
                        : const Color(0xFF4A3529),
                    shape: BoxShape.circle,
                    boxShadow: _isSending
                        ? []
                        : [
                            BoxShadow(
                              color: CoffeeColors.caramelBronze.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: _isSending
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftMoviePreview() {
    final movieId = _draftMovieId;
    final movieTitle = _draftMovieTitle ?? 'Film';
    final moviePoster = _draftMoviePoster;
    if (movieId == null || movieId <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(
              tmdbId: movieId,
              title: movieTitle,
              posterUrl: moviePoster,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CoffeeColors.creamBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: moviePoster != null && moviePoster.isNotEmpty
                  ? Image.network(
                      moviePoster,
                      width: 44,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 60,
                        color: CoffeeColors.latteCream,
                        child: const Icon(
                          Icons.movie_rounded,
                          size: 20,
                          color: CoffeeColors.moka,
                        ),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 60,
                      color: CoffeeColors.latteCream,
                      child: const Icon(
                        Icons.movie_rounded,
                        size: 20,
                        color: CoffeeColors.moka,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: CoffeeColors.caramelBronze,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Film dans le brouillon',
                        style: const TextStyle(
                          fontFamily: 'RecoletaAlt',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CoffeeColors.caramelBronze,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movieTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CoffeeColors.espresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ajoutez un message puis envoyez',
                    style: TextStyle(
                      fontFamily: 'RecoletaAlt',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CoffeeColors.moka,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _clearDraftMovie,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: CoffeeColors.latteCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: CoffeeColors.caramelBronze,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// MESSAGE BUBBLE - Design Premium
/// =============================================================================

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isSentByMe;
  final DateTime timestamp;
  final int? movieId;
  final String? movieTitle;
  final String? moviePoster;
  final String? otherUsername;
  final bool showAvatar;
  final List<Color> avatarGradient;

  const _MessageBubble({
    required this.content,
    required this.isSentByMe,
    required this.timestamp,
    this.movieId,
    this.movieTitle,
    this.moviePoster,
    this.otherUsername,
    this.showAvatar = true,
    this.avatarGradient = const [
      CoffeeColors.terracotta,
      CoffeeColors.caramelBronze,
    ],
  });

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}j';

    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTimestamp(timestamp);

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar && !isSentByMe ? 8 : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            // Avatar ou espace
            if (showAvatar)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: avatarGradient[0],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    otherUsername?.isNotEmpty == true
                        ? otherUsername![0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 30),
            const SizedBox(width: 8),
          ],
          // Bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isSentByMe ? 52 : 0,
                right: isSentByMe ? 0 : 52,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? const Color(0xFF4A3529)
                    : CoffeeColors.latteCream,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 18),
                ),
                border: isSentByMe
                    ? null
                    : Border.all(
                        color: CoffeeColors.steamMilk.withValues(alpha: 0.6),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isSentByMe
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.textPrimary.withValues(alpha: 0.04),
                    blurRadius: isSentByMe ? 12 : 8,
                    offset: const Offset(0, 3),
                    spreadRadius: isSentByMe ? -2 : -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Movie card if message has movie data
                  if (movieId != null && movieId! > 0) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(
                              tmdbId: movieId!,
                              posterUrl: moviePoster,
                              title: movieTitle,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSentByMe
                                ? Colors.white.withValues(alpha: 0.2)
                                : CoffeeColors.creamBorder,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (moviePoster != null &&
                                  moviePoster!.isNotEmpty)
                                Image.network(
                                  moviePoster!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    color: isSentByMe
                                        ? Colors.white12
                                        : CoffeeColors.steamMilk,
                                    child: Center(
                                      child: Icon(
                                        Icons.movie_rounded,
                                        color: isSentByMe
                                            ? Colors.white54
                                            : CoffeeColors.moka,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  color: isSentByMe
                                      ? Colors.white12
                                      : CoffeeColors.steamMilk,
                                  child: Center(
                                    child: Icon(
                                      Icons.movie_rounded,
                                      size: 36,
                                      color: isSentByMe
                                          ? Colors.white54
                                          : CoffeeColors.moka,
                                    ),
                                  ),
                                ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                color: isSentByMe
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : CoffeeColors.latteCream,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.movie_rounded,
                                      size: 14,
                                      color: isSentByMe
                                          ? Colors.white70
                                          : CoffeeColors.caramelBronze,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        movieTitle ?? 'Voir le film',
                                        style: GoogleFonts.dmSans(
                                          color: isSentByMe
                                              ? Colors.white
                                              : CoffeeColors.espresso,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 12,
                                      color: isSentByMe
                                          ? Colors.white54
                                          : CoffeeColors.moka,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (content.isNotEmpty)
                    Text(
                      content,
                      style: GoogleFonts.dmSans(
                        color: isSentByMe ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  if (timeText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      timeText,
                      style: GoogleFonts.dmSans(
                        color: isSentByMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
