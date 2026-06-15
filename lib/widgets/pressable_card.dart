import 'package:flutter/material.dart';

class PressableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const PressableCard({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        scale: _isPressed ? 0.97 : 1.0,
        child: widget.child,
      ),
    );
  }
}
