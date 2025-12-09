import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../home/home_screen.dart';

// ============================================
// ANIMATED SPLASH SCREEN
// ============================================
// A creative splash screen featuring:
// - Animated logo with scale and rotation
// - Floating particles background
// - Typing text animation for tagline
// - Smooth fade transition to home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _fadeController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _fadeOut;

  // Particles
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    // Use post frame callback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationSequence();
    });
  }

  void _initializeAnimations() {
    // Logo animation (scale + slight rotation)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Particle animation (continuous floating)
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Text animation (fade in)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Fade out to home
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 8 + 2,
          speed: _random.nextDouble() * 0.3 + 0.1,
          opacity: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  void _startAnimationSequence() async {
    try {
      // Start logo animation
      if (mounted) _logoController.forward();

      // Wait a bit then start text
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _textController.forward();

      // Wait for splash duration
      await Future.delayed(const Duration(milliseconds: 2000));

      // Fade out and navigate
      if (mounted) {
        await _fadeController.forward();
        if (mounted) _navigateToHome();
      }
    } catch (e) {
      // If any animation fails, still navigate to home
      if (mounted) _navigateToHome();
    }
  }

  void _navigateToHome() {
    try {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      // Fallback: use simple navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeOut,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF1a1a2e),
                          Color(0xFF16213e),
                          Color(0xFF0f3460),
                        ]
                      : [
                          primaryColor.withAlpha(26), // 0.1 * 255 ≈ 26
                          Colors.white,
                          primaryColor.withAlpha(13), // 0.05 * 255 ≈ 13
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Floating particles
                  _buildParticles(primaryColor),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        _buildAnimatedLogo(primaryColor, isDark),

                        const SizedBox(height: 24),

                        // App name
                        AnimatedBuilder(
                          animation: _logoScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Text(
                                AppStrings.appName,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : primaryColor,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Tagline with fade animation
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textOpacity.value,
                              child: Text(
                                'Track your career journey',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  letterSpacing: 1,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 60),

                        // Loading indicator
                        AnimatedBuilder(
                          animation: _textOpacity,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textOpacity.value,
                              child: _buildLoadingIndicator(primaryColor),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Version at bottom
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _textOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value * 0.5,
                          child: Text(
                            'v${AppStrings.appVersion}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo(Color primaryColor, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScale, _logoRotation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withAlpha(179), // 0.7 * 255 ≈ 179
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(102), // 0.4 * 255 ≈ 102
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles(Color primaryColor) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animation: _particleController.value,
            color: primaryColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Color primaryColor) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          // Animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final offset = ((_particleController.value * 3) + index) % 3;
                  final scale =
                      0.5 +
                      (offset < 1 ? offset : (offset < 2 ? 2 - offset : 0)) *
                          0.5;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PARTICLE CLASS
// ============================================
class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// ============================================
// PARTICLE PAINTER
// ============================================
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position (floating up)
      final y = (particle.y - animation * particle.speed) % 1.0;
      final x = particle.x + sin(animation * 2 * pi + particle.y * 10) * 0.02;

      // Calculate alpha from opacity (0.0-1.0 to 0-255)
      final alpha = (particle.opacity * 0.3 * 255).round().clamp(0, 255);

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
