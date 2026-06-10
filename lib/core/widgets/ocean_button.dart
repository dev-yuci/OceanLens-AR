import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Okyanus temalı özel buton widget'ı (3D Arcade Görünümlü)
class OceanButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;
  final bool isSmall;
  final double? width;

  const OceanButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isPrimary = true,
    this.isSmall = false,
    this.width,
  });

  @override
  State<OceanButton> createState() => _OceanButtonState();
}

class _OceanButtonState extends State<OceanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // 3D basılma hissi için aşağı doğru 4 piksellik öteleme
    _translateAnim = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _translateAnim,
        builder: (context, child) {
          final dy = _translateAnim.value;
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          padding: EdgeInsets.only(
            left: widget.isSmall ? 18 : 28,
            right: widget.isSmall ? 18 : 28,
            top: widget.isSmall ? 10 : 14,
            bottom: widget.isSmall ? 10 : 18, // 3D gölge payı
          ),
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? AppColors.aquaGradient : null,
            color: widget.isPrimary ? null : AppColors.oceanBlue.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(widget.isSmall ? 16 : 20),
            border: Border.all(
              color: widget.isPrimary ? AppColors.white : AppColors.teal,
              width: widget.isPrimary ? 2.5 : 2.0,
            ),
            boxShadow: [
              // 3D Sert Alt Kenar (Basıldıkça yüksekliği azalan gölge)
              BoxShadow(
                color: widget.isPrimary
                    ? const Color(0xFF0369A1) // Koyu aqua
                    : const Color(0xFF0B192C), // Koyu lacivert
                offset: Offset(0, 6 - _translateAnim.value),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              // Hafif yumuşak gölge
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 8),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.isSmall ? 16 : 20,
                  color: widget.isPrimary
                      ? AppColors.deepOcean
                      : AppColors.lightAqua,
                ),
                SizedBox(width: widget.isSmall ? 6 : 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: widget.isSmall ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: widget.isPrimary
                      ? AppColors.deepOcean
                      : AppColors.lightAqua,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parlayan tombul info chip
class OceanChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const OceanChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
