import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana Okyanus Paleti (Daha Parlak ve Oyuncu Tonlar)
  static const Color deepOcean = Color(0xFF0C213D);     // Zengin çocuk dostu koyu mavi
  static const Color darkOcean = Color(0xFF14325C);     // Canlı lacivert
  static const Color oceanBlue = Color(0xFF1E528F);     // Tatlı açık lacivert
  static const Color midOcean = Color(0xFF1B65A6);      // Derinlik mavisi
  static const Color teal = Color(0xFF0EA5E9);          // Canlı gök mavisi
  static const Color aqua = Color(0xFF06B6D4);          // Turkuaz
  static const Color lightAqua = Color(0xFF22D3EE);     // Parlak turkuaz
  static const Color seafoam = Color(0xFF10B981);       // Zümrüt yeşili
  static const Color lightSeafoam = Color(0xFF34D399);  // Canlı yeşilsu

  // Vurgu Renkleri (Çizgi Film / Oyuncu Tonlar)
  static const Color coral = Color(0xFFFF5277);         // Şeker pembesi
  static const Color amber = Color(0xFFFF9F1C);         // Canlı turuncu
  static const Color gold = Color(0xFFFFD166);          // Altın sarısı/Yıldız sarısı
  static const Color pearl = Color(0xFFF8FAFC);         // İnci beyazı

  // Nötr
  static const Color white = Color(0xFFFFFFFF);
  static const Color ghostWhite = Color(0xFFF1F5F9);
  static const Color silver = Color(0xFFCBD5E1);
  static const Color slate = Color(0xFF94A3B8);
  static const Color darkSlate = Color(0xFF475569);

  // Oyun ve Derinlik Efektleri
  static const Color shadowColor = Color(0xFF060E1A);    // 3D Buton ve kart gölgesi
  static const Color bubbleColor = Color(0x40A5F3FC);    // Yarı saydam kabarcık rengi

  // Balık büyüklük renkleri (oyun için)
  static const Color fishSmall = Color(0xFF10B981);     // Yeşil - yenilebilir
  static const Color fishMedium = Color(0xFFFF9F1C);    // Sarı - dikkatli
  static const Color fishDanger = Color(0xFFFF5277);    // Kırmızı - tehlikeli
  static const Color fishPlayer = Color(0xFF06B6D4);    // Aqua - oyuncu

  // Gradientler
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepOcean, darkOcean, oceanBlue],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x401E528F),
      Color(0x2006B6D4),
    ],
  );

  static const LinearGradient aquaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, aqua, lightAqua],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF061427),
      Color(0xFF0C213D),
      Color(0xFF12345E),
      Color(0xFF0E527D),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
}
