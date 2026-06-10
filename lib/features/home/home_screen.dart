import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/core/router/app_router.dart';
import 'package:ocean_lens_ar/core/widgets/ocean_guide_fish.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';
import 'widgets/nav_card.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardsController;
  late List<Animation<Offset>> _cardSlideAnimations;
  late List<Animation<double>> _cardFadeAnimations;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardSlideAnimations = List.generate(4, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardsController,
        curve: Interval(i * 0.1, 0.45 + i * 0.1, curve: Curves.easeOutBack), // Oyun havası için zıplayan geçiş
      ));
    });

    _cardFadeAnimations = List.generate(4, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _cardsController,
        curve: Interval(i * 0.1, 0.45 + i * 0.1, curve: Curves.easeOut),
      ));
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      _cardsController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          // Animasyonlu baloncuklu arka plan
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _HomeBackgroundPainter(_bgController.value),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 4),
                _buildSubtitle(),
                const SizedBox(height: 32),
                Expanded(child: _buildNavCards()),
                _buildBottomInfo(),
              ],
            ),
          ),

          const OceanGuideFish(
            messages: [
              "Okyanus macerasına hoş geldin! Balık müzesini gezebilir veya hemen oyuna başlayabilirsin! 🎮",
              "Oyunumuzda en çok skoru alıp okyanusun kralı olmaya ne dersin? 🏆",
              "Balık müzesinde bulunan her balığın gerçek denizlerimizden derlendiğini biliyor muydun? 🌊",
              "Hey, suyun altında keşfedilecek çok şey var! 🐠 Hadi hemen bir yere tıkla!",
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.aqua],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aqua.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (b) => AppColors.aquaGradient.createShader(b),
            child: Text(
              'OceanLens AR',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Oyna, Öğren, Keşfet! 🐠',
        style: GoogleFonts.fredoka(
          fontSize: 15,
          color: AppColors.lightSeafoam,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNavCards() {
    final cards = [
      _NavCardData(
        title: 'Balık Müzesi',
        subtitle: '10 Türkiye deniz türünü eğlenceli keşfet!',
        icon: Icons.menu_book_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3156), Color(0xFF1B4D7B)],
        ),
        accentColor: AppColors.aqua,
        route: AppRoutes.museum,
        tag: 'BİLGİ DEFTERİ 📖',
      ),
      _NavCardData(
        title: 'Balık Oyunu',
        subtitle: 'Ye, büyü, puan topla! • Büyük balığı atlat!',
        icon: Icons.sports_esports_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF421E07), Color(0xFF633912)],
        ),
        accentColor: AppColors.amber,
        route: AppRoutes.game,
        tag: 'BALIK YEME OYUNU 🎮',
      ),
      _NavCardData(
        title: 'Bilgi Yarışması',
        subtitle: 'Soruları doğru bil, rekor puan topla!',
        icon: Icons.psychology_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF381B54), Color(0xFF5A2A82)],
        ),
        accentColor: Colors.purpleAccent,
        route: AppRoutes.quiz,
        tag: 'BİLGİ YARIŞMASI 🏆',
      ),
      _NavCardData(
        title: 'Okyanus Akvaryumum',
        subtitle: 'Çıkartmalarla hayalindeki deniz dünyasını tasarla!',
        icon: Icons.palette_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4E56), Color(0xFF1E7B82)],
        ),
        accentColor: AppColors.aqua,
        route: AppRoutes.aquarium,
        tag: 'TASARIM KANVASI 🎨',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        return SlideTransition(
          position: _cardSlideAnimations[i],
          child: FadeTransition(
            opacity: _cardFadeAnimations[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NavCard(
                data: cards[i],
                onTap: () {
                  AudioService.instance.playClick();
                  context.push(cards[i].route);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, size: 16, color: AppColors.gold.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            'Okyanus Macerası  •  Eğlenceli Öğrenme Robotu',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              color: AppColors.teal.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String route;
  final String tag;

  const _NavCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.route,
    required this.tag,
  });
}

// Home arka plan painter
class _HomeBackgroundPainter extends CustomPainter {
  final double anim;
  _HomeBackgroundPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    // Glow circles
    _drawGlow(canvas, Offset(size.width * 0.8, size.height * 0.15),
        120, AppColors.teal.withValues(alpha: 0.08));
    _drawGlow(canvas, Offset(size.width * 0.1, size.height * 0.5),
        100, AppColors.aqua.withValues(alpha: 0.06));
    _drawGlow(canvas, Offset(size.width * 0.9, size.height * 0.7),
        80, AppColors.seafoam.withValues(alpha: 0.06));

    // Yükselen Arka Plan Baloncukları
    _drawBubbles(canvas, size);

    // Alt dalga
    _drawBottomWave(canvas, size);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final factor = sin(anim * 2 * pi) * 0.12 + 0.88;
    canvas.drawCircle(
      center,
      radius * factor,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bubbleColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Basit 5 adet arka plan kabarcığı
    final bubbles = [
      {'x': 0.18, 'radius': 14.0, 'speed': 0.5, 'offset': 0.0},
      {'x': 0.75, 'radius': 18.0, 'speed': 0.4, 'offset': 0.3},
      {'x': 0.88, 'radius': 10.0, 'speed': 0.6, 'offset': 0.6},
      {'x': 0.42, 'radius': 16.0, 'speed': 0.45, 'offset': 0.15},
      {'x': 0.28, 'radius': 11.0, 'speed': 0.55, 'offset': 0.75},
    ];

    for (final b in bubbles) {
      final progress = ((anim + (b['offset'] as num).toDouble()) % 1.0);
      final y = size.height * (1.1 - progress * 1.2);
      final x = size.width * (b['x'] as num).toDouble() + sin(progress * 2 * pi * 2) * 10;
      final r = (b['radius'] as num).toDouble();
      final center = Offset(x, y);

      canvas.drawCircle(center, r, paint);
      canvas.drawCircle(
        Offset(center.dx - r * 0.3, center.dy - r * 0.3),
        r * 0.22,
        highlightPaint,
      );
    }
  }

  void _drawBottomWave(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.midOcean.withValues(alpha: 0.15);
    final path = Path();
    path.moveTo(0, size.height * 0.90);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.90 +
          15 * sin((x / size.width) * 2 * pi + anim * 2 * pi);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HomeBackgroundPainter old) => old.anim != anim;
}

// NavCard için data sınıfını export et
// NavCard için data sınıfı bu dosyada tanımlı
