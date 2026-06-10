import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/core/router/app_router.dart';
import 'package:ocean_lens_ar/core/widgets/ocean_guide_fish.dart';
import 'package:ocean_lens_ar/features/museum/data/fish_data.dart';
import 'package:ocean_lens_ar/features/museum/models/fish_model.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';

class MuseumScreen extends StatefulWidget {
  const MuseumScreen({super.key});

  @override
  State<MuseumScreen> createState() => _MuseumScreenState();
}

class _MuseumScreenState extends State<MuseumScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';

  final List<String> _filters = ['Tümü', 'Yaygın', 'Nadir', 'Mevsimsel', 'Çok Yaygın'];

  List<FishModel> get _filteredFish {
    return fishDatabase.where((f) {
      final matchesSearch = f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'Tümü' || f.rarity == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          // Baloncuklu müze arka planı
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _MuseumBgPainter(_bgController.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchBar(),
                _buildFilterChips(),
                const SizedBox(height: 12),
                Expanded(child: _buildFishGrid()),
              ],
            ),
          ),
          const OceanGuideFish(
            messages: [
              "Denizlerimizdeki en tatlı balıkları listeledim! Merak ettiğin balığa dokunup onun sırlarını öğrenebilirsin! 📖",
              "En nadir balıkları bulmak için yukarıdaki filtreleri kullanabilirsin! 🔍",
              "Bazı balıklar sadece belirli mevsimlerde görünür, onları bulabilir misin? 🍂",
              "Tüm balıkları inceleyip hepsi hakkında bilgi edinmeye çalış! 🎓",
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              context.pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.oceanBlue.withValues(alpha: 0.6),
                border: Border.all(color: AppColors.teal, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  )
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balık Müzesi',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pearl,
                      letterSpacing: -0.3,
                    )),
                Text('${fishDatabase.length} Eğlenceli Deniz Türü',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: AppColors.lightSeafoam,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.lightAqua, size: 16),
                const SizedBox(width: 6),
                Text('Kılavuz',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: AppColors.lightAqua,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.oceanBlue.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.teal, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 8,
            )
          ],
        ),
        child: TextField(
          style: GoogleFonts.fredoka(color: AppColors.pearl, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Balık ara... (isim veya bilimsel ad)',
            hintStyle: GoogleFonts.fredoka(
                color: AppColors.silver.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.aqua, size: 22),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final selected = _selectedFilter == _filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () {
                AudioService.instance.playClick();
                setState(() => _selectedFilter = _filters[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.aqua.withValues(alpha: 0.3)
                      : AppColors.oceanBlue.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.white : AppColors.teal,
                    width: 2.0,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.aqua.withValues(alpha: 0.25),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _filters[i],
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.white : AppColors.silver,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFishGrid() {
    final fish = _filteredFish;
    if (fish.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.coral, size: 56),
            const SizedBox(height: 12),
            Text('Bulunamadı! Başka Ara 🐠',
                style: GoogleFonts.fredoka(
                    color: AppColors.silver, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18, // 3D gölge payı için artırıldı
        childAspectRatio: 0.76,
      ),
      itemCount: fish.length,
      itemBuilder: (context, i) {
        return _FishCard(
          fish: fish[i],
          index: i,
          onTap: () {
            AudioService.instance.playClick();
            context.push(
              AppRoutes.fishDetail,
              extra: fish[i],
            );
          },
        );
      },
    );
  }
}

class _FishCard extends StatefulWidget {
  final FishModel fish;
  final int index;
  final VoidCallback onTap;

  const _FishCard({
    required this.fish,
    required this.index,
    required this.onTap,
  });

  @override
  State<_FishCard> createState() => _FishCardState();
}

class _FishCardState extends State<_FishCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _translateAnim = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(widget.fish.colorValue);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _translateAnim,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, _translateAnim.value), child: child),
        child: Hero(
          tag: 'fish_${widget.fish.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.white,
                width: 2.5, // Kalın çizgi roman çerçevesi
              ),
              boxShadow: [
                // 3D katı kenarlık gölgesi
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.9),
                  offset: Offset(0, 6 - _translateAnim.value),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji + nadirlik rozeti
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.fish.emoji,
                            style: const TextStyle(fontSize: 38)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.white,
                                width: 1.5),
                          ),
                          child: Text(
                            widget.fish.rarity,
                            style: GoogleFonts.fredoka(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.fish.name,
                      style: GoogleFonts.fredoka(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.fish.scientificName,
                      style: GoogleFonts.fredoka(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.straighten_rounded,
                            size: 14, color: AppColors.white),
                        const SizedBox(width: 4),
                        Text(
                          widget.fish.length,
                          style: GoogleFonts.fredoka(
                            fontSize: 11,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MuseumBgPainter extends CustomPainter {
  final double anim;
  _MuseumBgPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    // Glow efektleri
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1),
        100 + sin(anim * 2 * pi) * 10, paint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85),
        80 + sin(anim * 2 * pi + pi) * 8,
        Paint()
          ..color = AppColors.seafoam.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50));

    // Kabarcıklar çiz
    _drawBubbles(canvas, size);
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bubbleColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final bubblePositions = [
      {'x': 0.15, 'radius': 12.0, 'offset': 0.1},
      {'x': 0.80, 'radius': 16.0, 'offset': 0.5},
      {'x': 0.45, 'radius': 10.0, 'offset': 0.8},
    ];

    for (final b in bubblePositions) {
      final progress = ((anim + (b['offset'] as num).toDouble()) % 1.0);
      final y = size.height * (1.1 - progress * 1.2);
      final x = size.width * (b['x'] as num).toDouble() + sin(progress * 2 * pi * 2) * 8;
      final r = (b['radius'] as num).toDouble();
      
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x - r * 0.3, y - r * 0.3), r * 0.22, highlight);
    }
  }

  @override
  bool shouldRepaint(_MuseumBgPainter old) => old.anim != anim;
}
