import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fishController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 2800));

    // Ekranı kararttıktan sonra yönlendir
    final fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    fadeOut.forward();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fishController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          // Arka plan gradyenti
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),

          // Animasyonlu Yükselen Kabarcıklar
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
                painter: _BubblePainter(_waveController.value),
              );
            },
          ),

          // Yüzen sevimli balıklar
          AnimatedBuilder(
            animation: _fishController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ),
                painter: _SplashFishPainter(_fishController.value),
              );
            },
          ),

          // Merkez içerik
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ikonu
                AnimatedBuilder(
                  animation: Listenable.merge([_logoFade, _logoScale]),
                  builder: (context, _) {
                    return Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _buildLogo(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Başlık
                AnimatedBuilder(
                  animation: _logoFade,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _logoFade.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.aquaGradient.createShader(bounds),
                            child: Text(
                              'OceanLens',
                              style: GoogleFonts.fredoka(
                                fontSize: 50,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'AR OYUNU',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Alt yazı
                AnimatedBuilder(
                  animation: _subtitleFade,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _subtitleFade.value,
                      child: Text(
                        'Okyanus Dünyasını Keşfet! 🐠',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.silver.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Yükleniyor indikatörü
                AnimatedBuilder(
                  animation: _subtitleFade,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _subtitleFade.value,
                      child: _buildLoadingDots(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, AppColors.aqua],
        ),
        border: Border.all(color: Colors.white, width: 3), // Çizgi film stili kenarlık
        boxShadow: [
          BoxShadow(
            color: AppColors.aqua.withValues(alpha: 0.45),
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logos/OceanlensAR_logo_2.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_waveController.value * 2 * pi + i * pi / 1.5);
            final opacity = (sin(phase) + 1) / 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: Container(
                  width: 12, // Daha büyük baloncuk indikatörleri
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.aqua,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Baloncuk animasyonu painter (Yükselen Sevimli Kabarcıklar)
class _BubblePainter extends CustomPainter {
  final double animValue;

  _BubblePainter(this.animValue);

  static final List<Map<String, dynamic>> _bubbleData = [
    {'x': 0.15, 'radius': 14.0, 'speed': 0.6, 'wiggle': 15.0, 'offset': 0.0},
    {'x': 0.35, 'radius': 8.0,  'speed': 0.8, 'wiggle': 10.0, 'offset': 0.25},
    {'x': 0.55, 'radius': 18.0, 'speed': 0.4, 'wiggle': 20.0, 'offset': 0.5},
    {'x': 0.75, 'radius': 10.0, 'speed': 0.7, 'wiggle': 12.0, 'offset': 0.1},
    {'x': 0.90, 'radius': 15.0, 'speed': 0.5, 'wiggle': 18.0, 'offset': 0.7},
    {'x': 0.25, 'radius': 12.0, 'speed': 0.55, 'wiggle': 14.0, 'offset': 0.6},
    {'x': 0.65, 'radius': 7.0,  'speed': 0.9, 'wiggle': 8.0,  'offset': 0.8},
    {'x': 0.80, 'radius': 20.0, 'speed': 0.45, 'wiggle': 22.0, 'offset': 0.35},
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bubbleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (final b in _bubbleData) {
      final progress = ((animValue + (b['offset'] as num).toDouble()) % 1.0);
      final y = size.height * (1.1 - progress * 1.2); // Yükselme hareketi
      
      // Yatayda dalgalanma (sinusoidal wiggle)
      final wiggleX = sin(progress * 2 * pi * 4) * (b['wiggle'] as num).toDouble();
      final x = size.width * (b['x'] as num).toDouble() + wiggleX;
      
      final r = (b['radius'] as num).toDouble();
      final center = Offset(x, y);

      // Ana balon çemberi
      canvas.drawCircle(center, r, paint);
      
      // Balon parlaması (iç hilal/nokta)
      canvas.drawCircle(
        Offset(center.dx - r * 0.3, center.dy - r * 0.3),
        r * 0.22,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.animValue != animValue;
}

// Sevimli balık animasyonu painter
class _SplashFishPainter extends CustomPainter {
  final double animValue;

  _SplashFishPainter(this.animValue);

  static final List<Map<String, dynamic>> _fishData = [
    {'size': 16.0, 'y': 0.22, 'speed': 0.35, 'color': 0xFF06B6D4, 'offset': 0.0},
    {'size': 12.0, 'y': 0.38, 'speed': 0.55, 'color': 0xFF10B981, 'offset': 0.3},
    {'size': 20.0, 'y': 0.70, 'speed': 0.25, 'color': 0xFF0EA5E9, 'offset': 0.6},
    {'size': 10.0, 'y': 0.52, 'speed': 0.7,  'color': 0xFFFF9F1C, 'offset': 0.15},
    {'size': 14.0, 'y': 0.82, 'speed': 0.45, 'color': 0xFFFF5277, 'offset': 0.75},
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final fish in _fishData) {
      final progress = ((animValue + (fish['offset'] as num).toDouble()) % 1.0);
      final x = progress * (size.width + 80) - 40;
      final y = size.height * (fish['y'] as num).toDouble();
      final fishSize = (fish['size'] as num).toDouble();
      final color = Color(fish['color'] as int).withValues(alpha: 0.5); // Daha belirgin
      _drawFish(canvas, Offset(x, y), fishSize, color);
    }
  }

  void _drawFish(Canvas canvas, Offset pos, double size, Color color) {
    final paint = Paint()..color = color;

    // Vücut (Tombul ve şirin)
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: size * 2.1, height: size * 1.3),
      paint,
    );

    // Kuyruk (Çizgi film stili)
    final tailPath = Path()
      ..moveTo(pos.dx - size * 0.9, pos.dy)
      ..lineTo(pos.dx - size * 1.7, pos.dy - size * 0.8)
      ..lineTo(pos.dx - size * 1.4, pos.dy)
      ..lineTo(pos.dx - size * 1.7, pos.dy + size * 0.8)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Göz (Beyaz kısmı)
    final eyePaintWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(pos.dx + size * 0.5, pos.dy - size * 0.2), size * 0.25, eyePaintWhite);

    // Göz (Siyah göz bebeği)
    final eyePaintBlack = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(pos.dx + size * 0.55, pos.dy - size * 0.2), size * 0.12, eyePaintBlack);
  }

  @override
  bool shouldRepaint(_SplashFishPainter old) => old.animValue != animValue;
}
