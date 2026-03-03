// lib/screens/splash/splash_screen.dart
// Animated splash screen with medical 3D theme

import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _cubeController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _textController;

  late Animation<double> _cubeRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 3D Cube rotation animation
    _cubeController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _cubeRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _cubeController, curve: Curves.easeInOut),
    );

    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Text slide up animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Start cube rotation
    _cubeController.forward();

    // Start pulse animation (repeating)
    _pulseController.repeat(reverse: true);

    // Delay then show text
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Wait for main animation to complete
    await Future.delayed(const Duration(milliseconds: 2200));

    // Fade out and complete
    await _fadeController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _cubeController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _cubeRotation,
        _pulseAnimation,
        _fadeAnimation,
        _textSlideAnimation,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Scaffold(
            backgroundColor: const Color(0xFF050d1a),
            body: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1a3a6e),
                    Color(0xFF0d1f3c),
                    Color(0xFF050d1a),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated 3D Medical Icon
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4FC3F7).withOpacity(0.3),
                              blurRadius: 40 * _pulseAnimation.value,
                              spreadRadius: 10 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_cubeRotation.value)
                            ..rotateX(_cubeRotation.value * 0.5),
                          child: CustomPaint(
                            size: const Size(150, 150),
                            painter: _Medical3DIconPainter(
                              rotation: _cubeRotation.value,
                              pulseScale: _pulseAnimation.value,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // App Name with slide animation
                    Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF4FC3F7),
                                  Color(0xFF81D4FA),
                                  Color(0xFFB3E5FC),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                '3D Clinic',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3D Anatomical Models',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF4FC3F7).withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for the 3D medical icon
class _Medical3DIconPainter extends CustomPainter {
  final double rotation;
  final double pulseScale;

  _Medical3DIconPainter({required this.rotation, required this.pulseScale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw outer ring (representing 3D orbit)
    final orbitPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius + 20, orbitPaint);

    // Draw rotating orbits
    for (int i = 0; i < 3; i++) {
      final orbitOffset = (rotation + i * math.pi / 3) % (2 * math.pi);
      final ellipsePaint = Paint()
        ..color = const Color(0xFF4FC3F7).withOpacity(0.2 + i * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(orbitOffset);
      canvas.scale(1, 0.3);
      canvas.drawCircle(Offset.zero, radius + 15, ellipsePaint);
      canvas.restore();
    }

    // Draw medical cross/plus symbol
    final crossPaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.fill;

    final crossWidth = radius * 0.3;
    final crossLength = radius * 0.8;

    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: crossLength,
          height: crossWidth,
        ),
        const Radius.circular(4),
      ),
      crossPaint,
    );

    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: crossWidth,
          height: crossLength,
        ),
        const Radius.circular(4),
      ),
      crossPaint,
    );

    // Draw orbiting particles (representing atoms/molecules)
    final particlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = rotation * 2 + i * math.pi / 2;
      final particleX = center.dx + (radius + 15) * math.cos(angle);
      final particleY = center.dy + (radius + 15) * math.sin(angle) * 0.3;

      // Only draw if in "front" of the ellipse
      if (math.sin(angle) > -0.5) {
        canvas.drawCircle(
          Offset(particleX, particleY),
          4,
          particlePaint,
        );
      }
    }

    // Inner glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4FC3F7).withOpacity(0.4 * pulseScale),
          const Color(0xFF4FC3F7).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _Medical3DIconPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulseScale != pulseScale;
  }
}
