import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../api_service.dart';
import '../../services/collection_notifier.dart';
import '../app_ui_components.dart';

/// Modale pour noter et éditer un film
class EditRatingModal extends StatefulWidget {
  final Movie movie;
  final Function() onUpdated;

  const EditRatingModal({
    super.key,
    required this.movie,
    required this.onUpdated,
  });

  @override
  State<EditRatingModal> createState() => _EditRatingModalState();
}

class _EditRatingModalState extends State<EditRatingModal> {
  final ApiService _api = ApiService();
  late double _rating;
  late TextEditingController _commentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.movie.userRating ?? 0.0;
    _commentController = TextEditingController(
      text: widget.movie.userComment ?? "",
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveRating() async {
    if (_rating == 0) {
      _showErrorSnackbar("Veuillez sélectionner une note");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _api.sendActionV3(
        widget.movie.tmdbId,
        "RATE",
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        collectionNotifier.notifyCollectionChanged();
        widget.onUpdated();
        Navigator.pop(context);
        _showSuccessSnackbar("Note enregistrée avec succès");
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackbar(e.message);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle de drag
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              widget.movie.title.fr,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 30),

          // Section de notation par étoiles
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Votre note",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Étoiles interactives (demi-étoiles)
                  Center(
                    child: _HalfStarRating(
                      rating: _rating,
                      onRatingChanged: (value) {
                        setState(() => _rating = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Affichage de la note
                  Center(
                    child: Text(
                      _rating > 0
                          ? "${_rating.toStringAsFixed(1)} / 5.0"
                          : "Non notée",
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Commentaire optionnel
                  Text(
                    "Commentaire (optionnel)",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coffeeDark.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Partagez votre avis sur ce film...",
                        hintStyle: GoogleFonts.dmSans(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(15),
                      ),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton sauvegarder
          Padding(
            padding: const EdgeInsets.all(25),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Enregistrer la note",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'étoiles avec support demi-étoiles via tap gauche/droite
class _HalfStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const _HalfStarRating({required this.rating, required this.onRatingChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            final starWidth = 62.0; // 50 icon + 12 padding
            final starStart = index * starWidth;
            final tapInStar = localPos.dx - starStart;
            final isLeftHalf = tapInStar < starWidth / 2;
            final newRating = index + (isLeftHalf ? 0.5 : 1.0);
            onRatingChanged(newRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              index + 1 <= rating
                  ? Icons.star
                  : index + 0.5 <= rating
                  ? Icons.star_half
                  : Icons.star_border,
              size: 50,
              color: index + 0.5 <= rating ? Colors.amber : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}
