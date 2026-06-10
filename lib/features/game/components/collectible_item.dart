import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/features/game/components/player_fish.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';

enum CollectibleType { shield, speedBoost, star, heart }

class CollectibleItem extends PositionComponent
    with CollisionCallbacks, HasGameReference<OceanGame> {
  final CollectibleType type;
  static const double itemRadius = 16.0;
  double _animTime = 0;

  CollectibleItem({required this.type, required Vector2 position})
      : super(position: position, size: Vector2.all(itemRadius * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: itemRadius));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    // Yavaşça dikey yönde yüzer (salınım)
    position.y += sin(_animTime * 2.5) * 8 * dt;

    // Eğer oyun biterse veya durursa sil
    if (game.gameState != GameState.playing) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerFish) {
      switch (type) {
        case CollectibleType.shield:
          other.activateShield();
          game.score += 25;
          break;
        case CollectibleType.speedBoost:
          other.activateSpeedBoost();
          game.score += 25;
          break;
        case CollectibleType.star:
          other.grow();
          game.score += 100;
          break;
        case CollectibleType.heart:
          game.healPlayer();
          game.score += 25;
          break;
      }
      game.onScoreChanged?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Hafif büyüme/küçülme animasyonu
    final scale = 1.0 + sin(_animTime * 4) * 0.08;
    canvas.scale(scale);

    final center = Offset(itemRadius, itemRadius);

    switch (type) {
      case CollectibleType.shield:
        _drawShield(canvas, center);
        break;
      case CollectibleType.speedBoost:
        _drawSpeedBoost(canvas, center);
        break;
      case CollectibleType.star:
        _drawStar(canvas, center);
        break;
      case CollectibleType.heart:
        _drawHeart(canvas, center);
        break;
    }

    canvas.restore();
  }

  void _drawShield(Canvas canvas, Offset center) {
    // Parlama
    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, itemRadius * 1.3, glowPaint);

    final bgPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, itemRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, itemRadius, borderPaint);

    // Kalkan ikonu
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - itemRadius * 0.45)
      ..lineTo(center.dx + itemRadius * 0.35, center.dy - itemRadius * 0.45)
      ..lineTo(center.dx + itemRadius * 0.35, center.dy)
      ..quadraticBezierTo(center.dx + itemRadius * 0.35, center.dy + itemRadius * 0.4, center.dx, center.dy + itemRadius * 0.65)
      ..quadraticBezierTo(center.dx - itemRadius * 0.35, center.dy + itemRadius * 0.4, center.dx - itemRadius * 0.35, center.dy)
      ..lineTo(center.dx - itemRadius * 0.35, center.dy - itemRadius * 0.45)
      ..close();
    canvas.drawPath(path, iconPaint);
  }

  void _drawSpeedBoost(Canvas canvas, Offset center) {
    // Parlama
    final glowPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, itemRadius * 1.3, glowPaint);

    final bgPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, itemRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, itemRadius, borderPaint);

    // Yıldırım ikonu
    final boltPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx + itemRadius * 0.1, center.dy - itemRadius * 0.5)
      ..lineTo(center.dx - itemRadius * 0.25, center.dy + itemRadius * 0.05)
      ..lineTo(center.dx + itemRadius * 0.02, center.dy + itemRadius * 0.05)
      ..lineTo(center.dx - itemRadius * 0.1, center.dy + center.dy * 0.05)
      ..lineTo(center.dx - itemRadius * 0.08, center.dy + itemRadius * 0.5)
      ..lineTo(center.dx + itemRadius * 0.28, center.dy - itemRadius * 0.05)
      ..lineTo(center.dx + itemRadius * 0.02, center.dy - itemRadius * 0.05)
      ..close();
    canvas.drawPath(path, boltPaint);
  }

  void _drawStar(Canvas canvas, Offset center) {
    // Parlama
    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, itemRadius * 1.3, glowPaint);

    final bgPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, itemRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, itemRadius, borderPaint);

    // Yıldız ikonu
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path();
    const int points = 5;
    const double outerRadius = itemRadius * 0.6;
    const double innerRadius = itemRadius * 0.28;
    const double step = pi / points;
    double angle = -pi / 2;

    path.moveTo(center.dx + cos(angle) * outerRadius, center.dy + sin(angle) * outerRadius);
    for (int i = 0; i < points * 2; i++) {
      angle += step;
      final r = (i % 2 == 0) ? innerRadius : outerRadius;
      path.lineTo(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
    }
    path.close();
    canvas.drawPath(path, starPaint);
  }

  void _drawHeart(Canvas canvas, Offset center) {
    // Parlama
    final glowPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, itemRadius * 1.3, glowPaint);

    final bgPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, itemRadius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, itemRadius, borderPaint);

    // Kalp şekli çizimi
    final heartPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = itemRadius * 0.95;
    final h = itemRadius * 0.95;
    
    path.moveTo(center.dx, center.dy - h * 0.25);
    // Sol kulakçık
    path.cubicTo(
      center.dx - w * 0.5, center.dy - h * 0.65,
      center.dx - w * 0.9, center.dy - h * 0.1,
      center.dx, center.dy + h * 0.5,
    );
    // Sağ kulakçık
    path.cubicTo(
      center.dx + w * 0.9, center.dy - h * 0.1,
      center.dx + w * 0.5, center.dy - h * 0.65,
      center.dx, center.dy - h * 0.25,
    );
    path.close();
    canvas.drawPath(path, heartPaint);
  }
}
