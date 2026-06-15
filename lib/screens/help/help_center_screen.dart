import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/section_card.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedFaq;
  final _faqs = const [
    {'q': 'How do I backup my data?', 'a': 'Go to Settings > Backup & Cloud Sync and click on "Generate Backup" to create a local backup or sync with cloud storage.'},
    {'q': 'Can I export patient records?', 'a': 'Yes, you can export patient records as Excel files from the Backup section. Choose the time period and click Complete Backup.'},
    {'q': 'How do I share prescriptions via WhatsApp?', 'a': 'Open the prescription screen and click the "Share via WhatsApp" button to send the prescription directly to the patient.'},
    {'q': 'How to change my password?', 'a': 'Navigate to Settings > Authentication and click on "Change Password" to update your login credentials.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.background, body: SingleChildScrollView(child: Column(children: [
      GradientAppBar(title: 'Help & Support', subtitle: 'Get assistance and learn more', onBack: () => context.go('/app/settings')),
      Padding(padding: EdgeInsets.all(16), child: Column(children: [
        _infoCard(Icons.code, Color(0x1A1A506C), AppTheme.primary, 'Developer Information', [
          _row('For Technical queries:', ''),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow('Email:', 'ashwin.innovatehive@gmail.com', AppTheme.primary),
              SizedBox(height: 8), _detailRow('Phone:', '8767555945', AppTheme.textPrimary),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.info_outline, Color(0x1A2563EB), Color(0xFF2563EB), 'Application Info', [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow('App Name:', 'MediHive', AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow('Version:', 'v1.0.2', AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow('Platform:', 'Mobile (Android/iOS)', AppTheme.textPrimary), SizedBox(height: 8),
              _detailRow('Last Updated:', 'May 2026', AppTheme.textPrimary),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.storage, Color(0x1A22C55E), Color(0xFF22C55E), 'Backup Information', [
          Text('Backup files are stored locally on your system.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          SizedBox(height: 12),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Location:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              SizedBox(height: 4),
              Text('Internal Storage/MediHive/backup', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontFamily: 'monospace')),
            ])),
        ]),
        SizedBox(height: 16),
        _infoCard(Icons.shield_outlined, Color(0x1A9333EA), Color(0xFF9333EA), 'Data & Privacy', [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceTint, borderRadius: BorderRadius.circular(12)),
            child: Text('All patient data is stored locally on your system. MediHive does not upload or share any data with external servers. Your data remains completely private and secure on your local machine.',
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
        ]),
        SizedBox(height: 16),
        // FAQ Section
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
          SizedBox(height: 16),
          ..._faqs.asMap().entries.map((e) => Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              InkWell(
                onTap: () => setState(() => _expandedFaq = _expandedFaq == e.key ? null : e.key),
                borderRadius: BorderRadius.circular(12),
                child: Padding(padding: EdgeInsets.all(16), child: Row(children: [
                  Expanded(child: Text(e.value['q']!, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
                  AnimatedRotation(turns: _expandedFaq == e.key ? 0.5 : 0, duration: Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: AppTheme.textTertiary)),
                ])),
              ),
              if (_expandedFaq == e.key) Container(
                width: double.infinity, padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                child: Text(e.value['a']!, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            ]),
          )),
        ])),
        SizedBox(height: 80),
      ])),
    ])));
  }

  Widget _infoCard(IconData icon, Color bg, Color fg, String title, List<Widget> children) => SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: fg, size: 24)),
      SizedBox(width: 12),
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
    ]),
    SizedBox(height: 16), ...children,
  ]));

  Widget _row(String label, String value) => Padding(padding: EdgeInsets.only(bottom: 12), child: Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)));
  Widget _detailRow(String label, String value, Color valueColor) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
  ]);
}



