import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';

class EatBubble extends PositionComponent with HasGameReference<OceanGame> {
  late Vector2 _velocity;
  double _opacity = 1.0;
  final double _lifeTime = 0.6;
  double _timer = 0;
  final double radius;

  EatBubble({required Vector2 position, required this.radius})
      : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center) {
    final rand = Random();
    final angle = rand.nextDouble() * 2 * pi;
    final speed = 60.0 + rand.nextDouble() * 90.0;
    _velocity = Vector2(cos(angle) * speed, sin(angle) * speed - 45.0); // Sağa sola ve yukarı fırlama
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    position += _velocity * dt;
    _opacity = (1.0 - _timer / _lifeTime).clamp(0.0, 1.0);
    if (_timer >= _lifeTime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: _opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: _opacity * 0.4);
    canvas.drawCircle(Offset(radius * 0.7, radius * 0.7), radius * 0.22, highlightPaint);
  }
}
