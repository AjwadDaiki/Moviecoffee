import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../theme/coffee_colors.dart';
import '../../screens/search_screen.dart';
import '../../screens/user_profile_screen.dart';

/// =============================================================================
/// DUO SYSTEM CARD - Système de partenaire privilégié
/// =============================================================================

class DuoSystemCard extends StatefulWidget {
  final String? currentPartner;
  final VoidCallback? onPartnerChanged;

  const DuoSystemCard({
    super.key,
    this.currentPartner,
    this.onPartnerChanged,
  });

  @override
  State<DuoSystemCard> createState() => _DuoSystemCardState();
}

class _DuoSystemCardState extends State<DuoSystemCard> {
  final _apiService = ApiService();
  Map<String, dynamic>? _partnerData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentPartner != null) {
      _loadPartnerData();
    }
  }

  @override
  void didUpdateWidget(covariant DuoSystemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPartner != widget.currentPartner && widget.currentPartner != null) {
      _loadPartnerData();
    }
  }

  Future<void> _loadPartnerData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getPartnerStatus();
      if (mounted && data != null) {
        setState(() {
          _partnerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unlinkPartner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Délier le Duo ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre lien Duo ? '
          'Vos statistiques communes seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Délier'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.unlinkPartner();
        if (mounted) {
          widget.onPartnerChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duo délié avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _selectPartner() async {
    final selectedUsername = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(initialTab: 1, selectMode: true),
      ),
    );

    if (selectedUsername != null && selectedUsername.isNotEmpty && mounted) {
      try {
        await _apiService.linkPartner(selectedUsername);
        if (mounted) {
          widget.onPartnerChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duo créé avec $selectedUsername !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CoffeeColors.caramelBronze.withValues(alpha: 0.15),
            CoffeeColors.terracotta.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CoffeeColors.caramelBronze.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: widget.currentPartner == null
          ? _buildNoDuo()
          : _buildDuoActive(),
    );
  }

  Widget _buildNoDuo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoffeeColors.caramelBronze.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline,
            size: 48,
            color: CoffeeColors.caramelBronze,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Créez votre Duo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'RecoletaAlt',
            color: CoffeeColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Liez-vous avec un ami pour comparer vos stats et découvrir vos films en commun',
          style: TextStyle(
            fontSize: 14,
            color: CoffeeColors.moka,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _selectPartner,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text(
              'Choisir mon Duo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'RecoletaAlt',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeeColors.caramelBronze,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuoActive() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final compatibility = _partnerData?['compatibility'] ?? 0;
    final commonMovies = _partnerData?['common_movies_count'] ?? 0;
    final totalMatches = _partnerData?['total_matches'] ?? 0;

    return Column(
      children: [
        // Header avec avatars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar('Vous', true),
            const SizedBox(width: 16),
            const Icon(
              Icons.favorite,
              color: CoffeeColors.caramelBronze,
              size: 32,
            ),
            const SizedBox(width: 16),
            _buildAvatar(widget.currentPartner!, false),
          ],
        ),
        const SizedBox(height: 20),

        // Titre
        Text(
          'Duo avec ${widget.currentPartner}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'RecoletaAlt',
            color: CoffeeColors.espresso,
          ),
        ),
        const SizedBox(height: 20),

        // Stats
        Row(
          children: [
            _buildStatBadge(
              icon: Icons.favorite,
              value: '$compatibility%',
              label: 'Compatibilité',
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              icon: Icons.movie_rounded,
              value: '$commonMovies',
              label: 'Films communs',
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              icon: Icons.stars_rounded,
              value: '$totalMatches',
              label: 'Matchs',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _unlinkPartner,
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Délier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoffeeColors.espresso,
                  side: const BorderSide(
                    color: CoffeeColors.steamMilk,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.currentPartner == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        username: widget.currentPartner!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person, size: 18),
                label: const Text('Voir profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoffeeColors.caramelBronze,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(String label, bool isMe) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isMe
                ? CoffeeColors.caramelBronze
                : CoffeeColors.terracotta,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'RecoletaAlt',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CoffeeColors.espresso.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: CoffeeColors.caramelBronze, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'RecoletaAlt',
                color: CoffeeColors.espresso,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: CoffeeColors.moka,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
