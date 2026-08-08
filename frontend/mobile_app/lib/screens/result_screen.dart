// frontend/mobile_app/lib/screens/result_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Color kPrimary     = Color(0xFFC13B57);
const Color kPrimaryPink = Color(0xFFE14D75);
const Color kBg          = Color(0xFFFFF5F7);
const Color kGreen       = Color(0xFF2E7D32);
const Color kGray        = Color(0xFF6B7280);
const Color kBlack       = Color(0xFF111111);

class ResultScreen extends StatefulWidget {
  final XFile xfile;
  final Map<String, dynamic> resultData;

  const ResultScreen({
    super.key,
    required this.xfile,
    required this.resultData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _activeTab = 0;

  final List<String> _tabs = [
    'Growth Progress',
    'Care Basics',
    'Care Actions',
    'Uses & Facts',
  ];

  // ── CARTOON images for Growth Progress timeline ───────────────
  // These are the illustration/cartoon style images
  final List<Map<String, dynamic>> _stagesCartoon = [
    {'key': 'Bud',         'label': 'Bud',         'cartoon': 'assets/images/bud.png'},
    {'key': 'Flower',      'label': 'Flower',       'cartoon': 'assets/images/bud.png'},     // use bud as fallback if no flower cartoon
    {'key': 'EarlyFruit',  'label': 'Early Fruit',  'cartoon': 'assets/images/early_fruit.png'},
    {'key': 'MidGrowth',   'label': 'Mid Growth',   'cartoon': 'assets/images/mid_growth.png'},
    {'key': 'MatureFruit', 'label': 'Mature',       'cartoon': 'assets/images/Mature.png'},
  ];

  // ── REAL PHOTO images for Detected & Next Stage cards ─────────
  // These are the realistic farm photos
  final Map<String, String> _stageRealPhotos = {
    'Bud':         'assets/images/bud.png',           // use cartoon as fallback
    'Flower':      'assets/images/Flower.jpg',
    'EarlyFruit':  'assets/images/Early_Fruit.jpg',
    'MidGrowth':   'assets/images/Mid_Growth.jpg',
    'MatureFruit': 'assets/images/Mature_fruit.jpg',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Data helpers ─────────────────────────────────────────────
  String get _detectedStage =>
      widget.resultData['growth_stage']?['detected'] ?? 'Unknown';
  String get _displayName =>
      widget.resultData['growth_stage']?['display_name'] ?? 'Unknown';
  double get _confidence =>
      (widget.resultData['growth_stage']?['confidence_percent'] ?? 0)
          .toDouble();
  int get _estimatedDays =>
      widget.resultData['harvest_prediction']?['estimated_days'] ?? 0;
  String get _nextStage =>
      widget.resultData['next_stage'] ?? '';
  String get _careTip =>
      widget.resultData['recommendations']?['care_tip'] ?? '';
  String get _riskWarning =>
      widget.resultData['recommendations']?['risk_warning'] ?? '';
  String get _weatherCondition =>
      widget.resultData['weather']?['condition'] ?? '';
  double get _temperature =>
      (widget.resultData['weather']?['temperature_celsius'] ?? 0)
          .toDouble();

  int get _currentStageIndex =>
      _stagesCartoon.indexWhere((s) => s['key'] == _detectedStage);

  String get _cleanStageName =>
      _displayName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

  String get _nextStageName {
    switch (_nextStage) {
      case 'Flower':      return 'Flower Stage';
      case 'EarlyFruit':  return 'Early Fruit Stage';
      case 'MidGrowth':   return 'Mid Growth Stage';
      case 'MatureFruit': return 'Mature Fruit Stage';
      default:            return 'Ready to Harvest';
    }
  }

  int get _transitionDays {
    switch (_detectedStage) {
      case 'Bud':        return 30;
      case 'Flower':     return 14;
      case 'EarlyFruit': return 21;
      case 'MidGrowth':  return 30;
      default:           return 0;
    }
  }

  // Real photo asset for detected stage
  String get _currentRealPhoto =>
      _stageRealPhotos[_detectedStage] ?? 'assets/images/bud.png';

  // Real photo asset for next stage
  String get _nextRealPhoto =>
      _stageRealPhotos[_nextStage] ?? 'assets/images/Mature_fruit.jpg';

  // ── Image widgets ─────────────────────────────────────────────

  // Cartoon/illustration image (for timeline)
  Widget _cartoonImg(String assetPath, {double size = 36}) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.eco_rounded, color: kPrimary, size: size * 0.6),
    );
  }

