import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/game/ocean_game.dart';
import 'package:ocean_lens_ar/features/game/data/game_questions.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late OceanGame _game;
  int _score = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isPaused = false;

  // Bilgi Kartı (Soru) Değişkenleri
  ShuffledQuestion? _currentQuestion;
  bool _showQuestionCard = false;
  bool _showRewardMessage = false;
  String _rewardTitle = "";
  String _rewardDescription = "";
  int? _selectedAnswerIndex;
  bool? _isCorrectAnswer;
  final Random _random = Random();
  final Set<int> _askedInGameIndices = {};

  @override
  void initState() {
    super.initState();
    _initGame();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    AudioService.instance.stopBackground();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _initGame() {
    _game = OceanGame();
    _game.onScoreChanged = () {
      if (mounted) setState(() => _score = _game.score);
    };
    _game.onLivesChanged = () {
      if (mounted) setState(() => _lives = _game.lives);
    };
    _game.onGameOver = () {
      if (mounted) {
        AudioService.instance.stopBackground();
        setState(() => _isGameOver = true);
      }
    };
    _game.onQuestionTriggered = () {
      if (mounted) {
        AudioService.instance.stopBackground();
        
        final unasked = List.generate(oceanQuestions.length, (i) => i)
            .where((i) => !_askedInGameIndices.contains(i))
            .toList();
            
        int selectedIndex;
        if (unasked.isEmpty) {
          _askedInGameIndices.clear();
          selectedIndex = _random.nextInt(oceanQuestions.length);
        } else {
          selectedIndex = unasked[_random.nextInt(unasked.length)];
        }
        
        _askedInGameIndices.add(selectedIndex);
        
        setState(() {
          _currentQuestion = ShuffledQuestion(oceanQuestions[selectedIndex]);
          _showQuestionCard = true;
          _selectedAnswerIndex = null;
          _isCorrectAnswer = null;
        });
      }
    };
    setState(() {
      _score = 0;
      _lives = 3;
      _isGameOver = false;
      _isPaused = false;
      _showQuestionCard = false;
      _showRewardMessage = false;
      _currentQuestion = null;
      _selectedAnswerIndex = null;
      _isCorrectAnswer = null;
      _askedInGameIndices.clear();
    });
    AudioService.instance.playBackground('ambient_water.wav');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Flame oyun
          GameWidget(game: _game),

          // HUD - Üst bar
          SafeArea(child: _buildHUD()),

          // Duraklat overlay
          if (_isPaused) _buildPauseOverlay(),

          // Oyun bitti overlay
          if (_isGameOver) _buildGameOverOverlay(),

          // Soru Overlay
          if (_showQuestionCard && _currentQuestion != null) _buildQuestionOverlay(),

          // Ödül/Hata Sonucu Overlay
          if (_showRewardMessage) _buildRewardOverlay(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Geri / duraklat (Tombul Yuvarlak Düğme)
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              if (_isPaused) {
                _game.resumeGame();
                AudioService.instance.playBackground('ambient_water.wav');
                setState(() => _isPaused = false);
              } else {
                _game.pauseGame();
                AudioService.instance.stopBackground();
                setState(() => _isPaused = true);
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.75),
                border: Border.all(color: AppColors.teal, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Puan (Tombul Altın Madalya Stili)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '$_score',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Canlar (Tombul Pembe Kalpler)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.coral, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _lives <= 3
                  ? List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 22,
                          color: i < _lives
                              ? AppColors.coral
                              : Colors.white10,
                        ),
                      );
                    })
                  : [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 22,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'x$_lives',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkOcean,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.teal, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.15),
                blurRadius: 20,
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_filled_rounded,
                    color: AppColors.aqua, size: 56),
                const SizedBox(height: 16),
                Text('Oyun Durduruldu',
                    style: GoogleFonts.fredoka(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pearl,
                    )),
                const SizedBox(height: 8),
                Text('Anlık Skor: $_score 🌟',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, color: AppColors.silver, fontWeight: FontWeight.w600)),
                const SizedBox(height: 28),
                _overlayButton(
                  'Oyuna Devam Et 🎮',
                  AppColors.aquaGradient,
                  const Color(0xFF0369A1),
                  () {
                    _game.resumeGame();
                    AudioService.instance.playBackground('ambient_water.wav');
                    setState(() => _isPaused = false);
                  },
                ),
                const SizedBox(height: 14),
                _overlayButton(
                  'Çıkış Yap 🏠',
                  const LinearGradient(
                      colors: [Color(0xFF8F1E1E), Color(0xFFC0392B)]),
                  const Color(0xFF5C1010),
                  () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkOcean, AppColors.deepOcean],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.coral, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withValues(alpha: 0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐠', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text('Macera Bitti!',
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pearl,
                    )),
                const SizedBox(height: 20),
                _statRow('🏆 Toplam Skor', '$_score'),
                _statRow('🐡 Yenen Balık Sayısı',
                    '${_game.fishEaten.toInt()}'),
                _statRow('📏 Final Boyutun',
                    'x${_game.player.fishSize.toStringAsFixed(1)}'),
                const SizedBox(height: 28),
                _overlayButton(
                  'Tekrar Oyna 🔄',
                  AppColors.aquaGradient,
                  const Color(0xFF0369A1),
                  () {
                    _initGame();
                  },
                ),
                const SizedBox(height: 14),
                _overlayButton(
                  'Ana Menüye Dön 🏠',
                  const LinearGradient(colors: [
                    Color(0xFF1E528F),
                    Color(0xFF14325C)
                  ]),
                  const Color(0xFF0C213D),
                  () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: AppColors.silver,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: AppColors.pearl,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _overlayButton(
      String label, LinearGradient gradient, Color shadowColor, VoidCallback onTap) {
    return _Overlay3DButton(
      label: label,
      gradient: gradient,
      shadowColor: shadowColor,
      onTap: () {
        AudioService.instance.playClick();
        onTap();
      },
    );
  }

  // Soru Overlay widget'ı
  Widget _buildQuestionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkOcean, AppColors.deepOcean],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.teal, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.25),
                blurRadius: 25,
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal.withValues(alpha: 0.15),
                  ),
                  child: const Text('❓', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bilgi Kartı 💡',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.aqua,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentQuestion!.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pearl,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(_currentQuestion!.options.length, (index) {
                  final optionText = _currentQuestion!.options[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOptionButton(index, optionText),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, String text) {
    final bool isAnswered = _isCorrectAnswer != null;
    final bool isCorrect = index == _currentQuestion!.correctAnswerIndex;
    final bool isSelected = index == _selectedAnswerIndex;

    Color buttonColor;
    Color borderColor;
    Color textColor = Colors.white;

    if (!isAnswered) {
      buttonColor = Colors.transparent;
      borderColor = AppColors.teal.withValues(alpha: 0.5);
    } else {
      if (isCorrect) {
        buttonColor = Colors.green.withValues(alpha: 0.25);
        borderColor = Colors.greenAccent;
      } else if (isSelected) {
        buttonColor = Colors.red.withValues(alpha: 0.25);
        borderColor = Colors.redAccent;
      } else {
        buttonColor = Colors.transparent;
        borderColor = Colors.white10;
        textColor = Colors.white30;
      }
    }

    return GestureDetector(
      onTap: () => _handleAnswer(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _handleAnswer(int index) {
    if (_isCorrectAnswer != null) return;
    final isCorrect = index == _currentQuestion!.correctAnswerIndex;
    if (isCorrect) {
      AudioService.instance.playCorrect();
    } else {
      AudioService.instance.playWrong();
    }
    setState(() {
      _selectedAnswerIndex = index;
      _isCorrectAnswer = isCorrect;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _showQuestionCard = false;
      });

      if (isCorrect) {
        final rewardType = _random.nextInt(3);
        String title = "Tebrikler! 🎉";
        String desc = "";

        if (rewardType == 0) {
          _game.score += 20;
          _game.onScoreChanged?.call();
          desc = "Doğru yanıt verdin ve +20 Skor Puanı kazandın!";
        } else if (rewardType == 1) {
          _game.player.grow();
          desc = "Doğru yanıt verdin ve Büyüme İksiri kazandın! Balığın biraz daha büyüdü.";
        } else {
          _game.healPlayer(allowOverHeal: true);
          desc = "Doğru yanıt verdin ve Ekstra Can kazandın!";
        }

        setState(() {
          _rewardTitle = title;
          _rewardDescription = desc;
          _showRewardMessage = true;
        });
      } else {
        setState(() {
          _rewardTitle = "Ah, Yakındı! 🌊";
          _rewardDescription = "Yanlış cevap verdin!\n\nDoğru Bilgi: ${_currentQuestion!.explanation}";
          _showRewardMessage = true;
        });
      }
    });
  }

  // Ödül / Sonuç Overlay widget'ı
  Widget _buildRewardOverlay() {
    final bool correct = _isCorrectAnswer ?? false;
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: correct
                  ? [AppColors.darkOcean, const Color(0xFF0F3A2E)]
                  : [AppColors.darkOcean, const Color(0xFF4A1521)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: correct ? Colors.greenAccent : Colors.redAccent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (correct ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2),
                blurRadius: 25,
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  correct ? "🎉" : "💡",
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  _rewardTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _rewardDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pearl,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _Overlay3DButton(
                  label: "Devam Et 🌊",
                  gradient: correct
                      ? const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF10B981)])
                      : AppColors.aquaGradient,
                  shadowColor: correct
                      ? const Color(0xFF0C5C3D)
                      : const Color(0xFF0369A1),
                  onTap: () {
                    AudioService.instance.playClick();
                    setState(() {
                      _showRewardMessage = false;
                    });
                    _game.resumeGame();
                    AudioService.instance.playBackground('ambient_water.wav');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Overlay3DButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _Overlay3DButton({
    required this.label,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_Overlay3DButton> createState() => _Overlay3DButtonState();
}

class _Overlay3DButtonState extends State<_Overlay3DButton>
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
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _translateAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateAnim.value),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 14, bottom: 18), // 3D payı
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              // 3D Gölge
              BoxShadow(
                color: widget.shadowColor,
                offset: Offset(0, 6 - _translateAnim.value),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 8),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
