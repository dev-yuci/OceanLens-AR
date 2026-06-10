import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/core/router/app_router.dart';
import 'package:ocean_lens_ar/core/widgets/ocean_button.dart';
import 'package:ocean_lens_ar/core/widgets/ocean_guide_fish.dart';
import 'package:ocean_lens_ar/features/museum/models/fish_model.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';

class FishDetailScreen extends StatefulWidget {
  final FishModel fish;

  const FishDetailScreen({super.key, required this.fish});

  @override
  State<FishDetailScreen> createState() => _FishDetailScreenState();
}

class _FishDetailScreenState extends State<FishDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentController, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200),
        () => _contentController.forward());
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final cardColor = Color(widget.fish.colorValue);

    return Scaffold(
      backgroundColor: AppColors.deepOcean,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroHeader(context, cardColor),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleRow(),
                          const SizedBox(height: 24),
                          _buildInfoGrid(),
                          const SizedBox(height: 24),
                          _buildSection('📖 Hakkında', widget.fish.description),
                          const SizedBox(height: 20),
                          _buildSection('🍽️ Beslenme Macerası', widget.fish.diet),
                          const SizedBox(height: 24),
                          _buildInfoRow(Icons.calendar_month_rounded, 'En Lezzetli Olduğu Sezon', widget.fish.season, AppColors.amber),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.map_rounded, 'Yaşadığı Denizler', widget.fish.habitat, AppColors.seafoam),
                          const SizedBox(height: 36),
                          _buildActionButtons(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          OceanGuideFish(
            messages: [
              "Bu balığın boyu tam ${widget.fish.length} kadarmış! AR butonuna dokunursan odanın ortasında yüzmesini izleyebilirsin! 🔮",
              "Bu sevimli canlı genellikle ${widget.fish.depth} derinliklerde yaşarmış! 🌊 Çok havalı değil mi?",
              "Onun en sevdiği yiyecekler: ${widget.fish.diet}! 🍽️ Tam bir gurme!",
              "Bu balığı en lezzetli ve bol bulabileceğin zaman: ${widget.fish.season}! 📅",
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, Color cardColor) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.deepOcean,
      leading: GestureDetector(
        onTap: () {
          AudioService.instance.playClick();
          context.pop();
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.6),
            border:
                Border.all(color: AppColors.white, width: 2),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.pearl, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'fish_${widget.fish.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withValues(alpha: 0.75),
                  AppColors.deepOcean,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Kabarcık desenleri
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                // Emoji ve etiket
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: ModelViewer(
                        src: widget.fish.modelUrl,
                        alt: widget.fish.name,
                        autoRotate: true,
                        cameraControls: true,
                        disableZoom: true,
                        backgroundColor: Colors.transparent,
                        autoPlay: true,
                        environmentImage: 'neutral',
                        shadowIntensity: 1.0,
                        exposure: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.white, width: 2),
                      ),
                      child: Text(
                        widget.fish.rarity,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.fish.name,
          style: GoogleFonts.fredoka(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.pearl,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.fish.scientificName,
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: AppColors.lightAqua,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Grup / Familya: ${widget.fish.family}',
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.silver.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('📏', 'Ortalama Boy', widget.fish.length, AppColors.teal)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatItem('⚖️', 'Ağırlık', widget.fish.weight, AppColors.coral)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatItem('🌊', 'Derinlik', widget.fish.depth, AppColors.lightSeafoam)),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 11,
              color: AppColors.pearl,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.pearl,
            )),
        const SizedBox(height: 10),
        Text(content,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.silver,
              height: 1.6,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oceanBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: AppColors.pearl,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        OceanButton(
          label: '3D AR Dünyasında Gör 🔮',
          icon: Icons.view_in_ar_rounded,
          width: double.infinity,
          onTap: () {
            AudioService.instance.playClick();
            context.push(AppRoutes.arViewer, extra: widget.fish);
          },
        ),
        const SizedBox(height: 14),
        OceanButton(
          label: 'Geri Dön',
          icon: Icons.arrow_back_rounded,
          isPrimary: false,
          width: double.infinity,
          onTap: () {
            AudioService.instance.playClick();
            context.pop();
          },
        ),
      ],
    );
  }
}
