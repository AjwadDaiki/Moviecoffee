import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_ui_components.dart';

/// Header de la collection avec recherche et tri
class CollectionHeader extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String sortBy;
  final Function(String) onSortChanged;

  const CollectionHeader({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Ma Collection",
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coffeeDark.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Rechercher un film...",
                hintStyle: GoogleFonts.dmSans(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.accentOrange,
                  size: 24,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => onSearchChanged(""),
                        color: Colors.grey[600],
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Options de tri
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                "Trier par:",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 10),
              _buildSortChip("Date", sortBy == "date"),
              const SizedBox(width: 8),
              _buildSortChip("Note", sortBy == "rating"),
              const SizedBox(width: 8),
              _buildSortChip("Titre", sortBy == "title"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => onSortChanged(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
