import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';

class PlayerFish extends PositionComponent
    with CollisionCallbacks, HasGameReference<OceanGame> {
  static const double _baseSize = 28.0;
  static const double _maxSpeed = 220.0;

  double fishSize = 1.0;    // Balık büyüklük çarpanı
  Vector2 _targetPos;
  bool _facingRight = true;
  double _animTime = 0;
  bool _isInvincible = false;
  double _invincibleTimer = 0;
  static const double _invincibleDuration = 1.5;

  // Güçlendiriciler ve Engellerin Durum Değişkenleri
  bool isShieldActive = false;
  double shieldTimer = 0.0;
  bool isSpeedBoostActive = false;
  double speedBoostTimer = 0.0;
  bool isStunned = false;
  double stunTimer = 0.0;
  double _scaleBounceTimer = 0.0;

  PlayerFish({required Vector2 startPos})
      : _targetPos = startPos.clone(),
        super(position: startPos);

  double get radius => _baseSize * fishSize;
  bool get isInvincible => _isInvincible;

  @override
  Future<void> onLoad() async {
    _updateHitbox();
  }

  void _updateHitbox() {
    children.whereType<CircleHitbox>().forEach((h) => h.removeFromParent());
    add(CircleHitbox(radius: radius * 0.75));
  }

  void moveTo(Vector2 target) {
    _targetPos = target.clone();
  }

  void grow() {
    fishSize = (fishSize + 0.04).clamp(0.5, 4.0);
    _updateHitbox();
    _scaleBounceTimer = 0.25;
  }

  void takeDamage() {
    if (isShieldActive) {
      isShieldActive = false;
      shieldTimer = 0;
      // Kalkan kırılınca kısa süreli dokunulmazlık ve titreşim
      HapticFeedback.mediumImpact();
      _isInvincible = true;
      _invincibleTimer = 0.8;
      return;
    }
    if (_isInvincible) return;
    _isInvincible = true;
    _invincibleTimer = _invincibleDuration;
    HapticFeedback.vibrate(); // Hasar alındığında telefon titrer
    game.onPlayerHit();
  }

  void activateShield() {
    isShieldActive = true;
    shieldTimer = 8.0;
  }

  void activateSpeedBoost() {
    isSpeedBoostActive = true;
    speedBoostTimer = 6.0;
  }

  void stun() {
    if (isShieldActive) {
      // Kalkan sersemlemeyi engeller
      isShieldActive = false;
      shieldTimer = 0;
      HapticFeedback.mediumImpact();
      _isInvincible = true;
      _invincibleTimer = 0.8;
      return;
    }
    isStunned = true;
    stunTimer = 1.2;
    HapticFeedback.vibrate(); // Elektrik şokunda telefon titrer
  }

  @override
  void update(double dt) {
    _animTime += dt;

    // Hedefe doğru hareket
    final dx = _targetPos.x - position.x;
    final dy = _targetPos.y - position.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > 5) {
      double currentSpeed = _maxSpeed;
      if (isStunned) {
        currentSpeed *= 0.2; // %80 yavaşlama
      } else if (isSpeedBoostActive) {
        currentSpeed *= 1.6; // %60 hızlanma
      }

      final speed = currentSpeed * dt;
      position.x += (dx / dist) * speed;
      position.y += (dy / dist) * speed;
      _facingRight = dx > 0;
    }

    // Ekran sınırları
    position.x = position.x.clamp(radius, game.size.x - radius);
    position.y = position.y.clamp(radius, game.size.y - radius);

    // Kırılmazlık süresi
    if (_isInvincible) {
      _invincibleTimer -= dt;
      if (_invincibleTimer <= 0) {
        _isInvincible = false;
      }
    }

    // Kalkan süresi azaltma
    if (isShieldActive) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) {
        isShieldActive = false;
      }
    }

    // Hız güçlendirme süresi azaltma
    if (isSpeedBoostActive) {
      speedBoostTimer -= dt;
      if (speedBoostTimer <= 0) {
        isSpeedBoostActive = false;
      }
    }

    // Sersemleme süresi azaltma
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
    }

    // Büyüme sıçraması süresi azaltma
    if (_scaleBounceTimer > 0) {
      _scaleBounceTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final bool blink = _isInvincible && ((_invincibleTimer * 8).floor() % 2 == 0);
    final bool stunBlink = isStunned && ((stunTimer * 10).floor() % 2 == 0);
    if (blink) return;

    canvas.save();

    // Yüzme animasyonu (hafif salınım)
    final bodyAngle = sin(_animTime * 5) * 0.06;
    canvas.rotate(bodyAngle);

    if (!_facingRight) {
      canvas.scale(-1, 1);
    }

    // Büyüme sıçraması animasyonlu ölçeği
    final scaleBounce = _scaleBounceTimer > 0
        ? 1.0 + sin((_scaleBounceTimer / 0.25) * pi) * 0.15
        : 1.0;
    canvas.scale(scaleBounce);

    // Sersemlemişken sarı yanıp söner
    final fishColor = stunBlink ? Colors.amberAccent : AppColors.fishPlayer;
    _drawFish(canvas, fishColor, radius, true, _animTime);

    canvas.restore();

    // Kalkan Efekti Çizimi
    if (isShieldActive) {
      final shieldPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset.zero, radius * 1.35, shieldPaint);

      final shieldFill = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.07);
      canvas.drawCircle(Offset.zero, radius * 1.35, shieldFill);
    }

    // Hız Efekti Çizimi (Arkada küçük baloncuk dalgası)
    if (isSpeedBoostActive && _facingRight) {
      // Sola doğru baloncuk halkaları
      final boostPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(-radius * 1.5, 0), radius * 0.3 * (1 + sin(_animTime * 10).abs()), boostPaint);
    } else if (isSpeedBoostActive && !_facingRight) {
      // Sağa doğru baloncuk halkaları
      final boostPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(radius * 1.5, 0), radius * 0.3 * (1 + sin(_animTime * 10).abs()), boostPaint);
    }
  }

  static void _drawFish(Canvas canvas, Color color, double r, bool isPlayer, double animTime) {
    // Parlama efekti (oyuncu için)
    if (isPlayer) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.6, height: r * 1.3),
        glowPaint,
      );
    }

    final darkShade = Color.alphaBlend(Colors.black.withValues(alpha: 0.25), color);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.95), darkShade.withValues(alpha: 0.85)],
        center: const Alignment(-0.2, -0.25),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.08).clamp(1.5, 4.0);

    // 1. Kuyruk (Wavy and playful)
    final tailPaint = Paint()..color = color.withValues(alpha: 0.8);
    final tailPath = Path()
      ..moveTo(-r * 0.8, 0)
      ..cubicTo(-r * 1.25, -r * 0.55, -r * 1.7, -r * 0.85, -r * 1.6, -r * 0.65)
      ..cubicTo(-r * 1.5, -r * 0.25, -r * 1.8, 0, -r * 1.45, 0)
      ..cubicTo(-r * 1.8, 0, -r * 1.5, r * 0.25, -r * 1.6, r * 0.65)
      ..cubicTo(-r * 1.7, r * 0.85, -r * 1.25, r * 0.55, -r * 0.8, 0)
      ..close();
    canvas.drawPath(tailPath, tailPaint);
    canvas.drawPath(tailPath, borderPaint);

    // 2. Sırt Yüzgeci (Dorsal Fin)
    final finPaint = Paint()..color = color.withValues(alpha: 0.85);
    final finPath = Path()
      ..moveTo(-r * 0.25, -r * 0.5)
      ..quadraticBezierTo(-r * 0.05, -r * 1.1, r * 0.25, -r * 0.85)
      ..quadraticBezierTo(r * 0.1, -r * 0.55, r * 0.15, -r * 0.5)
      ..close();
    canvas.drawPath(finPath, finPaint);
    canvas.drawPath(finPath, borderPaint);

    // 3. Gövde
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.1),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.1),
      borderPaint,
    );

    // 4. Gövde Çizgileri (Nemo stili dalgalı çizgiler)
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.1).clamp(1.5, 4.0)
      ..strokeCap = StrokeCap.round;

    final stripePath1 = Path()
      ..moveTo(-r * 0.15, -r * 0.45)
      ..quadraticBezierTo(-r * 0.05, 0, -r * 0.15, r * 0.45);
    final stripePath2 = Path()
      ..moveTo(r * 0.15, -r * 0.42)
      ..quadraticBezierTo(r * 0.25, 0, r * 0.15, r * 0.42);
    canvas.drawPath(stripePath1, stripePaint);
    canvas.drawPath(stripePath2, stripePaint);

    // 5. Yan Yüzgeç (Pectoral Fin - animasyonlu)
    final finWiggle = sin(animTime * 12) * 0.25;
    canvas.save();
    canvas.translate(-r * 0.1, r * 0.15);
    canvas.rotate(finWiggle);
    final sideFinPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-r * 0.4, r * 0.35)
      ..lineTo(r * 0.02, r * 0.45)
      ..close();
    canvas.drawPath(sideFinPath, finPaint);
    canvas.drawPath(sideFinPath, borderPaint);
    canvas.restore();

    // 6. Gözler (Büyük şirin çizgi film gözü)
    final eyeCenter = Offset(r * 0.52, -r * 0.15);
    canvas.drawCircle(eyeCenter, r * 0.24, Paint()..color = Colors.white);
    canvas.drawCircle(eyeCenter, r * 0.24, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = (r * 0.05).clamp(1.0, 3.0));

    final pupilCenter = Offset(eyeCenter.dx + r * 0.05, eyeCenter.dy);
    canvas.drawCircle(pupilCenter, r * 0.12, Paint()..color = Colors.black);
    // Göz Parlaması
    canvas.drawCircle(Offset(pupilCenter.dx - r * 0.04, pupilCenter.dy - r * 0.04), r * 0.045, Paint()..color = Colors.white);

    // Yanak Allık
    canvas.drawCircle(
      Offset(r * 0.35, r * 0.12),
      r * 0.14,
      Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.4),
    );

    // Ağız (Gülümseme)
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.06).clamp(1.5, 3.5)
      ..strokeCap = StrokeCap.round;
    final mouthRect = Rect.fromCenter(
      center: Offset(r * 0.72, r * 0.15),
      width: r * 0.25,
      height: r * 0.18,
    );
    canvas.drawArc(mouthRect, 0, pi, false, mouthPaint);
  }

  // NPC için statik çizim metodu
  static void drawNpcFish(Canvas canvas, Color color, double r, double animTime) {
    _drawFish(canvas, color, r, false, animTime);
  }
}
