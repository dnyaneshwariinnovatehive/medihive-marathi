import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'content': "Hello! I'm your MediHive AI assistant. How can I help you today?"},
  ];
  final _prompts = ['How do I add a new patient?', "Export last month's data", "Show me today's appointments", 'Help with prescription format'];

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add({'role': 'user', 'content': text}); _msgCtrl.clear(); });
    _scrollDown();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() { _messages.add({'role': 'bot', 'content': 'I can help you with that! To add a new patient, go to the OPD Registration screen and fill in the patient details including name, age, gender, and contact information.'}); });
      _scrollDown();
    });
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.background, body: Column(children: [
      // Header
      Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 12, offset: Offset(0, 4))]),
        child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(children: [
            GestureDetector(onTap: () => context.go('/app'), child: Icon(Icons.arrow_back, color: Colors.white, size: 24)),
            SizedBox(width: 12),
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
              Text('Always here to help', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ]),
          ]))),
      ),
      // Messages
      Expanded(child: ListView.builder(
        controller: _scrollCtrl, padding: const EdgeInsets.all(16), itemCount: _messages.length + (_messages.length == 1 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _messages.length == 1) {
            // Suggested prompts
            return Padding(padding: const EdgeInsets.only(top: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Suggested prompts:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
              Wrap(spacing: 8, runSpacing: 8, children: _prompts.map((p) => GestureDetector(
                onTap: () => _msgCtrl.text = p,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
                  child: Text(p, style: TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
              )).toList()),
            ]));
          }
          final msg = _messages[index];
          final isBot = msg['role'] == 'bot';
          return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(
            mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBot) CircleAvatar(radius: 20, backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.smart_toy_outlined, color: AppTheme.primary, size: 20)),
              if (isBot) SizedBox(width: 8),
              Flexible(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isBot ? Colors.white : AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isBot ? AppTheme.cardShadow : null,
                ),
                child: Text(msg['content']!, style: TextStyle(fontSize: 14, color: isBot ? AppTheme.textPrimary : Colors.white)),
              )),
              if (!isBot) SizedBox(width: 8),
              if (!isBot) CircleAvatar(radius: 20, backgroundColor: AppTheme.primary,
                child: Icon(Icons.person, color: Colors.white, size: 20)),
            ],
          ));
        },
      )),
      // Input bar
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))]),
        child: SafeArea(top: false, child: Row(children: [
          Expanded(child: TextField(controller: _msgCtrl,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'Ask me anything...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
          SizedBox(width: 12),
          GestureDetector(onTap: _send, child: Container(
            padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.send, color: Colors.white, size: 20))),
        ])),
      ),
    ]));
  }
}

