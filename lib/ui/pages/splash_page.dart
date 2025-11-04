import 'dart:async';
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
  late final Animation<double> _scale;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    // Load saved theme mode preference
    Future.microtask(() => ref.read(themeControllerProvider).load());
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _subtitleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn));
    _controller.forward();

    // Soft pulse around the logo
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withOpacity(0.9),
              cs.secondaryContainer.withOpacity(0.9),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle Islamic motif using icons grid
            Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: _PatternPainter(color: cs.primary),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final t = _pulseCtrl.value; // 0..1
                        final blur = 18 + 8 * t;
                        final spread = 1 + 1.5 * t;
                        final scale = 1.0 + 0.02 * t;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cs.onPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: cs.primary.withOpacity(0.35), blurRadius: blur, spreadRadius: spread),
                              ],
                            ),
                            child: Icon(Icons.mosque_rounded, color: cs.primary, size: 36),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Al Quran HR', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: cs.onSecondaryContainer)),
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text('Baca • Dengar • Tadabbur', style: GoogleFonts.poppins(fontSize: 14, color: cs.onSecondaryContainer.withOpacity(0.9))),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 48.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final path = Path();
        path.addPolygon([
          Offset(x + 12, y + 0),
          Offset(x + 24, y + 12),
          Offset(x + 12, y + 24),
          Offset(x + 0, y + 12),
        ], true);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
