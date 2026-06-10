import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';

/// Deniz arka planı - parallax katmanlar, hareketli ışık hüzmeleri ve yosunlar
class OceanBackground extends Component with HasGameReference<FlameGame> {
  late List<_BubbleParticle> _bubbles;
  late List<_SeaweedComponent> _seaweeds;
  final _random = Random();
  double _causticsTime = 0;

  @override
  Future<void> onLoad() async {
    _bubbles = List.generate(30, (_) => _BubbleParticle(_random));
    // Yosunları ekran genişliğine dağıtmak için başlangıçta normalize edilmiş konumlar kullanıyoruz
    _seaweeds = List.generate(10, (i) => _SeaweedComponent(
      (i + 0.5) / 10.0, // Normalize edilmiş X koordinatları (0.05, 0.15, ... 0.95)
      _random,
    ));
  }

  @override
  void update(double dt) {
    _causticsTime += dt;
    for (final b in _bubbles) {
      b.update(dt);
    }
    for (final s in _seaweeds) {
      s.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;

    // 1. Degradeli Derin Deniz Arka Planı
    _drawOceanGradient(canvas, size);

    // 2. Hareketli Güneş Hüzmeleri (Sunlight Rays)
    _drawLightRays(canvas, size);

    // 3. Wavy Deniz Tabanı Kumu (Sand Floor)
    _drawSandFloor(canvas, size);

    // 4. Salınan Yosunlar (Seaweeds)
    for (final s in _seaweeds) {
      s.render(canvas, size);
    }

    // 5. Yükselen Baloncuklar (Bubbles)
    for (final b in _bubbles) {
      b.render(canvas, size);
    }
  }

  void _drawOceanGradient(Canvas canvas, Vector2 size) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF003F5C), // Açık turkuaz/mavi (Yüzey)
          Color(0xFF0D253F), // Derin mavi
          Color(0xFF071B2B), // Koyu derinlik
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawLightRays(Canvas canvas, Vector2 size) {
    final rayPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    for (int i = 0; i < 3; i++) {
      // Yavaşça sola-sağa dalgalanan ışık şeritleri
      final offset = sin(_causticsTime * 0.4 + i * 2) * size.x * 0.06;
      final startX = size.x * (0.15 + i * 0.32) + offset;
      
      final rayPath = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX + size.x * 0.08, 0)
        ..lineTo(startX + size.x * 0.25 + size.x * 0.08, size.y)
        ..lineTo(startX + size.x * 0.25, size.y)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
  }

  void _drawSandFloor(Canvas canvas, Vector2 size) {
    // Kum dalgası
    final sandPath = Path()
      ..moveTo(0, size.y)
      ..lineTo(0, size.y - 24)
      ..quadraticBezierTo(size.x * 0.25, size.y - 32, size.x * 0.5, size.y - 20)
      ..quadraticBezierTo(size.x * 0.75, size.y - 8, size.x, size.y - 24)
      ..lineTo(size.x, size.y)
      ..close();

    final sandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF1C40F).withValues(alpha: 0.8), // Altın sarısı kum üstü
          const Color(0xFFD4AC0D).withValues(alpha: 0.95), // Koyu altın kum altı
        ],
      ).createShader(Rect.fromLTWH(0, size.y - 32, size.x, 32));

    canvas.drawPath(sandPath, sandPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(sandPath, borderPaint);
  }
}

class _BubbleParticle {
  double nx, ny, radius, speed, opacity;
  final Random random;

  _BubbleParticle(this.random)
      : nx = random.nextDouble(),
        ny = random.nextDouble(),
        radius = random.nextDouble() * 3 + 1.2,
        speed = random.nextDouble() * 0.08 + 0.03, // Normalize edilmiş dikey hız
        opacity = random.nextDouble() * 0.35 + 0.1;

  void update(double dt) {
    ny -= speed * dt;
    nx += sin(ny * 25) * 0.01 * dt; // Baloncukların saga sola süzülmesi
    if (ny < -0.05) {
      ny = 1.05;
      nx = random.nextDouble();
    }
  }

  void render(Canvas canvas, Vector2 size) {
    final paint = Paint()
      ..color = AppColors.aqua.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(nx * size.x, ny * size.y), radius, paint);
  }
}

class _SeaweedComponent {
  final double nx; // Normalize edilmiş X koordinatı (0.0 - 1.0)
  final Random random;
  double _time = 0;
  final double _height;
  final Color _color;

  _SeaweedComponent(this.nx, this.random)
      : _height = random.nextDouble() * 80 + 70, // Daha belirgin ve büyük yosunlar
        _color = Color.lerp(
          const Color(0xFF1B4F72), // Deniz mavisine yakın koyu yeşil
          const Color(0xFF1E824C), // Canlı yosun yeşili
          random.nextDouble(),
        )!;

  void update(double dt) {
    _time += dt;
  }

  void render(Canvas canvas, Vector2 size) {
    final paint = Paint()
      ..color = _color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final baseY = size.y - 15; // Kum hizası
    final path = Path();
    final realX = nx * size.x;
    path.moveTo(realX, baseY);

    // Sinusoidal dalga yosun yapısı
    for (double t = 0; t <= _height; t += 3) {
      final wx = realX + sin(_time * 1.6 + t * 0.08) * (14 * t / _height);
      path.lineTo(wx, baseY - t);
    }

    canvas.drawPath(path, paint);

    final whiteLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, whiteLine);
  }
}
