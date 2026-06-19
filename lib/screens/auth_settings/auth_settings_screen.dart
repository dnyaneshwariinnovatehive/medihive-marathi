import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/section_card.dart';

class AuthSettingsScreen extends StatefulWidget {
  const AuthSettingsScreen({super.key});
  @override
  State<AuthSettingsScreen> createState() => _AuthSettingsScreenState();
}

class _AuthSettingsScreenState extends State<AuthSettingsScreen> {
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('New passwords do not match!'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    if (_newCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password must be at least 4 characters!'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    if (_currentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter your current password.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('app_password') ?? 'admin123';
      if (_currentCtrl.text != savedPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Current password is incorrect!'),
            backgroundColor: AppTheme.danger,
          ));
        }
        return;
      }
      await prefs.setString('app_password', _newCtrl.text);
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: AppTheme.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update password: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.background, body: SingleChildScrollView(child: Column(children: [
      GradientAppBar(title: 'Authentication', subtitle: 'Manage login & security', onBack: () => context.go('/app/settings')),
      Padding(padding: EdgeInsets.all(16), child: Column(children: [
        // Change Password
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.lock_outline, color: AppTheme.primary, size: 24)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
              Text('Update your login credentials', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ]),
          SizedBox(height: 20),
          _pwField('Current Password', _currentCtrl, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
          SizedBox(height: 16),
          _pwField('New Password', _newCtrl, _showNew, () => setState(() => _showNew = !_showNew)),
          SizedBox(height: 16),
          _pwField('Confirm New Password', _confirmCtrl, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
          SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _isUpdating ? null : _updatePassword,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textOnPrimary,
              padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isUpdating
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textOnPrimary))
                : Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
          )),
        ])),
        SizedBox(height: 16),
        // 2FA
        SectionCard(child: Column(children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.smartphone, color: AppTheme.primary, size: 24)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
              Text('Add extra security layer', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ]),
          SizedBox(height: 16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceTint, borderRadius: BorderRadius.circular(12)),
            child: Text('Enable two-factor authentication to add an extra layer of security to your account. You\'ll need to enter a code from your phone in addition to your password.',
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('2FA not yet available on mobile. Coming soon!'),
              backgroundColor: AppTheme.primary,
            ));
          },
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.primary, width: 2)),
            child: Text('Enable 2FA', style: TextStyle(fontWeight: FontWeight.w600)))),
        ])),
        SizedBox(height: 16),
        // Connected Accounts
        SectionCard(child: Column(children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.mail_outline, color: AppTheme.primary, size: 24)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connected Accounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
              Text('Manage linked services', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ]),
          SizedBox(height: 16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.g_mobiledata, size: 28, color: AppTheme.primary),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Google Account', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  Text(context.watch<SettingsProvider>().isGoogleConnected ? 'Connected via Google Drive' : 'Not connected', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ]),
              Text(context.watch<SettingsProvider>().isGoogleConnected ? 'Connected' : 'Disconnected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.watch<SettingsProvider>().isGoogleConnected ? AppTheme.success : AppTheme.danger)),
            ])),
        ])),
        SizedBox(height: 16),
        // Login Sessions
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Login Sessions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
          SizedBox(height: 16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current Device', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                SizedBox(height: 4), Text('Session active', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.success))),
            ])),
        ])),
        SizedBox(height: 80),
      ])),
    ])));
  }

  Widget _pwField(String label, TextEditingController ctrl, bool show, VoidCallback toggle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
    SizedBox(height: 8),
    TextField(controller: ctrl, obscureText: !show, decoration: InputDecoration(
      hintText: 'Enter ${label.toLowerCase()}',
      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textTertiary, size: 20),
      suffixIcon: GestureDetector(onTap: toggle, child: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textTertiary, size: 20)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
    )),
  ]);
}



