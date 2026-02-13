import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../theme/coffee_colors.dart';
import '../widgets/community/friend_card.dart';
import 'movie_detail_screen.dart';
import 'user_profile_screen.dart';

/// =============================================================================
/// SEARCH SCREEN - Recherche films + utilisateurs
/// =============================================================================

class SearchScreen extends StatefulWidget {
  final int initialTab; // 0 = Films, 1 = Utilisateurs
  final bool
  usersOnly; // Si true, cache les tabs et montre seulement utilisateurs
  final bool
  selectMode; // Si true, tap sur un user retourne son username via pop
  final bool
  selectMovieMode; // Si true, tap sur un film retourne l'objet Movie via pop

  const SearchScreen({
    super.key,
    this.initialTab = 0,
    this.usersOnly = false,
    this.selectMode = false,
    this.selectMovieMode = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _searchController = TextEditingController();
  final _apiService = ApiService();

  // Films
  List<Movie> _movieResults = [];
  bool _isLoadingMovies = false;

  // Utilisateurs
  List<AppUser> _userResults = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    if (!widget.usersOnly) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.index = widget.initialTab;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().length < 2) {
      setState(() => _movieResults = []);
      return;
    }

    setState(() => _isLoadingMovies = true);

    try {
      final movies = await _apiService.searchMovies(query);
      if (mounted) {
        setState(() {
          _movieResults = movies;
          _isLoadingMovies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMovies = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _userResults = []);
      return;
    }

    setState(() => _isLoadingUsers = true);

    try {
      final result = await _apiService.searchUsers(query);
      if (mounted) {
        setState(() {
          _userResults = result;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _onSearchChanged(String query) {
    if (widget.usersOnly || (_tabController?.index ?? 1) == 1) {
      _searchUsers(query);
    } else {
      _searchMovies(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.latteCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoffeeColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.usersOnly ? 'Rechercher des amis' : 'Recherche',
          style: const TextStyle(
            color: CoffeeColors.espresso,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'RecoletaAlt',
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.usersOnly || (_tabController?.index ?? 1) == 1
                    ? 'Rechercher un utilisateur...'
                    : 'Rechercher un film...',
                hintStyle: const TextStyle(color: CoffeeColors.moka),
                prefixIcon: const Icon(Icons.search, color: CoffeeColors.moka),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: CoffeeColors.moka),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _movieResults = [];
                            _userResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: CoffeeColors.latteCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 15,
              ),
            ),
          ),

          // Tabs (seulement si pas en mode usersOnly)
          if (!widget.usersOnly && _tabController != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: CoffeeColors.caramelBronze,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: CoffeeColors.moka,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                onTap: (index) {
                  _searchController.clear();
                  setState(() {
                    _movieResults = [];
                    _userResults = [];
                  });
                },
                tabs: const [
                  Tab(text: 'Films'),
                  Tab(text: 'Utilisateurs'),
                ],
              ),
            ),

          // Content
          Expanded(
            child: widget.usersOnly
                ? _buildUsersTab()
                : TabBarView(
                    controller: _tabController,
                    children: [_buildMoviesTab(), _buildUsersTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesTab() {
    if (_isLoadingMovies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.movie_filter_rounded,
        title: 'Rechercher un film',
        subtitle: 'Entrez au moins 2 caractères',
      );
    }

    if (_movieResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucun résultat',
        subtitle: 'Essayez avec un autre titre',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _movieResults.length,
      itemBuilder: (context, index) {
        final movie = _movieResults[index];
        return _MovieSearchCard(
          movie: movie,
          onTap: widget.selectMovieMode
              ? () => Navigator.pop(context, movie)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(
                        tmdbId: movie.tmdbId,
                        posterUrl: movie.posterPath,
                        title: movie.title.fr,
                      ),
                    ),
                  );
                },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Rechercher des amis',
        subtitle: 'Trouvez des utilisateurs par leur pseudo',
      );
    }

    if (_userResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search_rounded,
        title: 'Aucun utilisateur trouvé',
        subtitle: 'Vérifiez l\'orthographe du pseudo',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FriendCard(
            username: user.username,
            bio: user.bio.isNotEmpty ? user.bio : null,
            totalSeen: user.totalSeen,
            level: user.level,
            isFriend: user.isFriend,
            requestSent: user.requestSent,
            requestReceived: user.requestReceived,
            onTap: () {
              if (widget.selectMode) {
                Navigator.pop(context, user.username);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserProfileScreen(username: user.username),
                  ),
                );
              }
            },
            onAcceptRequest: user.requestReceived
                ? () async {
                    await _apiService.acceptFriend(
                      user.id.isNotEmpty ? user.id : user.username,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${user.username} est maintenant votre ami!',
                        ),
                      ),
                    );
                    _searchUsers(_searchController.text);
                  }
                : null,
            onAddFriend:
                (!user.isFriend && !user.requestSent && !user.requestReceived)
                ? () async {
                    await _apiService.addFriend(user.username);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Demande envoyée à ${user.username}'),
                      ),
                    );
                    _searchUsers(_searchController.text);
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CoffeeColors.steamMilk.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: CoffeeColors.moka),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CoffeeColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: CoffeeColors.moka),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// MOVIE SEARCH CARD
/// =============================================================================

class _MovieSearchCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const _MovieSearchCard({required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                movie.posterPath,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 90,
                    color: CoffeeColors.steamMilk,
                    child: const Icon(
                      Icons.movie_rounded,
                      color: CoffeeColors.moka,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title.fr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RecoletaAlt',
                      color: CoffeeColors.espresso,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: CoffeeColors.caramelBronze,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CoffeeColors.espresso,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: CoffeeColors.moka,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.formattedRuntime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CoffeeColors.moka,
                        ),
                      ),
                    ],
                  ),
                  if (movie.genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      movie.genres.take(2).join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CoffeeColors.moka,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: CoffeeColors.steamMilk,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
