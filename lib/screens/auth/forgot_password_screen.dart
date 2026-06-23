import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSubmitting = false;
  bool _stepTwo = false;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyUsername() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final username = _usernameCtrl.text.trim();

    final envUser = dotenv.env['LOCAL_USERNAME'];
    if (username == envUser) {
      setState(() {
        _stepTwo = true;
        _isSubmitting = false;
      });
      _animCtrl.forward(from: 0);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Username not found. Please check and try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match!');
      return;
    }
    if (_newPasswordCtrl.text.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters!');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final username = _usernameCtrl.text.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_password', _newPasswordCtrl.text);
    await prefs.setString('app_username', username);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset successfully! Please login with your new password.'),
        backgroundColor: AppTheme.primary,
      ));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _stepTwo ? 'Set New Password' : 'Reset Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _stepTwo
                              ? 'Enter your new password'
                              : 'Enter your username to reset your password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          if (_stepTwo) ...[
                            TextFormField(
                              controller: _newPasswordCtrl,
                              enabled: !_isSubmitting,
                              obscureText: !_showNew,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                filled: true,
                                fillColor: AppTheme.surfaceVariant,
                                prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility, size: 22),
                                  onPressed: () => setState(() => _showNew = !_showNew),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter a new password';
                                if (v.length < 4) return 'At least 4 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              enabled: !_isSubmitting,
                              obscureText: !_showConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _resetPassword(),
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                filled: true,
                                fillColor: AppTheme.surfaceVariant,
                                prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 22),
                                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Confirm your new password';
                                return null;
                              },
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _usernameCtrl,
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _verifyUsername(),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                filled: true,
                                fillColor: AppTheme.surfaceVariant,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 8),
                                  child: Icon(Icons.person_outline, size: 22, color: AppTheme.primary),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your username';
                                return null;
                              },
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : (_stepTwo ? _resetPassword : _verifyUsername),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : Text(_stepTwo ? 'RESET PASSWORD' : 'VERIFY', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSubmitting ? null : () => context.go('/login'),
                            child: Text('Back to Login', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
