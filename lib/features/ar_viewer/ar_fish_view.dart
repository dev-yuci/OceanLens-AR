import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_lens_ar/core/services/audio_service.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ocean_lens_ar/core/constants/app_colors.dart';
import 'package:ocean_lens_ar/features/museum/models/fish_model.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class ArFishView extends StatefulWidget {
  final FishModel fish;

  const ArFishView({super.key, required this.fish});

  @override
  State<ArFishView> createState() => _ArFishViewState();
}

class _ArFishViewState extends State<ArFishView> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  bool _isPlaneDetected = false;
  bool _isModelPlaced = false;
  bool _isInfoVisible = false;
  bool _isPlacing = false;
  String _statusMessage = 'Yüzey tarıyorum... Cihazı yatay zemine doğru tut';

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Üst bar
          SafeArea(child: _buildTopBar(context)),

          // Alt panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Plane algılama göstergesi
          if (!_isPlaneDetected)
            Center(child: _buildScanningIndicator()),

          // Balık bilgi kutusu
          if (_isInfoVisible && _isModelPlaced)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: 20,
              right: 20,
              child: _buildInfoCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              context.pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.4), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaneDetected ? AppColors.seafoam : AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              AudioService.instance.playClick();
              setState(() => _isInfoVisible = !_isInfoVisible);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isInfoVisible
                    ? AppColors.teal.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.4), width: 1),
              ),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aqua.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.aqua,
            strokeWidth: 2,
          ),
          const SizedBox(height: 12),
          Text(
            'Yüzey tarıyorum...',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cihazı yatay yüzeye doğru tut',
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balık adı
          Row(
            children: [
              Text(widget.fish.emoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fish.name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.fish.scientificName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Butonlar
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isModelPlaced ? _removeModel : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 
                          _isModelPlaced ? 0.2 : 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.coral.withValues(alpha: 
                            _isModelPlaced ? 0.4 : 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppColors.coral.withValues(alpha: 
                                _isModelPlaced ? 1 : 0.4),
                            size: 18),
                        const SizedBox(width: 6),
                        Text('Kaldır',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.coral.withValues(alpha: 
                                  _isModelPlaced ? 1 : 0.4),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: (_isPlaneDetected && !_isPlacing) ? _placeFishAtCenter : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _isPlaneDetected
                          ? AppColors.aquaGradient
                          : null,
                      color: _isPlaneDetected
                          ? null
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isPlaneDetected
                          ? [
                              BoxShadow(
                                color: AppColors.aqua.withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: -4,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isPlacing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.deepOcean,
                                ),
                              )
                            : Icon(Icons.add_circle_outline,
                                color: _isPlaneDetected
                                    ? AppColors.deepOcean
                                    : Colors.white30,
                                size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isModelPlaced
                              ? 'Yeniden Yerleştir'
                              : _isPlacing
                                  ? 'Yerleştiriliyor...'
                                  : _isPlaneDetected
                                      ? 'Ekrana Dokun / Yerleştir 👆'
                                      : 'Yüzey Bekleniyor...',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isPlaneDetected
                                ? AppColors.deepOcean
                                : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.aqua.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(widget.fish.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.fish.name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isInfoVisible = false),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          _infoRow('📏 Boy', widget.fish.length),
          _infoRow('⚖️ Ağırlık', widget.fish.weight),
          _infoRow('🌊 Derinlik', widget.fish.depth),
          _infoRow('🏠 Habitat', widget.fish.habitat),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white70,
                )),
          ),
        ],
      ),
    );
  }

  // AR callbacks
  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    _sessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
    );

    _objectManager!.onInitialize();

    // Yüzeye dokunarak yerleştirme
    _sessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

    // Plane algılandığında kullanıcıya haber ver
    _sessionManager!.onPlaneDetected = (int planeCount) {
      if (!_isPlaneDetected && mounted) {
        setState(() {
          _isPlaneDetected = true;
          _statusMessage = 'Yüzey bulundu! 👆 Ekrana dokun veya butona bas';
        });
      }
    };
  }

  /// Butona basıldığında kullanıcıya ekranın ortasına dokunmasını hatırlatan rehber gösterir.
  /// Plugin yalnızca onPlaneOrPointTap callback'i ile hit-test desteklediğinden,
  /// buton yalnızca görsel ipucu verir; asıl yerleştirme dokunma ile olur.
  Future<void> _placeFishAtCenter() async {
    if (_isPlacing) return;
    setState(() {
      _isPlacing = false;
      _statusMessage = '👇 Kameranın gördüğü yüzeye doğrudan dokunun!';
    });

    // 3 saniye sonra normal mesaja dön
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && !_isModelPlaced) {
      setState(() {
        _statusMessage = 'Yüzey bulundu! Ekrana dokun ve balığı yerleştir 🐠';
      });
    }
  }


  Future<void> _onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || _isPlacing) return;
    setState(() => _isPlacing = true);
    await _placeModel(hitTestResults);
  }

  /// Ortak model yerleştirme mantığı (hem dokunuştan hem butondan çağrılır)
  Future<void> _placeModel(List<ARHitTestResult> hitTestResults) async {
    final result = hitTestResults.first;

    setState(() {
      _isPlaneDetected = true;
      _statusMessage = 'Model hazırlanıyor...';
    });

    // Önceki modeli temizle
    if (_nodes.isNotEmpty) {
      await _removeModel();
    }

    // Anchor oluştur
    final anchor = ARPlaneAnchor(transformation: result.worldTransform);
    final didAddAnchor = await _anchorManager!.addAnchor(anchor);

    if (didAddAnchor != true) {
      setState(() {
        _isPlacing = false;
        _statusMessage = 'Anchor oluşturulamadı. Yüzeye tekrar dokun.';
      });
      return;
    }

    _anchors.add(anchor);

    // Model hazırla — NodeType.localGLB (type=0) Flutter asset loader'ı kullanır,
    // dosyayı diske kopyalamaya gerek yok. Native kod getLookupKeyForAsset ile çözüyor.
    ARNode node;
    try {
      // assets/ prefix'i zaten fish_data.dart'ta var (örn: 'assets/fish_models/Bream_Fish.glb')
      node = ARNode(
        type: NodeType.localGLTF2,
        uri: widget.fish.modelUrl,
        scale: vm.Vector3(widget.fish.arScale, widget.fish.arScale, widget.fish.arScale),
        position: vm.Vector3(0.0, 0.0, 0.0),
        rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      );
    } catch (e) {
      setState(() {
        _isPlacing = false;
        _statusMessage = 'Model yüklenemedi: $e';
      });
      return;
    }

    final didAddNode = await _objectManager!.addNode(node, planeAnchor: anchor);

    if (didAddNode == true) {
      AudioService.instance.playCorrect();
      _nodes.add(node);
      setState(() {
        _isPlacing = false;
        _isModelPlaced = true;
        _statusMessage = '${widget.fish.name} yerleştirildi! Etrafında dön 🐟';
      });
    } else {
      setState(() {
        _isPlacing = false;
        _statusMessage = 'Model yerleştirilemedi. Tekrar dene.';
      });
    }
  }

  Future<void> _removeModel() async {
    AudioService.instance.playClick();
    try {
      for (final node in _nodes) {
        try {
          _objectManager?.removeNode(node);
        } catch (e) {
          debugPrint('AR node removal failed: $e');
        }
      }
      for (final anchor in _anchors) {
        try {
          _anchorManager?.removeAnchor(anchor);
        } catch (e) {
          debugPrint('AR anchor removal failed: $e');
        }
      }
    } catch (e) {
      debugPrint('AR model removal error: $e');
    }
    _nodes.clear();
    _anchors.clear();
    if (mounted) {
      setState(() {
        _isPlacing = false;
        _isModelPlaced = false;
        _statusMessage = 'Yüzeye dokun ve model yerleştir 🐠';
      });
    }
  }
}
