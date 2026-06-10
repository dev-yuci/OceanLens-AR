import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlacedSticker {
  final String id;
  final String name;
  final String emoji;
  double x;
  double y;
  double scale;

  PlacedSticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.x,
    required this.y,
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'x': x,
        'y': y,
        'scale': scale,
      };

  factory PlacedSticker.fromJson(Map<String, dynamic> json) => PlacedSticker(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      );
}

class AquariumStorage {
  static const String _fileName = 'ocean_aquarium.json';

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<PlacedSticker>> loadStickers() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
        return jsonList
            .map((item) => PlacedSticker.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Hata durumunda boş liste dön
    }
    return [];
  }

  static Future<void> saveStickers(List<PlacedSticker> stickers) async {
    try {
      final file = await _getFile();
      final jsonList = stickers.map((s) => s.toJson()).toList();
      final content = jsonEncode(jsonList);
      await file.writeAsString(content);
    } catch (e) {
      // Hata yönetimi
    }
  }
}
