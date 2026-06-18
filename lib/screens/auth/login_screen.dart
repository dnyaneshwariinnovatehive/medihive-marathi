import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _lastSyncedUsername = '';
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _staggerAnimations = List.generate(6, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(i * 0.12, 0.4 + (i * 0.08), curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (auth.username != _lastSyncedUsername &&
        auth.username != _usernameController.text) {
      _lastSyncedUsername = auth.username;
      _usernameController.text = auth.username;
      _usernameController.selection = TextSelection.collapsed(
        offset: _usernameController.text.length,
      );
    }
  }

  Future<void> _submitLogin(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await auth.login();
    if (success && mounted) {
      context.go('/app');
    }
  }

  Widget _staggeredItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _staggerAnimations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[index].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[index].value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.hasLoadedCredentials && auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/app');
        }
      });
    }

    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850, minHeight: 450),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(48),
                            decoration: const BoxDecoration(
                              gradient: AppTheme.headerGradient,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'HELLO',
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                          height: 1.1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '!',
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryLighter,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Welcome to your professional\nHealthcare Management System.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildLoginForm(auth, context),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.headerGradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'HELLO',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '!',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryLighter,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome to your professional\nHealthcare Management System.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildLoginForm(auth, context),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          _staggeredItem(0, Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          )),
          const SizedBox(height: 16),
          _staggeredItem(1, const Text(
            'MediHive',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.primary,
            ),
          )),
          const SizedBox(height: 6),
          _staggeredItem(2, Text(
            'Sign in to your account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          )),
          const SizedBox(height: 40),

          _staggeredItem(3, TextFormField(
            controller: _usernameController,
            enabled: !auth.isLoading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onChanged: (value) {
              _lastSyncedUsername = value;
              auth.setUsername(value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your username';
              }
              return null;
            },
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          )),
          const SizedBox(height: 24),

          _staggeredItem(3, TextFormField(
            controller: _passwordController,
            enabled: !auth.isLoading,
            obscureText: !_showPassword,
            onChanged: auth.setPassword,
            onFieldSubmitted: (_) => _submitLogin(auth),
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your password';
              }
              return null;
            },
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          )),
          const SizedBox(height: 18),

          _staggeredItem(4, Row(
            children: [
              Checkbox(
                value: auth.rememberMe,
                onChanged: auth.isLoading
                    ? null
                    : (value) => auth.setRememberMe(value ?? false),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              GestureDetector(
                onTap: auth.isLoading
                    ? null
                    : () => auth.setRememberMe(!auth.rememberMe),
                child: Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 22),

          _staggeredItem(5, Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () => _submitLogin(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
            ),
          )),
          const SizedBox(height: 24),

          _staggeredItem(5, Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final success = await auth.signInWithGoogle();
                      if (success && mounted) {
                        context.go('/app');
                      } else if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google Sign-In failed')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              label: const Text(
                'SIGN IN WITH GOOGLE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),

          _staggeredItem(5, Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 18, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text(
                'Quick Login',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          )),
          ],
        ),
      ),
    );
  }
}
