import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'theme/coffee_colors.dart';
import 'api_service.dart';
import 'widgets/common/animated_background.dart';

/// =============================================================================
/// AUTH SCREEN - Design Premium Coffee
/// =============================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() {
      isLogin = !isLogin;
    });
    _animController.reset();
    _animController.forward();
  }

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && username.isEmpty)) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    if (!email.contains('@')) {
      _showError("Email invalide");
      return;
    }

    if (password.length < 6) {
      _showError("Le mot de passe doit contenir au moins 6 caractères");
      return;
    }

    setState(() => _isLoading = true);

    bool success = isLogin
        ? await auth.login(email, password)
        : await auth.signup(username, email, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        _showError(isLogin
            ? "Email ou mot de passe incorrect"
            : "Erreur lors de l'inscription");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CoffeeColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.latteCream,
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 24),

                    // Form Card
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Text(
      'MoovieCoffee',
      style: TextStyle(
        fontFamily: 'HolyCream',
        fontSize: 42,
        color: CoffeeColors.espresso,
        shadows: [
          Shadow(
            color: CoffeeColors.espresso.withValues(alpha: 0.3),
            offset: const Offset(0.5, 0.5),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: CoffeeColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle buttons
          _buildToggle(),
          const SizedBox(height: 28),

          // Username (only for signup)
          if (!isLogin) ...[
            _buildTextField(
              controller: _usernameController,
              label: 'Pseudo',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
          ],

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: CoffeeColors.moka,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 28),

          // Submit button
          _buildSubmitButton(),

          // Forgot password (only for login)
          if (isLogin) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  color: CoffeeColors.moka,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CoffeeColors.latteCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Connexion',
              isSelected: isLogin,
              onTap: () {
                if (!isLogin) _toggleMode();
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Inscription',
              isSelected: !isLogin,
              onTap: () {
                if (isLogin) _toggleMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? CoffeeColors.caramelBronze : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'RecoletaAlt',
              color: isSelected ? Colors.white : CoffeeColors.moka,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: CoffeeColors.espresso,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: CoffeeColors.moka,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: CoffeeColors.caramelBronze, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: CoffeeColors.latteCream.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CoffeeColors.caramelBronze,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoffeeColors.caramelBronze,
          disabledBackgroundColor: CoffeeColors.steamMilk,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isLogin ? 'Se connecter' : "S'inscrire",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RecoletaAlt',
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

/// =============================================================================
/// FORGOT PASSWORD SCREEN
/// =============================================================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Veuillez entrer votre email");
      return;
    }

    if (!email.contains('@')) {
      _showError("Email invalide");
      return;
    }

    setState(() => _isLoading = true);

    final api = ApiService();
    await api.requestPasswordReset(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Always show success to prevent email enumeration attacks
        _emailSent = true;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CoffeeColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.latteCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CoffeeColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'RecoletaAlt',
            color: CoffeeColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez votre email pour recevoir un lien de réinitialisation.',
          style: TextStyle(
            fontSize: 15,
            color: CoffeeColors.moka.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 32),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 15,
            color: CoffeeColors.espresso,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: const TextStyle(
              color: CoffeeColors.moka,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: CoffeeColors.caramelBronze,
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: CoffeeColors.caramelBronze,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeeColors.caramelBronze,
              disabledBackgroundColor: CoffeeColors.steamMilk,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Envoyer le lien',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RecoletaAlt',
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CoffeeColors.caramelBronze.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: CoffeeColors.caramelBronze,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email envoyé !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'RecoletaAlt',
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Si un compte existe avec cet email, vous recevrez un lien de réinitialisation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: CoffeeColors.moka.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Retour à la connexion',
              style: TextStyle(
                color: CoffeeColors.caramelBronze,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'RecoletaAlt',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