  // Real photo image (for cards) — rounded rectangle
  Widget _realPhotoImg(String assetPath,
      {double width = 64, double height = 64, double radius = 14}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width, height: height,
          decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(radius)),
          child: Icon(Icons.eco_rounded, color: kPrimary,
              size: width * 0.4),
        ),
      ),
    );
  }

  // Farmer's uploaded image
  Widget _uploadedImg(
      {double width = 60, double height = 60, double radius = 12}) {
    return FutureBuilder<Uint8List>(
      future: widget.xfile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(snapshot.data!,
                width: width, height: height, fit: BoxFit.cover),
          );
        }
        return Container(
          width: width, height: height,
          decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(radius)),
          child: const Icon(Icons.eco_rounded, color: kPrimary, size: 28),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Column(
              children: [

                // ── Top navigation bar ───────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom:
                        BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kPrimary.withOpacity(0.2)),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15, color: kPrimary),
                        ),
                      ),
                      const Expanded(
                        child: Text('Results',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kBlack)),
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: kPrimary.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.share_rounded,
                            size: 16, color: kPrimary),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Header
                        const Text('Detected Result',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: kBlack)),
                        const SizedBox(height: 2),
                        Text(
                          'AI-powered pomegranate growth stage detection',
                          style: TextStyle(fontSize: 12, color: kGray),
                        ),

                        const SizedBox(height: 12),

                        // ── Detected stage card ─────────────
                        // Uses REAL PHOTO on right side
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kPrimary.withOpacity(0.2),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: kPrimary.withOpacity(0.07),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left: farmer's uploaded image
                              _uploadedImg(
                                  width: 60, height: 60, radius: 12),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('DETECTED STAGE',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: kGray,
                                            letterSpacing: 0.8)),
                                    const SizedBox(height: 3),
                                    Text(_cleanStageName,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: kBlack)),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: const BoxDecoration(
                                            color: kGreen,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Confidence Score ${_confidence.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kGreen),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right: REAL PHOTO of detected stage
                              _realPhotoImg(_currentRealPhoto,
                                  width: 56, height: 56, radius: 12),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Next stage card ─────────────────
                        // Uses REAL PHOTO on left side
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left: REAL PHOTO of next stage
                              _detectedStage == 'MatureFruit'
                                  ? Container(
                                      width: 64, height: 64,
                                      decoration: BoxDecoration(
                                        color: kBg,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: Text('✅',
                                            style: TextStyle(
                                                fontSize: 30))))
                                  : _realPhotoImg(_nextRealPhoto,
                                      width: 64,
                                      height: 64,
                                      radius: 14),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Coming Next',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: kGray)),
                                    Text(_nextStageName,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: kBlack)),
                                    const SizedBox(height: 6),
                                    _infoRow(
                                        Icons.schedule_rounded,
                                        'Estimated transition',
                                        _detectedStage == 'MatureFruit'
                                            ? 'Ready!'
                                            : '$_transitionDays Days'),
                                    const SizedBox(height: 4),
                                    _infoRow(
                                        Icons.agriculture_rounded,
                                        'Estimated Days to Harvest',
                                        _detectedStage == 'MatureFruit'
                                            ? 'Now!'
                                            : '$_estimatedDays Days'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Tab bar ─────────────────────────
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _tabs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final active = i == _activeTab;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _activeTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? const LinearGradient(
                                            colors: [
                                                kPrimary,
                                                kPrimaryPink
                                              ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight)
                                        : null,
                                    color: active ? null : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: active
                                        ? null
                                        : Border.all(
                                            color: Colors.grey.shade200),
                                  ),
                                  child: Text(_tabs[i],
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: active
                                              ? Colors.white
                                              : kGray)),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Tab content ─────────────────────
                        if (_activeTab == 0)
                          _growthProgressSection()
                        else if (_activeTab == 1)
                          _tipCard(
                              icon: Icons.water_drop_outlined,
                              title: 'Care Tips',
                              content: _careTip.isNotEmpty
                                  ? _careTip
                                  : 'Maintain regular irrigation and monitor fruit development.',
                              isWarning: false)
                        else if (_activeTab == 2)
                          _tipCard(
                              icon: Icons.warning_amber_rounded,
                              title: 'Risk Warning',
                              content: _riskWarning.isNotEmpty
                                  ? _riskWarning
                                  : 'Monitor weather and protect from pests.',
                              isWarning: true)
                        else
                          _usesFactsSection(),

                        const SizedBox(height: 14),

                        // ── Weather strip ───────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kPrimary.withOpacity(0.15)),
                          ),
                          child: Row(children: [
                            Icon(
                              _weatherCondition == 'Rainy'
                                  ? Icons.water_drop_rounded
                                  : Icons.wb_sunny_rounded,
                              color: kPrimary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Weather: $_weatherCondition · ${_temperature.toStringAsFixed(1)}°C · Harvest adjusted',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        // ── Scan Again ──────────────────────
                        GestureDetector(
                          onTap: () => Navigator.popUntil(
                              context, (r) => r.isFirst),
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimary, kPrimaryPink],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                    color: kPrimary.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5)),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Scan Again',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                _bottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Growth Progress timeline — CARTOON images ─────────────────
  Widget _growthProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Growth Progress',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kBlack)),
        const SizedBox(height: 14),
        Row(
          children: List.generate(_stagesCartoon.length, (i) {
            final isPast    = i < _currentStageIndex;
            final isCurrent = i == _currentStageIndex;
            final cartoon   = _stagesCartoon[i]['cartoon'] as String;
            final label     = _stagesCartoon[i]['label'] as String;

            return Expanded(
              child: Column(children: [
                Row(children: [
                  // Left connector line
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isPast
                            ? kGreen
                            : Colors.grey.shade200,
                      ),
                    ),

                  // Stage circle with CARTOON image
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isCurrent ? 50 : 40,
                    height: isCurrent ? 50 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast
                          ? kGreen
                          : Colors.white,
                      border: Border.all(
                        color: isCurrent
                            ? kPrimary
                            : isPast
                                ? kGreen
                                : Colors.grey.shade300,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: isPast
                        // Completed: green circle with check
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        // Current or future: cartoon image
                        : ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _cartoonImg(cartoon,
                                  size: isCurrent ? 38 : 30),
                            ),
                          ),
                  ),

                  // Right connector line
                  if (i < _stagesCartoon.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isPast
                            ? kGreen
                            : Colors.grey.shade200,
                      ),
                    ),
                ]),

                const SizedBox(height: 6),

                // Stage label
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: isCurrent
                        ? kPrimary
                        : isPast
                            ? kGreen
                            : kGray,
                  ),
                ),
              ]),
            );
          }),
        ),
      ],
    );
  }

  Widget _tipCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isWarning,
  }) {
    final color = isWarning ? const Color(0xFFE76F51) : kGreen;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(content,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usesFactsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline_rounded, color: kPrimary, size: 16),
            SizedBox(width: 6),
            Text('Pomegranate Facts',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kPrimary)),
          ]),
          const SizedBox(height: 10),
          ...[
            'Rich in antioxidants and vitamins',
            'Used in food, medicine, and beverages',
            'Takes 5–7 months from bud to harvest',
            'Grown in dry and semi-arid regions',
            'High export value in Sri Lanka',
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 5, color: kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 13, color: kGray),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: kGray)),
      const Spacer(),
      Text(value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: kBlack)),
    ]);
  }

  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', false),
          _navItem(Icons.history_rounded, 'History', false),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: kPrimary.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Colors.white, size: 24),
          ),
          _navItem(Icons.bar_chart_rounded, 'Reports', false),
          _navItem(Icons.person_rounded, 'Profile', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? kPrimary : Colors.grey[400]!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.normal)),
    ]);
  }
}