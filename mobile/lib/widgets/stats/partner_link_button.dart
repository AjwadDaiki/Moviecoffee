import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../api_service.dart';

/// =============================================================================
/// PARTNER LINK BUTTON - Bouton pour lier/délier un partenaire
/// =============================================================================

class PartnerLinkButton extends StatelessWidget {
  final String? currentPartner;
  final VoidCallback onLinked;

  const PartnerLinkButton({
    super.key,
    this.currentPartner,
    required this.onLinked,
  });

  void _showPartnerModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PartnerModal(
        currentPartner: currentPartner,
        onLinked: onLinked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPartner = currentPartner != null && currentPartner != "Aucun";

    return GestureDetector(
      onTap: () => _showPartnerModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasPartner
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : AppTheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasPartner
                    ? AppTheme.accent.withValues(alpha: 0.5)
                    : AppTheme.border.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: hasPartner ? AppTheme.shadowAccent(AppTheme.accent) : AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: hasPartner
                        ? const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark])
                        : null,
                    color: hasPartner ? null : AppTheme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    hasPartner ? Icons.favorite_rounded : Icons.person_add_rounded,
                    color: hasPartner ? Colors.white : AppTheme.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPartner ? "Partenaire lié" : "Lier un partenaire",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                          color: hasPartner ? AppTheme.accent : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasPartner
                            ? "Lié avec $currentPartner"
                            : "Comparez vos goûts cinéma",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasPartner
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: hasPartner ? AppTheme.accent : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// PARTNER MODAL - Modal pour gérer le partenaire
/// =============================================================================

class _PartnerModal extends StatefulWidget {
  final String? currentPartner;
  final VoidCallback onLinked;

  const _PartnerModal({
    this.currentPartner,
    required this.onLinked,
  });

  @override
  State<_PartnerModal> createState() => _PartnerModalState();
}

class _PartnerModalState extends State<_PartnerModal> {
  final ApiService _api = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccess = false;

  bool get _hasPartner => widget.currentPartner != null && widget.currentPartner != "Aucun";

  @override
  void dispose() {
    _usernameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _linkPartner() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = "Entrez un nom d'utilisateur");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.linkPartner(username);
      if (mounted && result != null) {
        setState(() {
          _showSuccess = true;
          _isLoading = false;
        });

        // Fermer après un délai
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
          widget.onLinked();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _unlinkPartner() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _api.unlinkPartner();
      if (mounted && success) {
        Navigator.pop(context);
        widget.onLinked();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),

            // Contenu selon l'état
            if (_showSuccess)
              _buildSuccessState()
            else if (_hasPartner)
              _buildLinkedState()
            else
              _buildLinkForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]),
            shape: BoxShape.circle,
            boxShadow: AppTheme.shadowAccent(AppTheme.accent),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text("Partenaire lié !", style: AppTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Vous pouvez maintenant voir vos matchs",
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLinkedState() {
    return Column(
      children: [
        // Header
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        Text("Partenaire actuel", style: AppTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.currentPartner!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'RecoletaAlt',
              color: AppTheme.accent,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Erreur
        if (_errorMessage != null) ...[
          _buildErrorMessage(),
          const SizedBox(height: 16),
        ],

        // Bouton délier
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _unlinkPartner,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  )
                : const Icon(Icons.link_off_rounded, size: 20),
            label: Text(_isLoading ? "Déconnexion..." : "Délier ce partenaire"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton fermer
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text("Lier un partenaire", style: AppTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "Entrez le nom d'utilisateur de votre partenaire pour comparer vos goûts et découvrir vos matchs !",
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),

        // Champ de saisie
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _errorMessage != null ? Colors.red.shade300 : AppTheme.border,
              width: 2,
            ),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: TextField(
            controller: _usernameController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _linkPartner(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            decoration: InputDecoration(
              hintText: "Nom d'utilisateur",
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.accent),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        // Message d'erreur
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(),
        ],

        const SizedBox(height: 24),

        // Bouton valider
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _linkPartner,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              disabledBackgroundColor: AppTheme.border,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Lier ce partenaire",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RecoletaAlt',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
