import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QuizStorage {
  static const String _fileName = 'ocean_quiz_score.txt';

  static Future<File> _getScoreFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<int> loadScore() async {
    try {
      final file = await _getScoreFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return int.tryParse(content.trim()) ?? 0;
      }
    } catch (e) {
      // Hata durumunda varsayılan 0
    }
    return 0;
  }

  static Future<void> saveScore(int score) async {
    try {
      final file = await _getScoreFile();
      await file.writeAsString(score.toString());
    } catch (e) {
      // Hata yönetimi
    }
  }

  static const String _answeredFileName = 'ocean_quiz_answered.txt';

  static Future<File> _getAnsweredFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_answeredFileName');
  }

  static Future<List<int>> loadAnsweredIndices() async {
    try {
      final file = await _getAnsweredFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) return [];
        return content.trim().split(',').map(int.parse).toList();
      }
    } catch (e) {
      // Hata yönetimi
    }
    return [];
  }

  static Future<void> saveAnsweredIndices(List<int> indices) async {
    try {
      final file = await _getAnsweredFile();
      await file.writeAsString(indices.join(','));
    } catch (e) {
      // Hata yönetimi
    }
  }

  static Future<void> clearAnsweredIndices() async {
    try {
      final file = await _getAnsweredFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Hata yönetimi
    }
  }
}
