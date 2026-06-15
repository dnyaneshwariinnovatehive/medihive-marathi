import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  
  // Phase 2
  late Animation<Offset> _appNameSlide;
  late Animation<double> _appNameFade;
  
  // Phase 3
  late Animation<double> _taglineFade;
  
  // Phase 5
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Phase 2: 500ms to 900ms (0.178 to 0.321)
    _appNameSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(500/2800, 900/2800, curve: Curves.easeOutCubic),
    ));
    _appNameFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(500/2800, 900/2800, curve: Curves.easeOutCubic),
    ));

    // Phase 3: 800ms to 1200ms (0.285 to 0.428)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(800/2800, 1200/2800, curve: Curves.easeOut),
    ));

    // Phase 5: 2400ms to 2800ms (0.857 to 1.0)
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _sequenceController,
      curve: const Interval(2400/2800, 2800/2800, curve: Curves.linear),
    ));

    _sequenceController.forward().then((_) async {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        await auth.loadSavedCredentials();
        if (mounted) {
          context.go(auth.isLoggedIn ? '/app' : '/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A506C),
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase 1: Logo arrives (0 to 700ms)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Phase 2: App name slides up
              FadeTransition(
                opacity: _appNameFade,
                child: SlideTransition(
                  position: _appNameSlide,
                  child: const Text(
                    'MediHive',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Phase 3: Tagline appears
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Smart Clinic Management',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Phase 4: Loading indicator (1000ms to 2400ms)
              // The dot animation handles its own continuous pulsing
              // but we delay its visibility via the main sequence.
              AnimatedBuilder(
                animation: _sequenceController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _sequenceController.value > (1000/2800) ? 1.0 : 0.0,
                    child: child,
                  );
                },
                child: const _LoadingDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    // Stagger delay: dot1=0ms, dot2=180ms, dot3=360ms
    // Relative to 700ms: dot1=0.0, dot2=0.257, dot3=0.514
    final delay = (index * 180) / 700.0;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Shift time by delay and wrap around 1.0
        double t = (_pulseController.value - delay) % 1.0;
        if (t < 0) t += 1.0;
        
        // Calculate pulse (Scale: 1.0 -> 1.6 -> 1.0, Opacity: 0.5 -> 1.0 -> 0.5)
        // using sine wave for smooth transition
        final pulse = sin(t * pi); 
        
        return Transform.scale(
          scale: 1.0 + (0.6 * pulse),
          child: Opacity(
            opacity: 0.5 + (0.5 * pulse),
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(0),
        const SizedBox(width: 8),
        _buildDot(1),
        const SizedBox(width: 8),
        _buildDot(2),
      ],
    );
  }
}
