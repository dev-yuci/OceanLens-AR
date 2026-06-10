import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/features/game/components/player_fish.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';

class JellyfishObstacle extends PositionComponent
    with CollisionCallbacks, HasGameReference<OceanGame> {
  static const double baseRadius = 20.0;
  double _animTime = 0;
  late Vector2 _velocity;
  bool _isFading = false;
  double _fadeTimer = 0;
  double _opacity = 1.0;

  JellyfishObstacle({required Vector2 position})
      : super(position: position, size: Vector2.all(baseRadius * 2), anchor: Anchor.center) {
    // Rastgele yatay hız ve yön
    final random = Random();
    final speedX = (random.nextBool() ? 1 : -1) * (20 + random.nextDouble() * 30);
    _velocity = Vector2(speedX, 0);
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: baseRadius));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (_isFading) {
      _fadeTimer += dt;
      _opacity = (1.0 - _fadeTimer / 0.4).clamp(0.0, 1.0);
      if (_fadeTimer > 0.4) {
        removeFromParent();
      }
      return;
    }

    // Yatay salınım ve dikey süzülüş
    position.x += _velocity.x * dt;
    position.y += sin(_animTime * 3) * 15 * dt;

    // Ekran kenarlarından dolanma
    final gameWidth = game.size.x;
    if (position.x < -baseRadius * 2) {
      position.x = gameWidth + baseRadius;
    } else if (position.x > gameWidth + baseRadius * 2) {
      position.x = -baseRadius;
    }

    // Oyun durduysa sil
    if (game.gameState != GameState.playing) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerFish && !_isFading) {
      other.stun();
      // Çarpılma sonrasında yok olma animasyonu tetikle
      _isFading = true;
      children.whereType<CircleHitbox>().forEach((h) => h.removeFromParent());
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    final center = Offset(baseRadius, baseRadius);

    // Denizanası süzülme animasyon ölçeği
    final pulseScaleY = 1.0 + sin(_animTime * 3.5) * 0.12;
    final pulseScaleX = 1.0 - sin(_animTime * 3.5) * 0.06;
    canvas.scale(pulseScaleX, pulseScaleY);

    // Parlama neon efekti
    final glowPaint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.25 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, baseRadius * 1.2, glowPaint);

    // Kubbe Boyası (Pembe şirin degradeli)
    final domePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.pinkAccent.withValues(alpha: 0.8 * _opacity),
          const Color(0xFFFF4081).withValues(alpha: 0.35 * _opacity),
        ],
        center: const Alignment(0, -0.25),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    // Kubbe Yolu (Şapka)
    final domePath = Path()
      ..arcTo(Rect.fromCircle(center: center, radius: baseRadius), pi, pi, true)
      ..quadraticBezierTo(center.dx, center.dy + baseRadius * 0.25, center.dx + baseRadius, center.dy)
      ..close();

    canvas.drawPath(domePath, domePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(domePath, borderPaint);

    // Sevimli küçük gözler
    final leftEye = Offset(center.dx - baseRadius * 0.35, center.dy - baseRadius * 0.15);
    final rightEye = Offset(center.dx + baseRadius * 0.35, center.dy - baseRadius * 0.15);
    canvas.drawCircle(leftEye, baseRadius * 0.1, Paint()..color = Colors.white.withValues(alpha: _opacity));
    canvas.drawCircle(rightEye, baseRadius * 0.1, Paint()..color = Colors.white.withValues(alpha: _opacity));
    canvas.drawCircle(leftEye, baseRadius * 0.05, Paint()..color = Colors.black.withValues(alpha: _opacity));
    canvas.drawCircle(rightEye, baseRadius * 0.05, Paint()..color = Colors.black.withValues(alpha: _opacity));

    // Dalgalı bacaklar/dokunaçlar
    final tentaclePaint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.65 * _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final whiteLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.45 * _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final startX = center.dx - baseRadius * 0.55 + (i * baseRadius * 0.55);
      final tentaclePath = Path()..moveTo(startX, center.dy + baseRadius * 0.1);

      // Bacak dalgalanma efekti
      final waveOffset = sin(_animTime * 6.5 + i) * 6;

      tentaclePath.cubicTo(
        startX - 4 + waveOffset * 0.5,
        center.dy + baseRadius * 0.6,
        startX + 4 + waveOffset,
        center.dy + baseRadius * 1.1,
        startX + waveOffset * 0.8,
        center.dy + baseRadius * 1.55,
      );
      canvas.drawPath(tentaclePath, tentaclePaint);
      canvas.drawPath(tentaclePath, whiteLine);
    }

    canvas.restore();
  }
}
