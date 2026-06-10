import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/game/components/player_fish.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';

class NpcFish extends PositionComponent
    with CollisionCallbacks, HasGameReference<OceanGame> {
  static const double _baseSize = 22.0;

  final double fishSize;     // 0.4 – 3.0 arası
  late Vector2 _velocity;
  double _animTime = 0;
  bool _facingRight = true;
  bool _isDead = false;
  double _deathTimer = 0;
  double _opacity = 1.0;

  final Random _random = Random();
  late Color _fishColor;
  late Color _resolvedColor; // oyuncuya göre belirlenir

  NpcFish({required this.fishSize, required Vector2 startPos})
      : super(position: startPos) {
    // Rastgele başlangıç hızı (Hard Difficulty - Daha hızlı balıklar)
    final angle = _random.nextDouble() * 2 * pi;
    final speed = 110.0 + (1 / fishSize) * 60; // küçükler ve tüm balıklar çok daha hızlı
    _velocity = Vector2(cos(angle) * speed, sin(angle) * speed * 0.5);
    _facingRight = _velocity.x > 0;
  }

  double get radius => _baseSize * fishSize;
  bool get isDead => _isDead;

  @override
  Future<void> onLoad() async {
    _resolvedColor = _getColorForSize();
    _fishColor = _resolvedColor;
    add(CircleHitbox(radius: radius * 0.75));
  }

  Color _getColorForSize() {
    final playerRadius = game.player.radius;
    if (radius < playerRadius * 0.85) {
      return AppColors.fishSmall;  // Yenilebilir → yeşil
    } else if (radius > playerRadius * 1.15) {
      return AppColors.fishDanger; // Tehlikeli → kırmızı
    } else {
      return AppColors.fishMedium; // Yakın boyut → sarı
    }
  }

  @override
  void update(double dt) {
    _animTime += dt;

    if (_isDead) {
      _deathTimer += dt;
      _opacity = (1 - _deathTimer / 0.5).clamp(0, 1);
      position.y -= 60 * dt;
      if (_deathTimer > 0.5) {
        removeFromParent();
      }
      return;
    }

    // Rengi dinamik olarak güncelle
    _fishColor = _getColorForSize();

    // Daha büyük balıklar oyuncuya yaklaşır, küçükler kaçar
    final toPlayer = game.player.position - position;
    final distToPlayer = toPlayer.length;

    if (distToPlayer < 250) {
      if (radius > game.player.radius * 1.15) {
        // Oyuncuya doğru yavaşça yürü
        _velocity += toPlayer.normalized() * 30 * dt;
      } else if (radius < game.player.radius * 0.85) {
        // Oyuncudan kaç
        _velocity -= toPlayer.normalized() * 40 * dt;
      }
    }

    // Hız sınırlama (Medium Difficulty)
    final maxSpeed = 100 + (1 / fishSize) * 55;
    if (_velocity.length > maxSpeed) {
      _velocity = _velocity.normalized() * maxSpeed;
    }

    // Hafif dalga hareketi
    _velocity.y += sin(_animTime * 2 + position.x * 0.01) * 8 * dt;

    position += _velocity * dt;
    _facingRight = _velocity.x > 0;

    // Ekrandan çıkınca geri döndür
    final gameInstance = game;
    if (position.x < -radius * 2) {
      position.x = gameInstance.size.x + radius;
    } else if (position.x > gameInstance.size.x + radius * 2) {
      position.x = -radius;
    }
    if (position.y < radius) {
      _velocity.y = _velocity.y.abs();
    } else if (position.y > gameInstance.size.y - radius) {
      _velocity.y = -_velocity.y.abs();
    }
  }

  void die() {
    _isDead = true;
    children.whereType<CircleHitbox>().forEach((h) => h.removeFromParent());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerFish && !_isDead) {
      final player = game.player;

      if (radius <= player.radius) {
        // Oyuncu daha büyük veya eşit → yer
        die();
        game.onFishEaten(fishSize);
        game.spawnEatParticles(position.clone(), radius);
        player.grow();
      } else {
        // NPC daha büyük → zarar ver
        player.takeDamage();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Ölüm animasyonu
    canvas.save();
    canvas.scale(1, 1);

    final opacity = _isDead ? _opacity : 1.0;
    final animAngle = sin(_animTime * 4) * 0.05;
    canvas.rotate(animAngle);

    if (!_facingRight) {
      canvas.scale(-1, 1);
    }

    _drawNpc(canvas, _fishColor.withValues(alpha: opacity), radius);

    canvas.restore();
    canvas.restore();
  }

  void _drawNpc(Canvas canvas, Color color, double r) {
    final playerRadius = game.player.radius;
    final isDanger = radius > playerRadius * 1.15;
    final isEatable = radius < playerRadius * 0.85;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: color.a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.08).clamp(1.2, 4.0);

    final darkShade = Color.alphaBlend(Colors.black.withValues(alpha: 0.25), color);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [color, darkShade],
        center: const Alignment(-0.2, -0.25),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    final finWiggle = sin(_animTime * 12) * 0.25;

    if (isDanger) {
      // 🦈 TEHLİKELİ BALIK: Kızgın Köpekbalığı / Pirana tarzı
      // 1. Sivri Kuyruk
      final tailPaint = Paint()..color = color.withValues(alpha: color.a * 0.85);
      final tailPath = Path()
        ..moveTo(-r * 0.8, 0)
        ..lineTo(-r * 1.6, -r * 0.8)
        ..lineTo(-r * 1.3, 0)
        ..lineTo(-r * 1.6, r * 0.8)
        ..close();
      canvas.drawPath(tailPath, tailPaint);
      canvas.drawPath(tailPath, borderPaint);

      // 2. Keskin Üst Yüzgeç (Shark Fin)
      final dorsalPaint = Paint()..color = color.withValues(alpha: color.a * 0.9);
      final dorsalPath = Path()
        ..moveTo(-r * 0.3, -r * 0.45)
        ..lineTo(-r * 0.5, -r * 1.2)
        ..lineTo(r * 0.1, -r * 0.5)
        ..close();
      canvas.drawPath(dorsalPath, dorsalPaint);
      canvas.drawPath(dorsalPath, borderPaint);

      // 3. Gövde (Uzun/Yassı yırtıcı)
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.3, height: r * 1.05),
        bodyPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.3, height: r * 1.05),
        borderPaint,
      );

      // 4. Yan yüzgeç (Sivri)
      canvas.save();
      canvas.translate(-r * 0.1, r * 0.15);
      canvas.rotate(finWiggle);
      final sideFinPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-r * 0.55, r * 0.3)
        ..lineTo(-r * 0.1, r * 0.4)
        ..close();
      canvas.drawPath(sideFinPath, dorsalPaint);
      canvas.drawPath(sideFinPath, borderPaint);
      canvas.restore();

      // 5. Kızgın Göz (Çekik kırmızı/sarı göz bebekli)
      final eyeCenter = Offset(r * 0.55, -r * 0.18);
      canvas.drawCircle(eyeCenter, r * 0.22, Paint()..color = Colors.white.withValues(alpha: color.a));
      canvas.drawCircle(eyeCenter, r * 0.22, borderPaint);
      
      // Göz bebeği
      canvas.drawCircle(Offset(eyeCenter.dx + 1.5, eyeCenter.dy), r * 0.1, Paint()..color = Colors.red.withValues(alpha: color.a));
      
      // Kızgın Kaş (Eyebrow)
      final browPaint = Paint()
        ..color = Colors.black87.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.08).clamp(1.5, 4.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(eyeCenter.dx - r * 0.3, eyeCenter.dy - r * 0.28),
        Offset(eyeCenter.dx + r * 0.25, eyeCenter.dy - r * 0.1),
        browPaint,
      );

      // 6. Keskin Dişler (Ağız)
      final mouthPaint = Paint()
        ..color = Colors.black87.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.06).clamp(1.5, 3.5);
      final mouthPath = Path()
        ..moveTo(r * 0.45, r * 0.2)
        ..lineTo(r * 0.85, r * 0.2);
      canvas.drawPath(mouthPath, mouthPaint);

      // Sivri dişler
      final toothPaint = Paint()..color = Colors.white.withValues(alpha: color.a);
      final toothPath = Path()
        ..moveTo(r * 0.5, r * 0.2)
        ..lineTo(r * 0.55, r * 0.35)
        ..lineTo(r * 0.6, r * 0.2)
        ..lineTo(r * 0.65, r * 0.35)
        ..lineTo(r * 0.7, r * 0.2)
        ..lineTo(r * 0.75, r * 0.35)
        ..lineTo(r * 0.8, r * 0.2);
      canvas.drawPath(toothPath, toothPaint);
      canvas.drawPath(toothPath, mouthPaint);

    } else if (isEatable) {
      // 🐡 YENİLEBİLİR BALIK: Şirin Tombul Japon/Süs Balığı tarzı
      // 1. Dalgalı Yelpaze Kuyruk
      final tailPaint = Paint()..color = color.withValues(alpha: color.a * 0.8);
      final tailPath = Path()
        ..moveTo(-r * 0.7, 0)
        ..cubicTo(-r * 1.2, -r * 0.7, -r * 1.7, -r * 0.8, -r * 1.5, -r * 0.2)
        ..cubicTo(-r * 1.3, 0, -r * 1.7, r * 0.8, -r * 1.2, r * 0.2)
        ..close();
      canvas.drawPath(tailPath, tailPaint);
      canvas.drawPath(tailPath, borderPaint);

      // 2. Yuvarlak Gövde
      canvas.drawCircle(Offset.zero, r * 1.05, bodyPaint);
      canvas.drawCircle(Offset.zero, r * 1.05, borderPaint);

      // 3. Sırt yüzgeci (Kıvrımlı)
      final dorsalPaint = Paint()..color = color.withValues(alpha: color.a * 0.85);
      final dorsalPath = Path()
        ..moveTo(-r * 0.25, -r * 0.85)
        ..quadraticBezierTo(0, -r * 1.4, r * 0.25, -r * 0.95)
        ..close();
      canvas.drawPath(dorsalPath, dorsalPaint);
      canvas.drawPath(dorsalPath, borderPaint);

      // 4. Yan yüzgeç (animasyonlu)
      canvas.save();
      canvas.translate(-r * 0.1, r * 0.2);
      canvas.rotate(finWiggle);
      final sideFinPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-r * 0.4, r * 0.4, r * 0.05, r * 0.4)
        ..close();
      canvas.drawPath(sideFinPath, dorsalPaint);
      canvas.drawPath(sideFinPath, borderPaint);
      canvas.restore();

      // 5. Devasa Şirin Göz (Anime Tarzı)
      final eyeCenter = Offset(r * 0.45, -r * 0.18);
      canvas.drawCircle(eyeCenter, r * 0.32, Paint()..color = Colors.white.withValues(alpha: color.a));
      canvas.drawCircle(eyeCenter, r * 0.32, borderPaint);

      final pupilCenter = Offset(eyeCenter.dx + r * 0.08, eyeCenter.dy);
      canvas.drawCircle(pupilCenter, r * 0.16, Paint()..color = Colors.black.withValues(alpha: color.a));
      
      // İki adet beyaz parlama
      canvas.drawCircle(Offset(pupilCenter.dx - r * 0.06, pupilCenter.dy - r * 0.06), r * 0.07, Paint()..color = Colors.white.withValues(alpha: color.a));
      canvas.drawCircle(Offset(pupilCenter.dx + r * 0.06, pupilCenter.dy + r * 0.03), r * 0.03, Paint()..color = Colors.white.withValues(alpha: color.a));

      // Şirin Pembe Yanaklar
      canvas.drawCircle(
        Offset(r * 0.22, r * 0.25),
        r * 0.2,
        Paint()..color = const Color(0xFFFF80AB).withValues(alpha: color.a * 0.55),
      );

      // Öpücük Ağız (Küçük sevimli 'o' ağzı)
      final mouthPaint = Paint()
        ..color = Colors.black87.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.07).clamp(1.5, 3.5);
      canvas.drawCircle(Offset(r * 0.85, r * 0.18), r * 0.1, mouthPaint);
      canvas.drawCircle(Offset(r * 0.85, r * 0.18), r * 0.06, Paint()..color = const Color(0xFFF06292).withValues(alpha: color.a));

    } else {
      // 🐠 NÖTR / ORTA BOY BALIK: Palyaço Balığı (Clownfish) tarzı çizgili
      // 1. Yuvarlak Kuyruk
      final tailPaint = Paint()..color = color.withValues(alpha: color.a * 0.85);
      final tailPath = Path()
        ..moveTo(-r * 0.8, 0)
        ..quadraticBezierTo(-r * 1.5, -r * 0.6, -r * 1.5, 0)
        ..quadraticBezierTo(-r * 1.5, r * 0.6, -r * 0.8, 0)
        ..close();
      canvas.drawPath(tailPath, tailPaint);
      canvas.drawPath(tailPath, borderPaint);

      // 2. Sırt Yüzgeci (Tırtıklı / Dalgalı)
      final dorsalPaint = Paint()..color = color.withValues(alpha: color.a * 0.9);
      final dorsalPath = Path()
        ..moveTo(-r * 0.2, -r * 0.5)
        ..quadraticBezierTo(r * 0.1, -r * 1.0, r * 0.35, -r * 0.5)
        ..close();
      canvas.drawPath(dorsalPath, dorsalPaint);
      canvas.drawPath(dorsalPath, borderPaint);

      // 3. Gövde
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.1),
        bodyPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.1),
        borderPaint,
      );

      // 4. Belirgin Beyaz-Siyah Desen Şeridi
      final stripePaint = Paint()
        ..color = Colors.white.withValues(alpha: color.a * 0.9)
        ..style = PaintingStyle.fill;
      final stripeBorder = Paint()
        ..color = Colors.black.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.05).clamp(1.0, 3.0);

      final stripeRect = Rect.fromCenter(center: const Offset(-0.05, 0), width: r * 0.3, height: r * 1.05);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.drawRect(stripeRect, stripeBorder);

      // 5. Yan yüzgeç (animasyonlu)
      canvas.save();
      canvas.translate(-r * 0.1, r * 0.15);
      canvas.rotate(finWiggle);
      final sideFinPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-r * 0.45, r * 0.3)
        ..lineTo(r * 0.02, r * 0.4)
        ..close();
      canvas.drawPath(sideFinPath, dorsalPaint);
      canvas.drawPath(sideFinPath, borderPaint);
      canvas.restore();

      // 6. Meraklı Göz
      final eyeCenter = Offset(r * 0.5, -r * 0.15);
      canvas.drawCircle(eyeCenter, r * 0.22, Paint()..color = Colors.white.withValues(alpha: color.a));
      canvas.drawCircle(eyeCenter, r * 0.22, borderPaint);

      final pupilCenter = Offset(eyeCenter.dx + r * 0.04, eyeCenter.dy);
      canvas.drawCircle(pupilCenter, r * 0.1, Paint()..color = Colors.black.withValues(alpha: color.a));
      canvas.drawCircle(Offset(pupilCenter.dx - r * 0.03, pupilCenter.dy - r * 0.03), r * 0.04, Paint()..color = Colors.white.withValues(alpha: color.a));

      // 7. Normal Güler Ağız
      final mouthPaint = Paint()
        ..color = Colors.black87.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.06).clamp(1.5, 3.5)
        ..strokeCap = StrokeCap.round;
      final mouthRect = Rect.fromCenter(
        center: Offset(r * 0.7, r * 0.15),
        width: r * 0.22,
        height: r * 0.15,
      );
      canvas.drawArc(mouthRect, 0, pi, false, mouthPaint);
    }

    // Büyüklük göstergesi (Tehlikeli balıklar için ekstra dış halka)
    if (radius > game.player.radius * 1.15) {
      final warnPaint = Paint()
        ..color = AppColors.coral.withValues(alpha: color.a * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.7, height: r * 1.45),
        warnPaint,
      );
    }
  }
}
