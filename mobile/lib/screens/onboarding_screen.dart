import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/coffee_colors.dart';
import '../widgets/common/animated_background.dart';

const _storage = FlutterSecureStorage();

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.coffee_rounded,
      title: 'MoovieCoffee',
      subtitle: 'Découvrez des films.\nPartagez vos coups de coeur.',
      useSvgLogo: true,
      useHolyCreamTitle: true,
    ),
    OnboardingPage(
      icon: Icons.swipe_rounded,
      title: 'Swipez pour découvrir',
      subtitle: 'Swipez à droite pour aimer\nSwipez à gauche pour passer',
    ),
    OnboardingPage(
      icon: Icons.star_rounded,
      title: 'Notez vos films vus',
      subtitle: 'Swipez vers le haut pour\nnoter un film déjà vu',
    ),
    OnboardingPage(
      icon: Icons.favorite_rounded,
      title: 'Matchs avec vos amis',
      subtitle: 'Quand vous et un ami aimez\nle même film = Match!',
    ),
    OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      title: 'Prêt à commencer ?',
      subtitle: 'Explorez, notez, partagez\net devenez un cinéphile!',
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await _storage.write(key: 'onboarding_complete', value: 'true');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.latteCream,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: CoffeeColors.moka.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _fadeController.reset();
                    _scaleController.reset();
                    _fadeController.forward();
                    _scaleController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next/Start button
                    _buildButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with glass effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: CoffeeColors.caramelBronze.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: CoffeeColors.caramelBronze.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: page.useSvgLogo
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: SvgPicture.asset(
                          'assets/logoB.svg',
                          colorFilter: const ColorFilter.mode(
                            CoffeeColors.espresso,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                    : Icon(
                        page.icon,
                        size: 70,
                        color: CoffeeColors.caramelBronze,
                      ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: page.useHolyCreamTitle
                    ? const TextStyle(
                        fontFamily: 'HolyCream',
                        fontSize: 38,
                        color: CoffeeColors.espresso,
                      )
                    : const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RecoletaAlt',
                        color: CoffeeColors.espresso,
                        letterSpacing: -0.5,
                      ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: CoffeeColors.moka.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? CoffeeColors.caramelBronze
            : CoffeeColors.steamMilk,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButton() {
    final isLast = _currentPage == _pages.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoffeeColors.espresso,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? "C'est parti !" : 'Suivant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'RecoletaAlt',
                letterSpacing: 0.5,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
            if (isLast) ...[
              const SizedBox(width: 8),
              const Icon(Icons.rocket_launch_rounded, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool useSvgLogo;
  final bool useHolyCreamTitle;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.useSvgLogo = false,
    this.useHolyCreamTitle = false,
  });
}
