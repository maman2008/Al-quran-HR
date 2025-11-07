import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quran_providers.dart';
import 'home_screen.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bgPulseCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _bgOpacity;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    // Load saved theme mode preference
    Future.microtask(() => ref.read(themeControllerProvider).load());
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _subtitleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut));
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    // Soft pulse around the logo
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    
    // Background pulse animation
    _bgPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _bgOpacity = Tween<double>(begin: 0.3, end: 0.6).animate(_bgPulseCtrl);

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseCtrl.dispose();
    _bgPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgPulseCtrl,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.8,
                    colors: [
                      cs.primaryContainer.withOpacity(_bgOpacity.value),
                      cs.secondaryContainer.withOpacity(_bgOpacity.value - 0.1),
                      cs.tertiaryContainer ?? cs.primaryContainer.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),

          // Modern geometric pattern
          Opacity(
            opacity: 0.12,
            child: CustomPaint(
              painter: _ModernPatternPainter(color: cs.primary),
            ),
          ),

          // Floating particles
          _FloatingParticles(count: 15, color: cs.primary.withOpacity(0.3)),

          Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, child) {
                          final t = _pulseCtrl.value;
                          final size = 120.0 + 20 * t;
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  cs.primary.withOpacity(0.2),
                                  cs.primary.withOpacity(0.05),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Rotating decorative ring
                      RotationTransition(
                        turns: _rotation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      // Main logo container with enhanced shadow
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, child) {
                          final t = _pulseCtrl.value;
                          final blur = 25 + 10 * t;
                          final spread = 2 + 3 * t;
                          final scale = 1.0 + 0.03 * t;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: cs.onPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.4),
                                    blurRadius: blur,
                                    spreadRadius: spread,
                                  ),
                                  BoxShadow(
                                    color: cs.onPrimary,
                                    blurRadius: 0,
                                    spreadRadius: 2,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.onPrimary,
                                    cs.onPrimary.withOpacity(0.9),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.mosque_rounded,
                                color: cs.primary,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App title with gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        cs.onSecondaryContainer,
                        cs.primary,
                        cs.onSecondaryContainer,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      'Al Quran HR',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle with fade animation
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Baca • Dengar • Tadabbur',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: cs.onSecondaryContainer.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Modern loading indicator
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            return Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 60 * _pulseCtrl.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary,
                                      cs.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Version info at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                'Versi 1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: cs.onSecondaryContainer.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernPatternPainter extends CustomPainter {
  final Color color;
  _ModernPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 60.0;
    
    // Draw modern geometric pattern
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Draw small circles
        canvas.drawCircle(
          Offset(x + spacing / 2, y + spacing / 2),
          1.5,
          paint,
        );
        
        // Draw connecting lines
        if (x < size.width - spacing) {
          canvas.drawLine(
            Offset(x + spacing / 2, y + spacing / 2),
            Offset(x + spacing * 1.5, y + spacing / 2),
            paint..strokeWidth = 0.5,
          );
        }
        
        if (y < size.height - spacing) {
          canvas.drawLine(
            Offset(x + spacing / 2, y + spacing / 2),
            Offset(x + spacing / 2, y + spacing * 1.5),
            paint..strokeWidth = 0.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingParticles extends StatefulWidget {
  final int count;
  final Color color;

  const _FloatingParticles({required this.count, required this.color});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize particles
    final random = Random();
    for (int i = 0; i < widget.count; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        offset: random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            color: widget.color,
            time: _controller.value,
          ),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double offset;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  final double time;

  _ParticlesPainter({
    required this.particles,
    required this.color,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height + sin(time * 2 * pi * particle.speed + particle.offset) * 10;
      final opacity = 0.5 + 0.5 * sin(time * 2 * pi * particle.speed + particle.offset);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint..color = color.withOpacity(opacity * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}