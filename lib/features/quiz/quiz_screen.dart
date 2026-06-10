import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/game/data/game_questions.dart';
import 'package:ocean_lens_ar/features/quiz/data/quiz_storage.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  int _score = 0;
  List<int> _answeredIndices = [];
  List<int> _unansweredIndices = [];
  ShuffledQuestion? _currentShuffledQuestion;
  bool _isLoading = true;

  int? _selectedAnswerIndex;
  bool? _isCorrectAnswer;
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initQuiz();
  }

  Future<void> _initQuiz() async {
    final score = await QuizStorage.loadScore();
    final answered = await QuizStorage.loadAnsweredIndices();
    if (mounted) {
      setState(() {
        _score = score;
        _answeredIndices = answered;
        _buildUnansweredPool();
        _isLoading = false;
      });
    }
  }

  void _buildUnansweredPool() {
    final allIndices = List.generate(oceanQuestions.length, (i) => i);
    _unansweredIndices = allIndices.where((index) => !_answeredIndices.contains(index)).toList();
    _unansweredIndices.shuffle();
    _updateCurrentQuestion();
  }

  void _updateCurrentQuestion() {
    if (_unansweredIndices.isNotEmpty) {
      final currentQuestionIndex = _unansweredIndices.first;
      _currentShuffledQuestion = ShuffledQuestion(oceanQuestions[currentQuestionIndex]);
    } else {
      _currentShuffledQuestion = null;
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _handleOptionTap(int index, ShuffledQuestion question) {
    if (_selectedAnswerIndex != null) return; // Zaten cevaplandıysa dur

    final bool isCorrect = index == question.correctAnswerIndex;
    setState(() {
      _selectedAnswerIndex = index;
      _isCorrectAnswer = isCorrect;
      _showExplanation = true;
    });

    if (isCorrect) {
      AudioService.instance.playCorrect();
      HapticFeedback.lightImpact();
      setState(() {
        _score += 10; // Doğru cevap başına +10 puan
      });
      QuizStorage.saveScore(_score);
    } else {
      AudioService.instance.playWrong();
      HapticFeedback.mediumImpact();
    }
  }

  void _nextQuestion() async {
    AudioService.instance.playClick();
    
    if (_unansweredIndices.isNotEmpty) {
      final completedIndex = _unansweredIndices.removeAt(0);
      if (!_answeredIndices.contains(completedIndex)) {
        _answeredIndices.add(completedIndex);
        await QuizStorage.saveAnsweredIndices(_answeredIndices);
      }
    }

    setState(() {
      _selectedAnswerIndex = null;
      _isCorrectAnswer = null;
      _showExplanation = false;
      _updateCurrentQuestion();
    });
  }

  Future<void> _resetQuizProgress() async {
    AudioService.instance.playClick();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkOcean,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.teal, width: 2.5),
          ),
          title: Text(
            'İlerlemeyi Sıfırla 🔄',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w800,
              color: AppColors.pearl,
            ),
          ),
          content: Text(
            'Tüm cevapladığın soruları sıfırlayıp baştan başlamak istediğine emin misin?',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: AppColors.silver,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playClick();
                Navigator.pop(context, false);
              },
              child: Text(
                'İptal',
                style: GoogleFonts.fredoka(color: Colors.white60, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                AudioService.instance.playClick();
                Navigator.pop(context, true);
              },
              child: Text(
                'Evet, Sıfırla',
                style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await QuizStorage.clearAnsweredIndices();
      if (mounted) {
        setState(() {
          _isLoading = true;
          _answeredIndices.clear();
        });
      }
      _buildUnansweredPool();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.deepOcean,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.aqua,
          ),
        ),
      );
    }

    final bool isCompleted = _unansweredIndices.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          // Animasyonlu baloncuklu arka plan
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _QuizBackgroundPainter(_bgController.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: isCompleted
                            ? _buildCompletionView(context)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildProgressCard(),
                                  const SizedBox(height: 16),
                                  _buildQuestionCard(_currentShuffledQuestion!),
                                  const SizedBox(height: 24),
                                  ...List.generate(_currentShuffledQuestion!.options.length, (i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildOptionButton(i, _currentShuffledQuestion!.options[i], _currentShuffledQuestion!),
                                    );
                                  }),
                                  if (_showExplanation) ...[
                                    const SizedBox(height: 20),
                                    _buildExplanationCard(_currentShuffledQuestion!),
                                    const SizedBox(height: 24),
                                    _buildNextButton(),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(color: AppColors.teal, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),

          // Başlık
          Text(
            'Bilgi Yarışması',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          // Skor Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final solvedCount = _answeredIndices.length;
    final totalCount = oceanQuestions.length;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkOcean.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Text(
            'İlerleme: $solvedCount / $totalCount Çözüldü 💡',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.aqua,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: totalCount > 0 ? (solvedCount / totalCount).clamp(0.0, 1.0) : 0.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.aquaGradient,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.aqua.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkOcean, AppColors.deepOcean],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Text(
                '👑',
                style: TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Denizlerin Bilgesi! 🌊',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Harika bir iş çıkardın! Tüm okyanus sorularını (${oceanQuestions.length} soru) başarıyla tamamladın ve okyanusların koruyucusu unvanını kazandın! 🐬✨',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.pearl,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Toplam Puanın: $_score',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _resetQuizProgress,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.aquaGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFF0369A1),
                      offset: Offset(0, 5),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 7),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  "Yarışmayı Yeniden Başlat 🔄",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                AudioService.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Text(
                  "Ana Menüye Dön",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.silver,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ShuffledQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkOcean, AppColors.deepOcean],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.teal, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.15),
            blurRadius: 20,
          )
        ],
      ),
      child: Text(
        question.question,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.pearl,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, String optionText, ShuffledQuestion question) {
    final bool isAnswered = _selectedAnswerIndex != null;
    final bool isCorrect = index == question.correctAnswerIndex;
    final bool isSelected = index == _selectedAnswerIndex;

    Color buttonBgColor;
    Color borderColor;
    Color textColor = Colors.white;

    if (!isAnswered) {
      buttonBgColor = AppColors.darkOcean.withValues(alpha: 0.4);
      borderColor = AppColors.teal.withValues(alpha: 0.4);
    } else {
      if (isCorrect) {
        buttonBgColor = Colors.green.withValues(alpha: 0.25);
        borderColor = Colors.greenAccent;
      } else if (isSelected) {
        buttonBgColor = Colors.red.withValues(alpha: 0.25);
        borderColor = Colors.redAccent;
      } else {
        buttonBgColor = Colors.transparent;
        borderColor = Colors.white.withValues(alpha: 0.05);
        textColor = Colors.white.withValues(alpha: 0.3);
      }
    }

    return GestureDetector(
      onTap: () => _handleOptionTap(index, question),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: buttonBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: !isAnswered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  )
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              optionText,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (isAnswered)
              Positioned(
                right: 0,
                child: Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : isSelected
                          ? Icons.cancel_rounded
                          : null,
                  color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(ShuffledQuestion question) {
    final bool correct = _isCorrectAnswer ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: correct
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: correct ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.stars_rounded : Icons.info_outline_rounded,
                color: correct ? Colors.greenAccent : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Harika! Doğru Cevap 🎉' : 'Neden Yanlış? 💡',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: correct ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.explanation,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.pearl,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _nextQuestion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.aquaGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF0369A1),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 7),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          "Sıradaki Soru ➡️",
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _QuizBackgroundPainter extends CustomPainter {
  final double anim;
  _QuizBackgroundPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGlow(canvas, Offset(size.width * 0.2, size.height * 0.2), 110, AppColors.teal.withValues(alpha: 0.07));
    _drawGlow(canvas, Offset(size.width * 0.8, size.height * 0.6), 130, AppColors.aqua.withValues(alpha: 0.05));
    _drawBubbles(canvas, size);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final factor = sin(anim * 2 * pi) * 0.1 + 0.9;
    canvas.drawCircle(
      center,
      radius * factor,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bubbleColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bubbles = [
      {'x': 0.15, 'radius': 12.0, 'offset': 0.0},
      {'x': 0.82, 'radius': 16.0, 'offset': 0.35},
      {'x': 0.45, 'radius': 14.0, 'offset': 0.7},
      {'x': 0.3, 'radius': 8.0, 'offset': 0.2},
      {'x': 0.65, 'radius': 11.0, 'offset': 0.5},
    ];

    for (final b in bubbles) {
      final progress = ((anim + (b['offset'] as num).toDouble()) % 1.0);
      final y = size.height * (1.1 - progress * 1.2);
      final x = size.width * (b['x'] as num).toDouble() + sin(progress * 2 * pi * 2) * 8;
      final r = (b['radius'] as num).toDouble();
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_QuizBackgroundPainter old) => old.anim != anim;
}
