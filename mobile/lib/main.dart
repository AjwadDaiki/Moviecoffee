import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme/theme_provider.dart';
import 'widgets/common/animated_background.dart';
import 'auth_provider.dart';
import 'auth_screens.dart';
import 'services/app_language.dart';
import 'services/app_i18n.dart';
import 'screens/feed_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/community_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MoovieCoffeeApp(),
    ),
  );
}

class MoovieCoffeeApp extends StatelessWidget {
  const MoovieCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.listenable,
      builder: (context, languageCode, _) {
        return MaterialApp(
          key: ValueKey<String>('app-lang-$languageCode'),
          title: 'MoovieCoffee',
          debugShowCheckedModeBanner: false,
          locale: Locale(languageCode),
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
            Locale('es'),
            Locale('de'),
            Locale('it'),
            Locale('pt'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final value = await _storage.read(key: 'onboarding_complete');
    setState(() {
      _onboardingComplete = value == 'true';
      _isLoading = false;
    });
  }

  void _completeOnboarding() {
    setState(() {
      _onboardingComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = Provider.of<AuthProvider>(context);

    // Show onboarding first if not complete
    if (!_onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return auth.isAuthenticated ? const MainNavigation() : const AuthScreen();
  }
}

/// =============================================================================
/// MAIN NAVIGATION - Navigation principale avec bottom bar moderne
/// =============================================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Utiliser des clés pour garder l'état des écrans
  final _feedKey = GlobalKey<State>();
  final _collectionKey = GlobalKey<State>();
  final _communityKey = GlobalKey<State>();
  final _statsKey = GlobalKey<State>();

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            FeedScreen(key: _feedKey),
            CollectionScreen(key: _collectionKey),
            CommunityScreen(key: _communityKey),
            StatsScreen(key: _statsKey),
          ],
        ),
      ),
      bottomNavigationBar: _ModernNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

/// =============================================================================
/// MODERN NAV BAR - Barre de navigation moderne flottante
/// =============================================================================

class _ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ModernNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF2D1F14).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.style_rounded,
                  label: AppI18n.t('nav.feed', fallback: 'Feed'),
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.collections_bookmark_rounded,
                  label: AppI18n.t('nav.collection', fallback: 'Collection'),
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: AppI18n.t('nav.community', fallback: 'Community'),
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  label: AppI18n.t('nav.stats', fallback: 'Stats'),
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD6C2B4).withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? const Color(0xFFE7D7CB)
                    : const Color(0xFFCAB3A2),
                size: 24,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFE7D7CB)
                    : const Color(0xFFCAB3A2),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
