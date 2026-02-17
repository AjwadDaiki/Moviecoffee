import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import '../auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/coffee_colors.dart';
import '../services/app_i18n.dart';
import '../services/app_language.dart';
import '../services/app_preferences.dart';

/// =============================================================================
/// SETTINGS SCREEN - Parametres complets
/// =============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();
  static const Map<String, IconData> _avatarPresets = {
    'coffee': Icons.local_cafe_rounded,
    'movie': Icons.movie_creation_rounded,
    'popcorn': Icons.local_movies_rounded,
    'star': Icons.auto_awesome_rounded,
    'camera': Icons.videocam_rounded,
  };
  static const Map<String, String> _supportedLanguages = {
    'fr': 'Francais',
    'en': 'English',
    'es': 'Espanol',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Portugues',
  };

  // Profile data
  String _username = '';
  String _email = '';
  String _bio = '';
  String _avatarUrl = '';
  String _avatarPreset = 'coffee';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _askSeenRatingPrompt = true;
  String _preferredLanguage = 'fr';
  bool _emailVerified = false;
  bool _isEmailVerificationLoading = false;
  bool _isLetterboxdLoading = false;
  bool _isLetterboxdSyncing = false;
  String? _letterboxdUsername;
  String? _letterboxdLastSyncStatus;
  String? _letterboxdLastSyncAt;
  String? _letterboxdLastSyncError;
  Map<String, dynamic>? _letterboxdLatestJob;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPreferences();
    _loadLetterboxdStatus();
  }

  Future<void> _loadPreferences() async {
    final notifications = await AppPreferences.getNotificationsEnabled();
    final askSeenRating = await AppPreferences.getAskSeenRating();
    final avatarPreset = await AppPreferences.getAvatarPreset();
    final preferredLanguage = await AppPreferences.getPreferredLanguage();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications;
      _askSeenRatingPrompt = askSeenRating;
      _preferredLanguage = _supportedLanguages.containsKey(preferredLanguage)
          ? preferredLanguage
          : 'fr';
      _avatarPreset = _avatarPresets.containsKey(avatarPreset)
          ? avatarPreset
          : 'coffee';
    });
    AppLanguage.setLanguage(_preferredLanguage);
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      if (profile != null && mounted) {
        final username = profile['user']?['username'] ?? '';
        final preferredLanguageRaw =
            (profile['user']?['preferred_language'] ?? '').toString();
        final normalizedLanguage =
            _supportedLanguages.containsKey(preferredLanguageRaw)
            ? preferredLanguageRaw
            : null;
        final askSeenFromApi = profile['user']?['ask_seen_rating_prompt'];
        final emailVerifiedFromApi = profile['user']?['email_verified'];
        if (username.toString().trim().isNotEmpty) {
          await AppPreferences.setCurrentUsername(username.toString());
        }
        if (normalizedLanguage != null) {
          await AppPreferences.setPreferredLanguage(normalizedLanguage);
        }
        if (askSeenFromApi is bool) {
          await AppPreferences.setAskSeenRating(askSeenFromApi);
        }
        setState(() {
          _username = username;
          _email = profile['user']?['email'] ?? '';
          _bio = profile['user']?['bio'] ?? '';
          _avatarUrl = profile['user']?['avatar_url'] ?? '';
          _preferredLanguage = normalizedLanguage ?? _preferredLanguage;
          if (askSeenFromApi is bool) {
            _askSeenRatingPrompt = askSeenFromApi;
          }
          _emailVerified = emailVerifiedFromApi == true;
          _isLoading = false;
        });
        AppLanguage.setLanguage(_preferredLanguage);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLetterboxdStatus({bool showErrors = false}) async {
    setState(() => _isLetterboxdLoading = true);
    try {
      final status = await _apiService.getLetterboxdStatus();
      if (!mounted) return;
      if (status == null) {
        setState(() => _isLetterboxdLoading = false);
        return;
      }
      setState(() {
        _isLetterboxdLoading = false;
        _letterboxdUsername = status['username'] as String?;
        _letterboxdLastSyncStatus = status['last_sync_status'] as String?;
        _letterboxdLastSyncAt = status['last_sync_at'] as String?;
        _letterboxdLastSyncError = status['last_sync_error'] as String?;
        _letterboxdLatestJob = status['latest_job'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLetterboxdLoading = false);
      if (showErrors) {
        _showSnackBar('Erreur Letterboxd: $e', isError: true);
      }
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
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppI18n.t('settings.title', fallback: 'Parametres'),
          style: AppTheme.titleMedium,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // === PROFIL ===
                _buildSectionHeader(
                  AppI18n.t('settings.section.profile', fallback: 'Profil'),
                  Icons.person_outline_rounded,
                ),
                _buildProfileCard(),

                const SizedBox(height: 24),

                // === COMPTE ===
                _buildSectionHeader(
                  AppI18n.t('settings.section.account', fallback: 'Compte'),
                  Icons.lock_outline_rounded,
                ),
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Adresse email',
                  subtitle: _emailVerified
                      ? '$_email • Verifie'
                      : '$_email • Non verifie',
                  onTap: null, // Read-only for now
                ),
                _buildSettingsTile(
                  icon: _emailVerified
                      ? Icons.verified_rounded
                      : Icons.mark_email_unread_outlined,
                  title: _emailVerified
                      ? 'Email verifie'
                      : 'Verifier mon email',
                  subtitle: _emailVerified
                      ? 'Votre compte est valide'
                      : 'Recevoir un lien de verification',
                  onTap: _emailVerified || _isEmailVerificationLoading
                      ? null
                      : _requestEmailVerification,
                  trailing: _isEmailVerificationLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        )
                      : null,
                ),
                _buildSettingsTile(
                  icon: Icons.key_rounded,
                  title: 'Changer le mot de passe',
                  subtitle: 'Modifier votre mot de passe',
                  onTap: _showChangePasswordDialog,
                ),

                const SizedBox(height: 24),

                // === APP ===
                _buildSectionHeader(
                  AppI18n.t('settings.section.app', fallback: 'Application'),
                  Icons.tune_rounded,
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: AppI18n.t(
                    'settings.notifications',
                    fallback: 'Notifications',
                  ),
                  subtitle: 'Matchs, messages, amis',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await AppPreferences.setNotificationsEnabled(value);
                    },
                    activeThumbColor: AppTheme.accent,
                    activeTrackColor: AppTheme.accent.withValues(alpha: 0.35),
                  ),
                ),
                _buildSettingsTile(
                  icon: Icons.star_rate_rounded,
                  title: "Demander une note apres 'Deja vu'",
                  subtitle: "Dans l'ecran Decouvrir",
                  trailing: Switch.adaptive(
                    value: _askSeenRatingPrompt,
                    onChanged: (value) async {
                      setState(() => _askSeenRatingPrompt = value);
                      await AppPreferences.setAskSeenRating(value);
                      try {
                        await _apiService.updateProfile(
                          askSeenRatingPrompt: value,
                        );
                      } catch (_) {}
                      if (!mounted) return;
                      _showSnackBar(
                        value
                            ? "Demande de note activee."
                            : "Demande de note desactivee.",
                      );
                    },
                    activeThumbColor: AppTheme.accent,
                    activeTrackColor: AppTheme.accent.withValues(alpha: 0.35),
                  ),
                ),
                _buildLetterboxdCard(),
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: AppI18n.t('settings.language', fallback: 'Langue'),
                  subtitle:
                      _supportedLanguages[_preferredLanguage] ?? 'Francais',
                  onTap: _showLanguageSheet,
                ),
                _buildSettingsTile(
                  icon: Icons.add_a_photo_rounded,
                  title: 'Photo perso',
                  subtitle: 'Bientot disponible (upload personnalise)',
                  onTap: null,
                ),
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Personnalisation couleurs',
                  subtitle: 'Bientot disponible',
                  onTap: null,
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                ),

                const SizedBox(height: 24),

                // === DANGER ZONE ===
                _buildSectionHeader(
                  AppI18n.t(
                    'settings.section.danger',
                    fallback: 'Zone de danger',
                  ),
                  Icons.warning_amber_rounded,
                ),
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: AppI18n.t(
                    'settings.logout',
                    fallback: 'Se deconnecter',
                  ),
                  subtitle: 'Deconnexion de votre compte',
                  iconColor: Colors.orange,
                  onTap: _confirmLogout,
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Supprimer le compte',
                  subtitle: 'Cette action est irreversible',
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
              // Avatar preset
              GestureDetector(
                onTap: _showAvatarPresetSheet,
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
                                  child: Icon(
                                    _avatarPresets[_avatarPreset] ??
                                        Icons.local_cafe_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                _avatarPresets[_avatarPreset] ??
                                    Icons.local_cafe_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                    ),
                    // Preset badge
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
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
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
                      Text('Aucune bio', style: AppTheme.caption),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Icones de profil',
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _avatarPresets.entries.map((entry) {
              final isSelected = entry.key == _avatarPreset;
              return GestureDetector(
                onTap: () => _setAvatarPreset(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.2)
                        : AppTheme.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    entry.value,
                    color: isSelected ? AppTheme.accent : AppTheme.accentDark,
                    size: 20,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Photo personnalisee: bientot disponible.',
              style: AppTheme.caption,
            ),
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

  Future<void> _setAvatarPreset(String key) async {
    if (!_avatarPresets.containsKey(key)) return;
    await AppPreferences.setAvatarPreset(key);
    if (!mounted) return;
    setState(() {
      _avatarPreset = key;
      // Keep remote avatar only if user uploaded one explicitly.
      // Preset selection is local and takes priority when no uploaded photo.
      if (_avatarUrl.trim().isEmpty) {
        _avatarUrl = '';
      }
    });
  }

  void _showAvatarPresetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choisir une icone', style: AppTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _avatarPresets.entries.map((entry) {
                    final isSelected = entry.key == _avatarPreset;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await _setAvatarPreset(entry.key);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accent.withValues(alpha: 0.2)
                              : AppTheme.accentSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accent
                                : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.accentDark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Photo personnalisee: bientot disponible.',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestEmailVerification() async {
    if (_isEmailVerificationLoading || _emailVerified) return;
    setState(() => _isEmailVerificationLoading = true);
    try {
      final response = await _apiService.requestEmailVerification();
      if (!mounted) return;
      final maybeToken = (response?['verify_token'] ?? '').toString().trim();
      if (maybeToken.isNotEmpty) {
        _showEmailTokenDialog(maybeToken);
      } else {
        _showSnackBar('Lien de verification envoye (si email configure).');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur verification email: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isEmailVerificationLoading = false);
      }
    }
  }

  void _showEmailTokenDialog(String token) {
    final controller = TextEditingController(text: token);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Token verification (dev)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ce token n'apparait qu'en mode dev. Collez-le pour valider l'email.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Token',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(ctx);
              await _confirmEmailToken(value);
            },
            child: const Text('Verifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmailToken(String token) async {
    try {
      final response = await _apiService.verifyEmail(token);
      if (!mounted) return;
      if (response?['email_verified'] == true) {
        setState(() => _emailVerified = true);
        _showSnackBar('Email verifie avec succes.');
      } else {
        _showSnackBar('Verification email terminee.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Token invalide ou expire: $e', isError: true);
    }
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppI18n.t(
                    'settings.choose_language',
                    fallback: 'Choisir la langue',
                  ),
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._supportedLanguages.entries.map((entry) {
                  final selected = entry.key == _preferredLanguage;
                  return ListTile(
                    onTap: () async {
                      Navigator.pop(context);
                      await _setPreferredLanguage(entry.key);
                    },
                    leading: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? AppTheme.accent : AppTheme.textTertiary,
                    ),
                    title: Text(entry.value, style: AppTheme.bodyLarge),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setPreferredLanguage(String code) async {
    final normalized = code.trim().toLowerCase();
    if (!_supportedLanguages.containsKey(normalized)) return;
    if (normalized == _preferredLanguage) return;

    await AppPreferences.setPreferredLanguage(normalized);
    AppLanguage.setLanguage(normalized);
    if (!mounted) return;
    setState(() => _preferredLanguage = normalized);

    try {
      await _apiService.updateProfile(preferredLanguage: normalized);
      if (!mounted) return;
      _showSnackBar(
        AppI18n.t('settings.language_updated', fallback: 'Langue mise a jour.'),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        AppI18n.t(
          'settings.language_sync_pending',
          fallback: 'Langue locale mise a jour, sync serveur en attente.',
        ),
      );
    }
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
            style: AppTheme.labelLarge.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterboxdCard() {
    final connected = (_letterboxdUsername ?? '').trim().isNotEmpty;
    final syncStatus = (_letterboxdLastSyncStatus ?? '').toLowerCase();
    Map<String, dynamic> asMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      return const {};
    }

    final latestJob = _letterboxdLatestJob;
    final latestDiagnosticsText = asMap(latestJob?['diagnostics_text']);
    final watchedStopReason =
        (latestDiagnosticsText['watched_stop_reason'] ?? '').toString().trim();
    final showWarningStopReason =
        watchedStopReason.isNotEmpty &&
        watchedStopReason != 'max_items_reached' &&
        watchedStopReason != 'completed' &&
        watchedStopReason != 'completed_via_html' &&
        watchedStopReason != 'completed_with_films';
    final watchedStatusChain =
        (latestDiagnosticsText['watched_last_status_chain'] ?? '')
            .toString()
            .trim();
    final watchedScanned =
        ((latestJob?['watched_scanned_items'] as num?) ??
                (latestJob?['scanned_items'] as num?) ??
                0)
            .toInt();
    final watchlistScanned =
        ((latestJob?['watchlist_scanned_items'] as num?) ?? 0).toInt();
    final importedCount = ((latestJob?['imported_items'] as num?) ?? 0).toInt();
    final updatedCount = ((latestJob?['updated_items'] as num?) ?? 0).toInt();
    final skippedCount = ((latestJob?['skipped_items'] as num?) ?? 0).toInt();

    Color statusColor = AppTheme.textSecondary;
    String statusLabel = connected ? 'Connecte' : 'Non connecte';
    if (syncStatus == 'completed') {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Synchronisation terminee';
    } else if (syncStatus == 'failed') {
      statusColor = Colors.red.shade700;
      statusLabel = 'Synchronisation en erreur';
    } else if (syncStatus == 'queued') {
      statusColor = CoffeeColors.caramelBronze;
      statusLabel = 'Synchronisation en file';
    } else if (syncStatus == 'running') {
      statusColor = CoffeeColors.caramelBronze;
      statusLabel = 'Synchronisation en cours';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3529).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  size: 18,
                  color: Color(0xFF4A3529),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integration Letterboxd',
                      style: AppTheme.labelLarge.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connected
                          ? '@${_letterboxdUsername ?? ''}'
                          : 'Connectez votre compte pour importer vos films',
                      style: AppTheme.caption.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLetterboxdLoading)
            const LinearProgressIndicator(minHeight: 3, color: AppTheme.accent)
          else ...[
            Row(
              children: [
                Text(
                  statusLabel,
                  style: AppTheme.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if ((_letterboxdLastSyncAt ?? '').isNotEmpty)
                  Text(
                    _formatSyncTime(_letterboxdLastSyncAt),
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
              ],
            ),
            if (latestJob != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3529).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF4A3529).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$watchedScanned vus | $watchlistScanned watchlist',
                      style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3529),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$importedCount importes | $updatedCount maj | $skippedCount ignores',
                      style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3529),
                      ),
                    ),
                    if (showWarningStopReason) ...[
                      const SizedBox(height: 4),
                      Text(
                        watchedStatusChain.isEmpty
                            ? 'Arret flux: $watchedStopReason'
                            : 'Arret flux: $watchedStopReason ($watchedStatusChain)',
                        style: AppTheme.caption.copyWith(
                          fontSize: 10.5,
                          color: const Color(0xFF6A4F3D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if ((_letterboxdLastSyncError ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _letterboxdLastSyncError!,
                  style: AppTheme.caption.copyWith(
                    fontSize: 11,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!connected)
                Expanded(
                  child: _buildIntegrationAction(
                    icon: Icons.link_rounded,
                    label: 'Connecter',
                    color: const Color(0xFF4A3529),
                    onTap: _showLetterboxdConnectDialog,
                  ),
                ),
              if (connected) ...[
                Expanded(
                  child: _buildIntegrationAction(
                    icon: Icons.download_rounded,
                    label: _isLetterboxdSyncing
                        ? 'En cours...'
                        : 'Synchroniser',
                    color: CoffeeColors.caramelBronze,
                    onTap: _isLetterboxdSyncing ? null : _syncLetterboxd,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildIntegrationAction(
                    icon: Icons.link_off_rounded,
                    label: 'Deconnecter',
                    color: Colors.red.shade600,
                    onTap: _disconnectLetterboxd,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSyncTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m $h:$min';
    } catch (_) {
      return '';
    }
  }

  void _showLetterboxdConnectDialog() {
    final controller = TextEditingController(text: _letterboxdUsername ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Connecter Letterboxd', style: AppTheme.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'username Letterboxd',
            prefixText: '@',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isEmpty) return;
              Navigator.pop(dialogContext);
              await _connectLetterboxd(username);
            },
            child: const Text('Connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectLetterboxd(String username) async {
    setState(() => _isLetterboxdLoading = true);
    try {
      await _apiService.connectLetterboxd(username);
      if (!mounted) return;
      _showSnackBar('Compte Letterboxd connecte');
      await _loadLetterboxdStatus(showErrors: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLetterboxdLoading = false);
      _showSnackBar('Connexion Letterboxd impossible: $e', isError: true);
    }
  }

  Future<void> _syncLetterboxd() async {
    if (_isLetterboxdSyncing) return;
    setState(() => _isLetterboxdSyncing = true);
    try {
      final response = await _apiService.syncLetterboxd(
        maxItems: 5000,
        watchlistMaxItems: 5000,
      );
      if (!mounted) return;
      final status = (response?['status'] ?? '').toString().toLowerCase();
      if (status == 'already_running') {
        _showSnackBar('Synchronisation deja en cours.');
      } else {
        _showSnackBar(
          'Synchronisation lancee. Revenez dans quelques secondes.',
        );
      }
      await Future.delayed(const Duration(milliseconds: 700));
      await _loadLetterboxdStatus(showErrors: true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur de synchronisation: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLetterboxdSyncing = false);
      }
    }
  }

  Future<void> _disconnectLetterboxd() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Deconnecter Letterboxd', style: AppTheme.titleMedium),
        content: const Text(
          'Vous pourrez reconnecter ce compte a tout moment depuis cet ecran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Deconnecter',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (shouldDisconnect != true) return;
    try {
      final ok = await _apiService.disconnectLetterboxd();
      if (!mounted) return;
      if (!ok) {
        _showSnackBar('Deconnexion impossible', isError: true);
        return;
      }
      _showSnackBar('Compte Letterboxd deconnecte');
      await _loadLetterboxdStatus(showErrors: true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur deconnexion: $e', isError: true);
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
            hintStyle: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textTertiary,
            ),
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
          style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
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
                if (isUsername) {
                  await AppPreferences.setCurrentUsername(value);
                }
                setState(() {
                  if (isUsername) _username = result['username'] ?? value;
                  if (!isUsername) _bio = result['bio'] ?? value;
                });
                _showSnackBar('Profil mis a jour');
              } else if (mounted) {
                _showSnackBar('Erreur lors de la mise a jour', isError: true);
              }
            },
            child: Text(
              'Enregistrer',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.accent),
            ),
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
            child: Text(
              'Annuler',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final current = currentController.text;
              final newPwd = newController.text;
              final confirm = confirmController.text;

              if (current.isEmpty || newPwd.isEmpty) {
                _showSnackBar(
                  'Veuillez remplir tous les champs',
                  isError: true,
                );
                return;
              }
              if (newPwd.length < 6) {
                _showSnackBar(
                  'Le mot de passe doit avoir au moins 6 caracteres',
                  isError: true,
                );
                return;
              }
              if (newPwd != confirm) {
                _showSnackBar(
                  'Les mots de passe ne correspondent pas',
                  isError: true,
                );
                return;
              }

              Navigator.pop(context);
              final result = await _apiService.changePassword(current, newPwd);
              if (result != null && mounted) {
                _showSnackBar('Mot de passe modifie');
              } else if (mounted) {
                _showSnackBar('Mot de passe actuel incorrect', isError: true);
              }
            },
            child: Text(
              'Modifier',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.accent),
            ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.textPrimary),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Se deconnecter', style: AppTheme.titleMedium),
        content: Text(
          'Voulez-vous vraiment vous deconnecter ?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthProvider>().logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Deconnexion',
              style: AppTheme.labelLarge.copyWith(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Supprimer le compte',
              style: AppTheme.titleMedium.copyWith(color: Colors.red),
            ),
          ],
        ),
        content: Text(
          'Cette action est irreversible. Toutes vos donnees, films, matchs et messages seront supprimes definitivement.',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _apiService.deleteAccount();
              if (!mounted) return;
              if (success) {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
                return;
              }
              _showSnackBar('Erreur lors de la suppression', isError: true);
            },
            child: Text(
              'Supprimer',
              style: AppTheme.labelLarge.copyWith(color: Colors.red),
            ),
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
