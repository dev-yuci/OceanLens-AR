import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/quiz/data/quiz_storage.dart';
import 'package:ocean_lens_ar/features/aquarium/data/aquarium_storage.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';

class AquariumSticker {
  final String id;
  final String name;
  final String emoji;
  final int scoreRequired;

  const AquariumSticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.scoreRequired,
  });
}

const List<AquariumSticker> availableStickers = [
  AquariumSticker(id: 'levrek', name: 'Levrek', emoji: '🐟', scoreRequired: 0),
  AquariumSticker(id: 'japon', name: 'Japon Balığı', emoji: '🐡', scoreRequired: 0),
  AquariumSticker(id: 'palyaco', name: 'Palyaço Balığı', emoji: '🐠', scoreRequired: 0),
  AquariumSticker(id: 'denizati', name: 'Denizatı', emoji: '🦑', scoreRequired: 40),
  AquariumSticker(id: 'ahtapot', name: 'Ahtapot', emoji: '🐙', scoreRequired: 40),
  AquariumSticker(id: 'denizyildizi', name: 'Denizyıldızı', emoji: '⭐', scoreRequired: 40),
  AquariumSticker(id: 'cipura', name: 'Çipura', emoji: '🐟', scoreRequired: 80),
  AquariumSticker(id: 'cekicbas', name: 'Çekiçbaş', emoji: '🦈', scoreRequired: 80),
  AquariumSticker(id: 'yengec', name: 'Yengeç', emoji: '🦀', scoreRequired: 80),
  AquariumSticker(id: 'buyukbeyaz', name: 'Büyük Beyaz', emoji: '🦈', scoreRequired: 120),
  AquariumSticker(id: 'balinakopek', name: 'Balina Köpek.', emoji: '🦈', scoreRequired: 120),
  AquariumSticker(id: 'denizkaplumbagasi', name: 'Kaplumbağa', emoji: '🐢', scoreRequired: 120),
  AquariumSticker(id: 'megalodon', name: 'Megalodon', emoji: '🦈', scoreRequired: 160),
  AquariumSticker(id: 'mavibalina', name: 'Mavi Balina', emoji: '🐋', scoreRequired: 160),
  AquariumSticker(id: 'denizkizi', name: 'Denizkızı', emoji: '🧜‍♀️', scoreRequired: 200),
];

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  State<AquariumScreen> createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  int _quizScore = 0;
  List<PlacedSticker> _placedStickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _loadInitialData();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final score = await QuizStorage.loadScore();
    final savedStickers = await AquariumStorage.loadStickers();
    if (mounted) {
      setState(() {
        _quizScore = score;
        _placedStickers = savedStickers;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLayout() async {
    await AquariumStorage.saveStickers(_placedStickers);
  }

  void _addSticker(AquariumSticker sticker, double width, double height) {
    HapticFeedback.lightImpact();
    setState(() {
      _placedStickers.add(
        PlacedSticker(
          id: sticker.id,
          name: sticker.name,
          emoji: sticker.emoji,
          x: width / 2 - 25,
          y: height / 2 - 25,
          scale: 1.0,
        ),
      );
    });
    _saveLayout();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${sticker.name} eklendi! Taşıyabilir veya büyütebilirsin.',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.teal,
      ),
    );
  }

  void _cycleScale(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      final double current = _placedStickers[index].scale;
      if (current == 1.0) {
        _placedStickers[index].scale = 1.4;
      } else if (current == 1.4) {
        _placedStickers[index].scale = 1.8;
      } else if (current == 1.8) {
        _placedStickers[index].scale = 2.2;
      } else if (current == 2.2) {
        _placedStickers[index].scale = 0.7;
      } else {
        _placedStickers[index].scale = 1.0;
      }
    });
    _saveLayout();
  }

  void _deleteSticker(int index) {
    HapticFeedback.mediumImpact();
    final name = _placedStickers[index].name;
    setState(() {
      _placedStickers.removeAt(index);
    });
    _saveLayout();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name akvaryumdan çıkarıldı.',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _clearAll() {
    if (_placedStickers.isEmpty) return;
    AudioService.instance.playClick();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkOcean,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.teal, width: 2.5),
          ),
          title: Text(
            'Akvaryumu Temizle 🧼',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w800,
              color: AppColors.pearl,
            ),
          ),
          content: Text(
            'Akvaryumdaki tüm balıkları kaldırmak istediğine emin misin?',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: AppColors.silver,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playClick();
                Navigator.pop(context);
              },
              child: Text(
                'İptal',
                style: GoogleFonts.fredoka(color: Colors.white60, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                AudioService.instance.playClick();
                HapticFeedback.vibrate();
                setState(() {
                  _placedStickers.clear();
                });
                _saveLayout();
                Navigator.pop(context);
              },
              child: Text(
                'Temizle',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          // Baloncuklu su altı arka planı
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _AquariumBackgroundPainter(_bgController.value),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.aqua))
          else
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildHelperTip(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Stack(
                                children: [
                                  // Boşken kılavuz yazı
                                  if (_placedStickers.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🌿', style: TextStyle(fontSize: 48)),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Akvaryumun bomboş!\nAşağıdan balık ekleyip sürüklemeye başla.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.fredoka(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white54,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Çıkartmaların listesi
                                  ...List.generate(_placedStickers.length, (index) {
                                    final sticker = _placedStickers[index];
                                    return Positioned(
                                      left: sticker.x,
                                      top: sticker.y,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            // Ekran dışına tamamen taşmayı önle
                                            sticker.x = (sticker.x + details.delta.dx).clamp(
                                                -20, constraints.maxWidth - 30);
                                            sticker.y = (sticker.y + details.delta.dy).clamp(
                                                -20, constraints.maxHeight - 30);
                                          });
                                        },
                                        onPanEnd: (_) => _saveLayout(),
                                        onDoubleTap: () => _cycleScale(index),
                                        onLongPress: () => _deleteSticker(index),
                                        child: Transform.scale(
                                          scale: sticker.scale,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.aqua.withValues(alpha: 0.25),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              sticker.emoji,
                                              style: const TextStyle(fontSize: 48),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStickerShelf(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(color: AppColors.teal, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),

          // Başlık
          Text(
            'Okyanus Akvaryumum',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          // Temizleme Butonu
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(
                  color: _placedStickers.isEmpty ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.7),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: _placedStickers.isEmpty ? Colors.white24 : Colors.redAccent,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperTip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Sürükle: Taşı  •  Çift Tıkla: Büyüt/Küçült  •  Basılı Tut: Çıkar',
        style: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.lightSeafoam.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStickerShelf() {
    return Container(
      width: double.infinity,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        border: const Border(top: BorderSide(color: AppColors.teal, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Çıkartma Kutum 🐠',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.aqua,
                  ),
                ),
                Text(
                  'Yarışma Puanın: $_quizScore ⭐',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableStickers.length,
                  itemBuilder: (context, i) {
                    final sticker = availableStickers[i];
                    final bool isUnlocked = _quizScore >= sticker.scoreRequired;

                    return GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          AudioService.instance.playClick();
                          // Akvaryum alanının boyutlarını al ve sticker ekle
                          // Yükseklik/genişlik verilerini üst stack alanından dinamik hesaplayacağız
                          final size = MediaQuery.of(context).size;
                          _addSticker(sticker, size.width, size.height - 250);
                        } else {
                          AudioService.instance.playWrong();
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Bu çıkartmanın kilidini açmak için bilgi yarışmasında ${sticker.scoreRequired} puan almalısın!',
                                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppColors.darkOcean.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUnlocked
                                ? AppColors.teal.withValues(alpha: 0.4)
                                : Colors.white10,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sticker.emoji,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: isUnlocked ? null : Colors.white24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sticker.name,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isUnlocked ? AppColors.pearl : Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                            if (!isUnlocked)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 10,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AquariumBackgroundPainter extends CustomPainter {
  final double anim;
  _AquariumBackgroundPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    // Dip kum tepesi
    final sandPaint = Paint()..color = const Color(0xFFE3C485).withValues(alpha: 0.25);
    final sandPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.78, size.width * 0.5, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.86, size.width, size.height * 0.81)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(sandPath, sandPaint);

    // Su altı ışık hüzmeleri
    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final offset = i * size.width * 0.3 + sin(anim * 2 * pi) * 20;
      final path = Path()
        ..moveTo(offset, 0)
        ..lineTo(offset + size.width * 0.15, 0)
        ..lineTo(offset + size.width * 0.35, size.height)
        ..lineTo(offset + size.width * 0.1, size.height)
        ..close();
      canvas.drawPath(path, lightPaint);
    }

    // Yosunlar (Sol ve Sağ Köşelerde)
    _drawSeaweed(canvas, size.width * 0.1, size.height * 0.85, 90, 8);
    _drawSeaweed(canvas, size.width * 0.88, size.height * 0.83, 110, 10);

    // Yükselen baloncuklar
    _drawBubbles(canvas, size);
  }

  void _drawSeaweed(Canvas canvas, double x, double y, double height, int segments) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    final path = Path()..moveTo(x, y);
    for (int i = 0; i < segments; i++) {
      final double progress = i / segments;
      final double wave = sin(progress * pi * 1.5 + anim * 2 * pi) * 12;
      path.lineTo(x + wave, y - progress * height);
    }
    canvas.drawPath(path, paint);
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bubbleColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bubbles = [
      {'x': 0.22, 'radius': 11.0, 'offset': 0.1},
      {'x': 0.78, 'radius': 15.0, 'offset': 0.4},
      {'x': 0.52, 'radius': 13.0, 'offset': 0.8},
      {'x': 0.35, 'radius': 7.0, 'offset': 0.25},
      {'x': 0.62, 'radius': 10.0, 'offset': 0.55},
    ];

    for (final b in bubbles) {
      final progress = ((anim + (b['offset'] as num).toDouble()) % 1.0);
      final y = size.height * (1.1 - progress * 1.2);
      final x = size.width * (b['x'] as num).toDouble() + sin(progress * 2 * pi * 2) * 8;
      final r = (b['radius'] as num).toDouble();
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_AquariumBackgroundPainter old) => old.anim != anim;
}
