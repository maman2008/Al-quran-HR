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
  late final AnimationController _textRevealCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _bgOpacity;
  late final Animation<double> _rotation;
  late final Animation<double> _textSlide;
  late final Animation<double> _welcomeFade;

  @override
  void initState() {
    super.initState();
    // Load saved theme mode preference
    Future.microtask(() => ref.read(themeControllerProvider).load());
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _subtitleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut));
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // Text reveal animation
    _textRevealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _textSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _textRevealCtrl, curve: Curves.easeOutCubic),
    );
    _welcomeFade = CurvedAnimation(parent: _textRevealCtrl, curve: Curves.easeIn);

    // Soft pulse around the logo
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    
    // Background pulse animation
    _bgPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    _bgOpacity = Tween<double>(begin: 0.2, end: 0.8).animate(_bgPulseCtrl);

    _controller.forward().then((_) {
      _textRevealCtrl.forward();
    });

    Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseCtrl.dispose();
    _bgPulseCtrl.dispose();
    _textRevealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Enhanced animated gradient background
          AnimatedBuilder(
            animation: _bgPulseCtrl,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: 0,
                    endAngle: 2 * pi,
                    colors: [
                      cs.primaryContainer.withOpacity(_bgOpacity.value),
                      cs.secondaryContainer.withOpacity(_bgOpacity.value - 0.1),
                      cs.tertiaryContainer ?? cs.primaryContainer,
                      cs.primaryContainer.withOpacity(_bgOpacity.value),
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                    transform: GradientRotation(_bgPulseCtrl.value * 2 * pi),
                  ),
                ),
              );
            },
          ),

          // Animated geometric pattern
          AnimatedBuilder(
            animation: _bgPulseCtrl,
            builder: (context, child) {
              return Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: _bgPulseCtrl.value * 0.1,
                  child: CustomPaint(
                    painter: _ModernPatternPainter(color: cs.primary),
                  ),
                ),
              );
            },
          ),

          // Enhanced floating particles
          _FloatingParticles(count: 25, color: cs.primary.withOpacity(0.4)),

          // Glowing orbs in background
          _GlowingOrbs(color: cs.primary.withOpacity(0.2)),

          Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Multi-layer glow effect
                      ...List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            final t = _pulseCtrl.value;
                            final size = 120.0 + 30 * (index + 1) * t;
                            final opacity = 0.15 - (index * 0.05);
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    cs.primary.withOpacity(opacity),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      // Rotating decorative rings
                      ...List.generate(2, (index) {
                        return RotationTransition(
                          turns: _rotation,
                          child: Container(
                            width: 100 + (index * 20),
                            height: 100 + (index * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withOpacity(0.2 - (index * 0.1)),
                                width: 1 + index.toDouble(),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Enhanced main logo container
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, child) {
                          final t = _pulseCtrl.value;
                          final blur = 30 + 15 * t;
                          final spread = 3 + 4 * t;
                          final scale = 1.0 + 0.05 * t;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.onPrimary,
                                    cs.onPrimary.withOpacity(0.8),
                                    cs.primary.withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.5),
                                    blurRadius: blur,
                                    spreadRadius: spread,
                                  ),
                                  BoxShadow(
                                    color: cs.onPrimary,
                                    blurRadius: 0,
                                    spreadRadius: 3,
                                  ),
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Inner glow
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          cs.primary.withOpacity(0.1),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.mosque_rounded,
                                      color: cs.primary,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Welcome text with reveal animation
                  AnimatedBuilder(
                    animation: _textRevealCtrl,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _welcomeFade.value,
                          child: Text(
                            'Welcome to',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: cs.onSecondaryContainer.withOpacity(0.7),
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Enhanced app title with gradient text and shine effect
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              cs.onSecondaryContainer,
                              cs.primary,
                              cs.primary,
                              cs.onSecondaryContainer,
                            ],
                            stops: const [0.0, 0.4, 0.6, 1.0],
                            transform: _GradientTransform(_pulseCtrl.value),
                          ).createShader(bounds);
                        },
                        child: Text(
                          'Al Quran HR',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Enhanced subtitle with fade animation
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Baca • Dengar • Tadabbur • Amalkan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: cs.onSecondaryContainer.withOpacity(0.8),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Modern loading indicator with pulse effect
                  Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
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
                              width: 120 * _pulseCtrl.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary,
                                      cs.primary.withOpacity(0.8),
                                      cs.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Loading text
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Memuat kebijaksanaan Ilahi...',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSecondaryContainer.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced version info at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: Column(
                children: [
                  Text(
                    'Your Spiritual Companion',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: cs.onSecondaryContainer.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: cs.onSecondaryContainer.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTransform extends GradientTransform {
  final double value;
  
  _GradientTransform(this.value);
  
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()
      ..translate(-bounds.width * 2 + value * bounds.width * 4, 0);
  }
}

class _ModernPatternPainter extends CustomPainter {
  final Color color;
  _ModernPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 80.0;
    
    // Draw enhanced geometric pattern
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final center = Offset(x + spacing / 2, y + spacing / 2);
        
        // Draw hexagon pattern
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = 2 * pi * i / 6;
          final point = center + Offset(cos(angle) * 4, sin(angle) * 4);
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        
        canvas.drawPath(path, paint);
        
        // Draw connecting lines
        if (x < size.width - spacing) {
          canvas.drawLine(
            center,
            center + Offset(spacing, 0),
            paint..strokeWidth = 0.8,
          );
        }
        
        if (y < size.height - spacing) {
          canvas.drawLine(
            center,
            center + Offset(0, spacing),
            paint..strokeWidth = 0.8,
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
      duration: const Duration(seconds: 25),
    )..repeat();

    // Initialize enhanced particles
    final random = Random();
    for (int i = 0; i < widget.count; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 1,
        speed: random.nextDouble() * 0.8 + 0.2,
        offset: random.nextDouble() * 2 * pi,
        type: random.nextInt(3), // Different particle types
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

class _GlowingOrbs extends StatefulWidget {
  final Color color;

  const _GlowingOrbs({required this.color});

  @override
  State<_GlowingOrbs> createState() => _GlowingOrbsState();
}

class _GlowingOrbsState extends State<_GlowingOrbs> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
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
          painter: _GlowingOrbsPainter(
            color: widget.color,
            time: _controller.value,
          ),
        );
      },
    );
  }
}

class _GlowingOrbsPainter extends CustomPainter {
  final Color color;
  final double time;

  _GlowingOrbsPainter({required this.color, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(1); // Fixed seed for consistent pattern
    
    for (int i = 0; i < 8; i++) {
      final x = (random.nextDouble() * 0.6 + 0.2) * size.width;
      final y = (random.nextDouble() * 0.6 + 0.2) * size.height;
      final radius = 30 + 20 * sin(time * 2 * pi + i);
      final opacity = 0.1 + 0.1 * sin(time * 2 * pi + i * 0.5);
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double offset;
  final int type;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
    required this.type,
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
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height + 
                sin(time * 2 * pi * particle.speed + particle.offset) * 20 +
                cos(time * pi * particle.speed * 0.7 + particle.offset) * 10;
      
      final opacity = 0.3 + 0.7 * sin(time * 2 * pi * particle.speed + particle.offset);
      final scale = 0.8 + 0.4 * sin(time * pi * particle.speed + particle.offset);
      
      final paint = Paint()..color = color.withOpacity(opacity * 0.8);
      
      switch (particle.type) {
        case 0:
          // Circle particles
          canvas.drawCircle(
            Offset(x, y),
            particle.size * scale,
            paint,
          );
          break;
        case 1:
          // Square particles
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y),
              width: particle.size * scale * 2,
              height: particle.size * scale * 2,
            ),
            paint,
          );
          break;
        case 2:
          // Star particles
          final path = Path();
          for (int i = 0; i < 5; i++) {
            final angle = 2 * pi * i / 5 - pi / 2;
            final point = Offset(
              x + cos(angle) * particle.size * scale,
              y + sin(angle) * particle.size * scale,
            );
            if (i == 0) {
              path.moveTo(point.dx, point.dy);
            } else {
              path.lineTo(point.dx, point.dy);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}