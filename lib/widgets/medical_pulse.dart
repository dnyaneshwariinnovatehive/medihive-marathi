import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicalPulse extends StatefulWidget {
  final Widget child;
  final double size;
  final Color? color;

  const MedicalPulse({
    super.key,
    required this.child,
    this.size = 120,
    this.color,
  });

  @override
  State<MedicalPulse> createState() => _MedicalPulseState();
}

class _MedicalPulseState extends State<MedicalPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseColor = widget.color ?? AppTheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * _pulseAnim.value,
          height: widget.size * _pulseAnim.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * _pulseAnim.value,
                height: widget.size * _pulseAnim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pulseColor.withValues(alpha: _fadeAnim.value),
                ),
              ),
              Container(
                width: widget.size * 0.85,
                height: widget.size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: pulseColor.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
