import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';
import 'package:ocean_lens_ar/features/game/components/npc_fish.dart';
import 'package:ocean_lens_ar/features/game/components/ocean_background.dart';
import 'package:ocean_lens_ar/features/game/components/player_fish.dart';
import 'package:ocean_lens_ar/features/game/components/collectible_item.dart';
import 'package:ocean_lens_ar/features/game/components/jellyfish_obstacle.dart';
import 'package:ocean_lens_ar/features/game/components/eat_bubble.dart';

enum GameState { playing, gameOver, paused }

class OceanGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, TapCallbacks {
  // Oyun durumu
  GameState gameState = GameState.playing;
  int score = 0;
  int lives = 3;
  double fishEaten = 0;

  // Oyun bileşenleri
  late PlayerFish player;
  late OceanBackground background;

  // Zamanlayıcılar
  double _spawnTimer = 0;
  double _spawnInterval = 3.5;
  double _collectibleTimer = 0;
  double _jellyfishTimer = 0;
  double _questionTimer = 0;
  final Random _random = Random();

  // Callbacks
  VoidCallback? onScoreChanged;
  VoidCallback? onLivesChanged;
  VoidCallback? onGameOver;
  VoidCallback? onQuestionTriggered;

  @override
  Future<void> onLoad() async {
    // Arka plan
    background = OceanBackground();
    add(background);

    // Oyuncu
    player = PlayerFish(
      startPos: Vector2(size.x / 2, size.y / 2),
    );
    add(player);

    // İlk NPC balıkları
    for (int i = 0; i < 3; i++) {
      _spawnNpc();
    }
  }

  @override
  void update(double dt) {
    if (gameState != GameState.playing) return;
    super.update(dt);

    _spawnTimer += dt;
    _collectibleTimer += dt;
    _jellyfishTimer += dt;
    _questionTimer += dt;

    // Zorluk artışı (Hard seviye: daha hızlı ve agresif zorlaşma)
    _spawnInterval = (3.0 - score * 0.005).clamp(1.2, 3.0);

    // Düşman spawn
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnNpc();
    }

    // Güçlendirici spawn (12-16 saniyede bir)
    if (_collectibleTimer >= 14.0) {
      _collectibleTimer = 0;
      _spawnCollectible();
    }

    // Denizanası engel spawn (18-24 saniyede bir)
    if (_jellyfishTimer >= 20.0) {
      _jellyfishTimer = 0;
      _spawnJellyfish();
    }

    // Soru tetikleme (Her 15 saniyede bir)
    if (_questionTimer >= 15.0) {
      _questionTimer = 0;
      pauseGame();
      onQuestionTriggered?.call();
    }
  }

  void _spawnCollectible() {
    final types = CollectibleType.values;
    final randomType = types[_random.nextInt(types.length)];
    final spawnPos = Vector2(
      50 + _random.nextDouble() * (size.x - 100),
      50 + _random.nextDouble() * (size.y - 100),
    );
    final collectible = CollectibleItem(type: randomType, position: spawnPos);
    add(collectible);
  }

  void _spawnJellyfish() {
    final startX = 50 + _random.nextDouble() * (size.x - 100);
    // Ekranın altından veya üstünden başlat
    final startY = _random.nextBool() ? -30.0 : size.y + 30.0;
    final jellyfish = JellyfishObstacle(position: Vector2(startX, startY));
    add(jellyfish);
  }

  void _spawnNpc() {
    final baseSize = player.fishSize;
    
    // Balanced spawn size categories (Hard Difficulty):
    // 40% edible (green), 35% neutral/close size (yellow), 25% dangerous (red)
    final roll = _random.nextDouble();
    double sizeMultiplier;
    if (roll < 0.40) {
      // Edible: 0.35x to 0.8x of player size
      sizeMultiplier = 0.35 + _random.nextDouble() * 0.45;
    } else if (roll < 0.75) {
      // Neutral: 0.8x to 1.15x of player size
      sizeMultiplier = 0.8 + _random.nextDouble() * 0.35;
    } else {
      // Dangerous: 1.15x to 2.0x of player size
      sizeMultiplier = 1.15 + _random.nextDouble() * 0.85;
    }
    
    final npcSize = (baseSize * sizeMultiplier).clamp(0.35, 3.5);

    // Ekran kenarından başlat
    final side = _random.nextInt(4);
    Vector2 startPos;

    switch (side) {
      case 0: // Sol
        startPos = Vector2(-30, _random.nextDouble() * size.y);
        break;
      case 1: // Sağ
        startPos = Vector2(size.x + 30, _random.nextDouble() * size.y);
        break;
      case 2: // Üst
        startPos = Vector2(_random.nextDouble() * size.x, -30);
        break;
      default: // Alt
        startPos = Vector2(_random.nextDouble() * size.x, size.y + 30);
    }

    final npc = NpcFish(fishSize: npcSize, startPos: startPos);
    add(npc);
  }

  // Drag ile kontrol
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState == GameState.playing) {
      player.moveTo(event.canvasStartPosition + event.canvasDelta);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing) {
      player.moveTo(event.canvasPosition);
    }
  }

  // Balık yenildi
  void onFishEaten(double npcSize) {
    fishEaten += 1;
    score += (npcSize * 10 * player.fishSize).round();
    AudioService.instance.playEat();
    HapticFeedback.lightImpact(); // Yeme anında pıt titreşimi
    onScoreChanged?.call();
  }

  // Yeme baloncuk patlama efekti fırlatır
  void spawnEatParticles(Vector2 position, double radius) {
    for (int i = 0; i < 7; i++) {
      final bubbleRadius = 3.0 + _random.nextDouble() * 4.5;
      add(EatBubble(position: position, radius: bubbleRadius));
    }
  }

  // Oyuncuyu iyileştir
  void healPlayer({bool allowOverHeal = false}) {
    if (allowOverHeal || lives < 3) {
      lives++;
      HapticFeedback.mediumImpact();
      onLivesChanged?.call();
    }
  }

  // Oyuncuya hasar geldi
  void onPlayerHit() {
    lives = (lives - 1).clamp(0, 99);
    onLivesChanged?.call();

    if (lives <= 0) {
      AudioService.instance.playDie();
      gameState = GameState.gameOver;
      onGameOver?.call();
    } else {
      AudioService.instance.playWrong();
    }
  }

  void pauseGame() {
    gameState = GameState.paused;
    pauseEngine();
  }

  void resumeGame() {
    gameState = GameState.playing;
    resumeEngine();
  }

  void restartGame() {
    score = 0;
    lives = 3;
    fishEaten = 0;
    player.fishSize = 1.0;
    player.isShieldActive = false;
    player.shieldTimer = 0;
    player.isSpeedBoostActive = false;
    player.speedBoostTimer = 0;
    player.isStunned = false;
    player.stunTimer = 0;
    _collectibleTimer = 0;
    _jellyfishTimer = 0;
    _questionTimer = 0;
    gameState = GameState.playing;

    // Tüm nesneleri temizle
    children.whereType<NpcFish>().forEach((npc) => npc.removeFromParent());
    children.whereType<CollectibleItem>().forEach((item) => item.removeFromParent());
    children.whereType<JellyfishObstacle>().forEach((jelly) => jelly.removeFromParent());

    // Oyuncuyu merkeze al
    player.position = Vector2(size.x / 2, size.y / 2);

    // Yeni NPC'ler
    for (int i = 0; i < 3; i++) {
      _spawnNpc();
    }

    onScoreChanged?.call();
    onLivesChanged?.call();

    resumeEngine();
  }
}
