class FishModel {
  final String id;
  final String name;           // Türkçe ad
  final String scientificName; // Latince ad
  final String family;         // Familya
  final String habitat;        // Yaşam alanı
  final String depth;          // Yaşam derinliği
  final String length;         // Ortalama boy
  final String weight;         // Ortalama ağırlık
  final String description;    // Açıklama
  final String diet;           // Beslenme
  final String season;         // Avlanma sezonu
  final String rarity;         // Nadir / Yaygın / Çok Yaygın
  final String emoji;          // Emoji temsili
  final String modelUrl;       // 3D GLB model URL'i (AR için)
  final double arScale;        // AR model ölçek katsayısı
  final int colorValue;        // Kart rengi (int)

  const FishModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.family,
    required this.habitat,
    required this.depth,
    required this.length,
    required this.weight,
    required this.description,
    required this.diet,
    required this.season,
    required this.rarity,
    required this.emoji,
    required this.modelUrl,
    required this.arScale,
    required this.colorValue,
  });
}
