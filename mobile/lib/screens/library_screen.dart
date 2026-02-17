import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';
import '../models/movie.dart';
import '../theme/coffee_colors.dart';
import '../services/collection_notifier.dart';

/// =============================================================================
/// LIBRARY SCREEN - Recherche globale + Noter sans swiper
/// =============================================================================

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Movie> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final movies = await _apiService.searchMovies(query);
      if (mounted) {
        setState(() {
          _searchResults = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _openRatingModal(Movie movie) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickRateModal(
        movie: movie,
        onRated: () {
          collectionNotifier.notifyCollectionChanged();
        },
      ),
    );
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
        title: const Text(
          'Bibliothèque',
          style: TextStyle(
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
              onChanged: _searchMovies,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher un film à noter...',
                hintStyle: const TextStyle(color: CoffeeColors.moka),
                prefixIcon: const Icon(Icons.search, color: CoffeeColors.moka),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: CoffeeColors.moka),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
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

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_rounded,
        title: 'Rechercher un film',
        subtitle: 'Trouvez et notez n\'importe quel film',
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucun résultat',
        subtitle: 'Essayez avec un autre titre',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        return _MovieCard(movie: movie, onTap: () => _openRatingModal(movie));
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
/// MOVIE CARD
/// =============================================================================

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

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
                    movie.title.display,
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

            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CoffeeColors.caramelBronze.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: CoffeeColors.caramelBronze,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// QUICK RATE MODAL
/// =============================================================================

class _QuickRateModal extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onRated;

  const _QuickRateModal({required this.movie, this.onRated});

  @override
  State<_QuickRateModal> createState() => _QuickRateModalState();
}

class _QuickRateModalState extends State<_QuickRateModal> {
  final _apiService = ApiService();
  double _rating = 3.5;
  final _commentController = TextEditingController();
  bool _isSaving = false;
  String _selectedAction = "SEEN"; // SEEN, LIKE, DISLIKE

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveRating() async {
    setState(() => _isSaving = true);

    try {
      await _apiService.sendActionV3(
        widget.movie.tmdbId,
        _selectedAction,
        rating: _selectedAction == "SEEN" ? _rating : null,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onRated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedAction == "SEEN"
                  ? 'Film noté avec succès !'
                  : _selectedAction == "LIKE"
                  ? 'Ajouté à votre liste !'
                  : 'Noté comme "Pas intéressé"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CoffeeColors.steamMilk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Poster + Title
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.movie.posterPath,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 120,
                        color: CoffeeColors.steamMilk,
                        child: const Icon(Icons.movie_rounded),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title.display,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                          color: CoffeeColors.espresso,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: CoffeeColors.caramelBronze,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.movie.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CoffeeColors.espresso,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action selector
            const Text(
              'Action',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CoffeeColors.espresso,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionChip(
                  label: 'Vu',
                  icon: Icons.check_circle,
                  isSelected: _selectedAction == "SEEN",
                  onTap: () => setState(() => _selectedAction = "SEEN"),
                ),
                const SizedBox(width: 12),
                _ActionChip(
                  label: 'À voir',
                  icon: Icons.bookmark,
                  isSelected: _selectedAction == "LIKE",
                  onTap: () => setState(() => _selectedAction = "LIKE"),
                ),
                const SizedBox(width: 12),
                _ActionChip(
                  label: 'Pas intéressé',
                  icon: Icons.close,
                  isSelected: _selectedAction == "DISLIKE",
                  onTap: () => setState(() => _selectedAction = "DISLIKE"),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rating (only if SEEN)
            if (_selectedAction == "SEEN") ...[
              const Text(
                'Votre note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CoffeeColors.espresso,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'RecoletaAlt',
                      color: CoffeeColors.caramelBronze,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    size: 32,
                    color: CoffeeColors.caramelBronze,
                  ),
                ],
              ),
              Slider(
                value: _rating,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                activeColor: CoffeeColors.caramelBronze,
                inactiveColor: CoffeeColors.steamMilk,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 16),
            ],

            // Comment
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Commentaire (optionnel)...',
                hintStyle: const TextStyle(color: CoffeeColors.moka),
                filled: true,
                fillColor: CoffeeColors.latteCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoffeeColors.caramelBronze,
                  disabledBackgroundColor: CoffeeColors.steamMilk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedAction == "SEEN"
                            ? 'Noter ce film'
                            : _selectedAction == "LIKE"
                            ? 'Ajouter à ma liste'
                            : 'Marquer comme non intéressé',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                          color: Colors.white,
                        ),
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
/// ACTION CHIP
/// =============================================================================

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      CoffeeColors.caramelBronze,
                      CoffeeColors.terracotta,
                    ],
                  )
                : null,
            color: isSelected ? null : CoffeeColors.latteCream,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: CoffeeColors.steamMilk, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : CoffeeColors.moka,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : CoffeeColors.espresso,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
