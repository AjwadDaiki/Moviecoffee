import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_service.dart';
import 'models/movie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = ApiService().fetchFeed(); // On charge les films au démarrage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Erreur de connexion au serveur Python 🐍", style: TextStyle(color: Colors.white)));
          }

          final movies = snapshot.data!;

          return Column(
            children: [
              // --- ZONE DE SWIPE (80% de l'écran) ---
              Expanded(
                child: CardSwiper(
                  controller: controller,
                  cardsCount: movies.length,
                  numberOfCardsDisplayed: 3,
                  backCardOffset: const Offset(0, 40),
                  padding: const EdgeInsets.all(24.0),
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    final movie = movies[index];
                    return _buildMovieCard(movie);
                  },
                ),
              ),

              // --- ZONE DE BOUTONS (Les 4 actions) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionBtn(Icons.arrow_downward, Colors.blue, () => controller.swipe(CardSwiperDirection.bottom)), // Watchlist
                    _actionBtn(Icons.close, Colors.red, () => controller.swipe(CardSwiperDirection.left)), // Dislike
                    _actionBtn(Icons.star, Colors.amber, () => controller.swipe(CardSwiperDirection.top)), // Super Like
                    _actionBtn(Icons.favorite, Colors.green, () => controller.swipe(CardSwiperDirection.right)), // Like
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Design de la Carte
  Widget _buildMovieCard(Movie movie) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Image de fond
          CachedNetworkImage(
            imageUrl: movie.posterPath,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[900]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          // 2. Dégradé noir en bas pour lire le texte
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF2D2420)],
                stops: [0.6, 1.0],
              ),
            ),
          ),
          // 3. Textes et Logos
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title.display,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  movie.overview.display,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                if (movie.genres.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: movie.genres.take(3).map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Bouton rond stylé
  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
