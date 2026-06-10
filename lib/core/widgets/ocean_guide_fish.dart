import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';

/// Ekranların sağ altında çıkan sevimli, animasyonlu rehber balık yardımcısı
class OceanGuideFish extends StatefulWidget {
  final List<String> messages;

  const OceanGuideFish({super.key, required this.messages});

  @override
  State<OceanGuideFish> createState() => _OceanGuideFishState();
}

class _OceanGuideFishState extends State<OceanGuideFish>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _swimController;
  late AnimationController _bubbleController;
  late AnimationController _scaleController;

  late Animation<double> _floatAnim;
  late Animation<double> _scaleAnim;

  bool _isBubbleVisible = true;
  int _currentMessageIndex = 0;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // Dikey Yüzme (Yukarı-aşağı salınım)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Kuyruk Sallama
    _swimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Baloncuk dalgalanması
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Konuşma Balonu Giriş Efekti (Zıplayarak ölçeklenme)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // İlk açılışta balonu 800ms sonra çıkar
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _swimController.dispose();
    _bubbleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onFishTapped() {
    if (_isTransitioning) return;

    if (!_isBubbleVisible) {
      setState(() {
        _isBubbleVisible = true;
      });
      _scaleController.forward();
    } else {
      if (widget.messages.isEmpty) return;
      
      // Açıksa sonraki mesaja geçiş yapalım
      _isTransitioning = true;
      _scaleController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % widget.messages.length;
          });
          _scaleController.forward().then((_) {
            _isTransitioning = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMessage = widget.messages.isNotEmpty;
    final displayMessage = hasMessage ? widget.messages[_currentMessageIndex] : "";

    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Konuşma Balonu (Speech Bubble)
          if (_isBubbleVisible && hasMessage)
            ScaleTransition(
              scale: _scaleAnim,
              alignment: const Alignment(0.8, 1.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Balon Gövdesi
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 32, 12), // Sağ tarafa X butonu için yer ayırdık
                        decoration: BoxDecoration(
                          color: AppColors.oceanBlue.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.aqua, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          displayMessage,
                          style: GoogleFonts.fredoka(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                      // Kapatma (X) Butonu
                      Positioned(
                        top: 6,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (_isTransitioning) return;
                            _isTransitioning = true;
                            _scaleController.reverse().then((_) {
                              if (mounted) {
                                setState(() {
                                  _isBubbleVisible = false;
                                  _isTransitioning = false;
                                });
                              }
                            });
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                      // Balon Kuyruğu (3D oyun stili köşeli uç)
                      Positioned(
                        bottom: -6,
                        right: 28,
                        child: Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.oceanBlue,
                              border: const Border(
                                bottom: BorderSide(color: AppColors.aqua, width: 2.5),
                                right: BorderSide(color: AppColors.aqua, width: 2.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Baloncuk Efekti & Rehber Balık
          AnimatedBuilder(
            animation: Listenable.merge([_floatAnim, _swimController, _bubbleController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _onFishTapped,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Küçük Bouncing Yükselen Baloncuklar
                  Positioned(
                    top: -16,
                    left: 10,
                    child: _buildRisingBubble(0.3, 8),
                  ),
                  Positioned(
                    top: -28,
                    right: 14,
                    child: _buildRisingBubble(0.7, 5),
                  ),

                  // Balık Gövdesi (En büyütüldü ve 180 derece döndürüldü / yatay çevrildi)
                  Transform.flip(
                    flipX: true,
                    child: CustomPaint(
                      size: const Size(80, 68), // Eski: Size(62, 52)
                      painter: _GuideFishPainter(
                        swimAnim: _swimController.value,
                        bubbleAnim: _bubbleController.value,
                      ),
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

  Widget _buildRisingBubble(double offset, double radius) {
    final progress = (_bubbleController.value + offset) % 1.0;
    final y = -progress * 24.0;
    final x = sin(progress * 2 * pi) * 6.0;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(x, y),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: AppColors.aqua.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Align(
            alignment: const Alignment(-0.3, -0.3),
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Özel Çizim ile Sarı Rehber Balık (Puffer Fish Stili)
class _GuideFishPainter extends CustomPainter {
  final double swimAnim;
  final double bubbleAnim;

  _GuideFishPainter({required this.swimAnim, required this.bubbleAnim});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2.2;
    final center = Offset(size.width / 2, size.height / 2);

    // Gövde Boyası (Canlı sarı/altın radyal geçiş)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF176), Color(0xFFFBC02D)],
        center: Alignment(-0.25, -0.25),
      ).createShader(Rect.fromCircle(center: center, radius: r));

    final outlinePaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Kuyruk (Kuyruk sallama animasyonlu)
    final tailPaint = Paint()..color = const Color(0xFFFBC02D);
    final tailWiggle = sin(swimAnim * 2 * pi) * 5;
    final tailPath = Path()
      ..moveTo(center.dx - r * 0.7, center.dy)
      ..lineTo(center.dx - r * 1.4, center.dy - r * 0.65 + tailWiggle)
      ..lineTo(center.dx - r * 1.15, center.dy + tailWiggle)
      ..lineTo(center.dx - r * 1.4, center.dy + r * 0.65 + tailWiggle)
      ..close();

    canvas.drawPath(tailPath, tailPaint);
    canvas.drawPath(tailPath, outlinePaint);

    // Gövde Çizimi
    canvas.drawCircle(center, r, bodyPaint);
    canvas.drawCircle(center, r, outlinePaint);

    // Üst Yüzgeç (Sevimli küçük yüzgeç)
    final topFinPaint = Paint()..color = const Color(0xFFFDD835);
    final topFinPath = Path()
      ..moveTo(center.dx - r * 0.3, center.dy - r * 0.8)
      ..lineTo(center.dx - r * 0.5, center.dy - r * 1.2)
      ..lineTo(center.dx + r * 0.1, center.dy - r * 0.9)
      ..close();
    canvas.drawPath(topFinPath, topFinPaint);
    canvas.drawPath(topFinPath, outlinePaint);

    // Alt Yüzgeç
    final bottomFinPaint = Paint()..color = const Color(0xFFFDD835);
    final bottomFinPath = Path()
      ..moveTo(center.dx - r * 0.2, center.dy + r * 0.8)
      ..lineTo(center.dx - r * 0.4, center.dy + r * 1.2)
      ..lineTo(center.dx + r * 0.1, center.dy + r * 0.9)
      ..close();
    canvas.drawPath(bottomFinPath, bottomFinPaint);
    canvas.drawPath(bottomFinPath, outlinePaint);

    // Büyük Sevimli Göz (Balık sağa bakıyor)
    final eyeCenter = Offset(center.dx + r * 0.35, center.dy - r * 0.2);
    canvas.drawCircle(eyeCenter, r * 0.28, Paint()..color = Colors.white);
    canvas.drawCircle(eyeCenter, r * 0.28, outlinePaint);

    // Göz Bebeği (Büyük siyah)
    final pupilCenter = Offset(eyeCenter.dx + 1.5, eyeCenter.dy);
    canvas.drawCircle(pupilCenter, r * 0.14, Paint()..color = Colors.black);

    // Göz Parlaması (Çizgi film parlaması)
    canvas.drawCircle(
      Offset(pupilCenter.dx - 2, pupilCenter.dy - 2),
      r * 0.05,
      Paint()..color = Colors.white,
    );

    // Şeker Pembesi Yanaklar (Blush)
    canvas.drawCircle(
      Offset(center.dx + r * 0.15, center.dy + r * 0.15),
      r * 0.16,
      Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.6),
    );

    // Gülen Ağız
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx + r * 0.55, center.dy + r * 0.12),
      width: r * 0.3,
      height: r * 0.2,
    );
    canvas.drawArc(mouthRect, 0, pi, false, mouthPaint);
  }

  @override
  bool shouldRepaint(_GuideFishPainter old) =>
      old.swimAnim != swimAnim || old.bubbleAnim != bubbleAnim;
}
