import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import '../auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/coffee_colors.dart';

/// =============================================================================
/// SETTINGS SCREEN - Paramètres complets
/// =============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();

  // Profile data
  String _username = '';
  String _email = '';
  String _bio = '';
  String _avatarUrl = '';
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _username = profile['user']?['username'] ?? '';
          _email = profile['user']?['email'] ?? '';
          _bio = profile['user']?['bio'] ?? '';
          _avatarUrl = profile['user']?['avatar_url'] ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Paramètres', style: AppTheme.titleMedium),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // === PROFIL ===
                _buildSectionHeader('Profil', Icons.person_outline_rounded),
                _buildProfileCard(),

                const SizedBox(height: 24),

                // === COMPTE ===
                _buildSectionHeader('Compte', Icons.lock_outline_rounded),
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Adresse email',
                  subtitle: _email,
                  onTap: null, // Read-only for now
                ),
                _buildSettingsTile(
                  icon: Icons.key_rounded,
                  title: 'Changer le mot de passe',
                  subtitle: 'Modifier votre mot de passe',
                  onTap: _showChangePasswordDialog,
                ),

                const SizedBox(height: 24),

                // === APP ===
                _buildSectionHeader('Application', Icons.tune_rounded),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Matchs, messages, amis',
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppTheme.accent,
                  ),
                ),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: null,
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                ),

                const SizedBox(height: 24),

                // === DANGER ZONE ===
                _buildSectionHeader('Zone de danger', Icons.warning_amber_rounded),
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Se déconnecter',
                  subtitle: 'Déconnexion de votre compte',
                  iconColor: Colors.orange,
                  onTap: _confirmLogout,
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Supprimer le compte',
                  subtitle: 'Cette action est irréversible',
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: _confirmDeleteAccount,
                ),

                const SizedBox(height: 100),
              ],
            ),
    );
  }

  // ===========================================================================
  // PROFILE CARD
  // ===========================================================================

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard(radius: 18),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with photo upload
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accentDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowAccent(AppTheme.accent),
                      ),
                      child: _avatarUrl.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _avatarUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: CoffeeColors.caramelBronze,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(4),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username, style: AppTheme.titleMedium),
                    if (_bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _bio,
                          style: AppTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        'Aucune bio',
                        style: AppTheme.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfileAction(
                  'Modifier le nom',
                  Icons.edit_rounded,
                  () => _showEditDialog('username', _username),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProfileAction(
                  'Modifier la bio',
                  Icons.short_text_rounded,
                  () => _showEditDialog('bio', _bio),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.labelLarge.copyWith(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SETTINGS TILE
  // ===========================================================================

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.accent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelLarge.copyWith(
                      fontSize: 14,
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: AppTheme.caption.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PHOTO UPLOAD
  // ===========================================================================

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final newUrl = await _apiService.uploadAvatar(image.path);
      if (newUrl != null && mounted) {
        setState(() {
          _avatarUrl = newUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo de profil mise à jour !'),
            backgroundColor: CoffeeColors.caramelBronze,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // DIALOGS
  // ===========================================================================

  void _showEditDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    final isUsername = field == 'username';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isUsername ? 'Modifier le nom' : 'Modifier la bio',
          style: AppTheme.titleMedium,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: isUsername ? 20 : 150,
          maxLines: isUsername ? 1 : 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: isUsername ? 'Nom d\'utilisateur' : 'Votre bio...',
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final value = controller.text.trim();
              if (value.isEmpty) return;

              final result = isUsername
                  ? await _apiService.updateProfile(username: value)
                  : await _apiService.updateProfile(bio: value);

              if (result != null && mounted) {
                setState(() {
                  if (isUsername) _username = result['username'] ?? value;
                  if (!isUsername) _bio = result['bio'] ?? value;
                });
                _showSnackBar('Profil mis à jour');
              } else if (mounted) {
                _showSnackBar('Erreur lors de la mise à jour', isError: true);
              }
            },
            child: Text('Enregistrer', style: AppTheme.labelLarge.copyWith(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Changer le mot de passe', style: AppTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(currentController, 'Mot de passe actuel'),
            const SizedBox(height: 12),
            _buildPasswordField(newController, 'Nouveau mot de passe'),
            const SizedBox(height: 12),
            _buildPasswordField(confirmController, 'Confirmer le nouveau'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final current = currentController.text;
              final newPwd = newController.text;
              final confirm = confirmController.text;

              if (current.isEmpty || newPwd.isEmpty) {
                _showSnackBar('Veuillez remplir tous les champs', isError: true);
                return;
              }
              if (newPwd.length < 6) {
                _showSnackBar('Le mot de passe doit avoir au moins 6 caractères', isError: true);
                return;
              }
              if (newPwd != confirm) {
                _showSnackBar('Les mots de passe ne correspondent pas', isError: true);
                return;
              }

              Navigator.pop(context);
              final result = await _apiService.changePassword(current, newPwd);
              if (result != null && mounted) {
                _showSnackBar('Mot de passe modifié');
              } else if (mounted) {
                _showSnackBar('Mot de passe actuel incorrect', isError: true);
              }
            },
            child: Text('Modifier', style: AppTheme.labelLarge.copyWith(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.textPrimary),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Se déconnecter', style: AppTheme.titleMedium),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Déconnexion', style: AppTheme.labelLarge.copyWith(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('Supprimer le compte', style: AppTheme.titleMedium.copyWith(color: Colors.red)),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Toutes vos données, films, matchs et messages seront supprimés définitivement.',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _apiService.deleteAccount();
              if (success && mounted) {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else if (mounted) {
                _showSnackBar('Erreur lors de la suppression', isError: true);
              }
            },
            child: Text('Supprimer', style: AppTheme.labelLarge.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
