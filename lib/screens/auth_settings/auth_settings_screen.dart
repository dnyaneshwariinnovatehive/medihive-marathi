import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/standard_header.dart';
import '../../widgets/section_card.dart';
import '../../services/backup_code_service.dart';

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

  bool _is2FAEnabled = false;
  bool _isLoading2FA = true;
  bool _isSettingUp2FA = false;
  List<String>? _setupCodes;
  final _setupCodeCtrl = TextEditingController();
  String? _setupError;
  bool _isVerifyingSetup = false;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
  }

  Future<void> _check2FAStatus() async {
    final enabled = await BackupCodeService.is2FAEnabled();
    if (mounted) {
      setState(() {
        _is2FAEnabled = enabled;
        _isLoading2FA = false;
      });
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _setupCodeCtrl.dispose();
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
    return Scaffold(backgroundColor: AppTheme.background, body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
      StandardHeader(title: 'Authentication', showBack: true, onBack: () => context.go('/app/settings')),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
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
        SectionCard(child: _build2FASection()),
        SizedBox(height: 16),
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
      ]))),
    ]));
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

  // ─── 2FA Methods ──────────────────────────────────────────────

  Widget _build2FASection() {
    return Column(children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: (_is2FAEnabled ? AppTheme.success : AppTheme.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_is2FAEnabled ? Icons.security : Icons.smartphone, color: _is2FAEnabled ? AppTheme.success : AppTheme.primary, size: 24)),
        SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
          Text(_is2FAEnabled ? 'Extra security is active' : 'Add extra security layer', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      ]),
      SizedBox(height: 16),
      if (_isLoading2FA)
        Center(child: Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator()))
      else if (_isSettingUp2FA)
        _build2FASetup()
      else if (_is2FAEnabled)
        _build2FADisable()
      else
        _build2FAEnable(),
    ]);
  }

  Widget _build2FAEnable() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceTint, borderRadius: BorderRadius.circular(12)),
        child: Text('Enable two-factor authentication to add an extra layer of security to your account. You\'ll need to enter a backup code in addition to your password.',
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _start2FASetup,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textOnPrimary, padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Enable 2FA', style: TextStyle(fontWeight: FontWeight.w600)))),
    ]);
  }

  Future<void> _start2FASetup() async {
    setState(() {
      _isSettingUp2FA = true;
      _setupCodes = null;
      _setupCodeCtrl.clear();
      _setupError = null;
    });

    final codes = BackupCodeService.generateCodes();
    setState(() {
      _setupCodes = codes;
    });
  }

  Widget _build2FASetup() {
    if (_setupCodes == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Save these backup codes now. You will not see them again after this screen. Each code can only be used once.',
            style: TextStyle(fontSize: 13, color: AppTheme.warning, fontWeight: FontWeight.w500),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: [
          ...List.generate(5, (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: _codeChip(_setupCodes![row * 2], row * 2)),
              const SizedBox(width: 8),
              Expanded(child: _codeChip(_setupCodes![row * 2 + 1], row * 2 + 1)),
            ]),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: [
          Text('Confirm by entering one of the backup codes above:', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _setupCodeCtrl,
            enabled: !_isVerifyingSetup,
            textCapitalization: TextCapitalization.characters,
            maxLength: 9,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'ABCD-1234',
              hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 20, letterSpacing: 4),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),
          if (_setupError != null) ...[
            const SizedBox(height: 8),
            Text(_setupError!, style: TextStyle(color: AppTheme.danger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: _isVerifyingSetup ? null : () => setState(() => _isSettingUp2FA = false),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _isVerifyingSetup ? null : _verify2FASetup,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isVerifyingSetup
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textOnPrimary))
                  : const Text('Verify & Enable', style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ])),
    ]);
  }

  Widget _codeChip(String code, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Text('${index + 1}.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(child: Text(code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textPrimary, fontFamily: 'monospace'))),
      ]),
    );
  }

  Future<void> _verify2FASetup() async {
    final code = _setupCodeCtrl.text.trim().toUpperCase();
    if (code.length != 9 || !code.contains('-')) {
      setState(() => _setupError = 'Enter a valid backup code (e.g. ABCD-1234)');
      return;
    }

    final codes = _setupCodes;
    if (codes == null || !codes.contains(code)) {
      setState(() => _setupError = 'Invalid code. Enter one of the codes displayed above.');
      return;
    }

    setState(() {
      _isVerifyingSetup = true;
      _setupError = null;
    });

    await BackupCodeService.enable2FA(codes);
    if (mounted) {
      setState(() {
        _is2FAEnabled = true;
        _isSettingUp2FA = false;
        _isVerifyingSetup = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('2FA enabled successfully!'),
        backgroundColor: AppTheme.primary,
      ));
    }
  }

  Widget _build2FADisable() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Two-factor authentication is enabled. Your account has an extra layer of security.',
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
        ])),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _confirmDisable2FA,
        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.danger, width: 1.5)),
        child: const Text('Disable 2FA', style: TextStyle(fontWeight: FontWeight.w600)))),
    ]);
  }

  Future<void> _confirmDisable2FA() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
          const SizedBox(width: 8),
          const Text('Disable 2FA'),
        ]),
        content: const Text('Are you sure? Two-factor authentication adds an important layer of security to your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: AppTheme.textOnPrimary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BackupCodeService.disable2FA();
      if (mounted) {
        setState(() => _is2FAEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('2FA disabled'),
          backgroundColor: AppTheme.primary,
        ));
      }
    }
  }
}
