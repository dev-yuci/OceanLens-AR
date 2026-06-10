import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';

/// Ana menüdeki büyük navigasyon kartı (3D Çocuk ve Oyun Temalı)
class NavCard extends StatefulWidget {
  final dynamic data; // _NavCardData
  final VoidCallback onTap;

  const NavCard({super.key, required this.data, required this.onTap});

  @override
  State<NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<NavCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _translateAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
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
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _translateAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateAnim.value),
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 130),
          margin: const EdgeInsets.only(bottom: 8), // 3D gölge payı
          decoration: BoxDecoration(
            gradient: widget.data.gradient as LinearGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.white,
              width: 3.0, // Kalın çizgi film kenarlık
            ),
            boxShadow: [
              // 3D Ekstrüzyon Gölgesi
              BoxShadow(
                color: (widget.data.accentColor as Color).withValues(alpha: 0.8),
                offset: Offset(0, 8 - _translateAnim.value),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              // Yumuşak derinlik gölgesi
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 10),
                blurRadius: 14,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Sağ köşe dekoratif daireler (Oyun baloncukları)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.data.accentColor as Color).withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.data.accentColor as Color).withValues(alpha: 0.07),
                    ),
                  ),
                ),

                // İçerik
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // İkon (Kabartma Oyun Jetonu/Rozet gibi)
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: (widget.data.accentColor as Color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: widget.data.accentColor as Color,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.data.accentColor as Color).withValues(alpha: 0.15),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Icon(
                          widget.data.icon as IconData,
                          color: AppColors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Metin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rozet/Etiket
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (widget.data.accentColor as Color)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.data.accentColor as Color,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                widget.data.tag as String,
                                style: GoogleFonts.fredoka(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.data.title as String,
                              style: GoogleFonts.fredoka(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pearl,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.data.subtitle as String,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.silver.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Ok ikonu (Tombul buton dairesi)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
