import 'package:flutter/material.dart';

class SuccessOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onComplete;

  const SuccessOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _textController;
  late AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Animation Sequence
    _scaleController.forward().then((_) {
      if (!mounted) return;
      _checkController.forward().then((_) {
        if (!mounted) return;
        _textController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _exitController.forward().then((_) {
              if (mounted) {
                widget.onComplete();
              }
            });
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(_exitController),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circle + check
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  width: 88, 
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A506C),
                    shape: BoxShape.circle,
                  ),
                  child: FadeTransition(
                    opacity: _checkController,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white, 
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Text fades in after check
              FadeTransition(
                opacity: _textController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _textController,
                    curve: Curves.easeOut,
                  )),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A506C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8AAFC0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }
}
