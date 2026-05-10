// lib/screens/dashboard_screen.dart
// Dashboard screen — imports all shared widgets and config.
// To change colors  → edit lib/theme/app_colors.dart
// To change sizes   → edit lib/config/app_constants.dart
// To change buttons → edit lib/widgets/module_button.dart
// To change weather → edit lib/widgets/weather_card.dart
// To add real screens → update _openScreen() switch cases below

import 'dart:async';
import 'package:flutter/material.dart';

// ── Config & theme ────────────────────────────────────────────────────────────
import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

// ── Data model ────────────────────────────────────────────────────────────────
import '../models/dashboard_item.dart';

// ── Reusable widgets ──────────────────────────────────────────────────────────
import '../widgets/glass_box.dart';
import '../widgets/module_button.dart';
import '../widgets/weather_card.dart';

// ── Services ──────────────────────────────────────────────────────────────────
import '../services/weather_service.dart';

// ── Screens ───────────────────────────────────────────────────────────────────
import 'quality_grading_screen.dart';
import 'coming_soon_screen.dart';
// When team members finish their screens, add imports here:
// import 'soil_analysis_screen.dart';
// import 'fruit_growth_screen.dart';
// import 'disease_detection_screen.dart';

// ── Module list — ADD / REMOVE / REORDER here only ───────────────────────────
// Colors come from AppColors so changing one place updates all buttons
const _modules = [
  DashboardItem(
    title: 'Soil Analysis',
    subtitle: 'NPK & Moisture',
    emoji: '🌱',
    color: AppColors.soilColor,
    screenName: 'soil',
  ),
  DashboardItem(
    title: 'Fruit Growth',
    subtitle: 'Stage & Harvest',
    emoji: '🌿',
    color: AppColors.growthColor,
    screenName: 'growth',
  ),
  DashboardItem(
    title: 'Disease Detect',
    subtitle: 'Scan & Treat',
    emoji: '🔬',
    color: AppColors.diseaseColor,
    screenName: 'disease',
  ),
  DashboardItem(
    title: 'Quality Grading',
    subtitle: 'AI Analysis',
    emoji: '🍎',
    color: AppColors.gradingColor,
    screenName: 'grading',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // ── Time ──────────────────────────────────────────────────────────────────
  late Timer _timer;
  late DateTime _now;

  // ── Weather ───────────────────────────────────────────────────────────────
  final _weatherSvc = WeatherService();
  WeatherData? _weather;
  bool _weatherLoading = true;
  String? _weatherError;

  // ── Button entrance animations ────────────────────────────────────────────
  late final List<AnimationController> _btnCtrls;
  late final List<Animation<double>> _btnAnims;

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Staggered scale-in for each module button
    _btnCtrls = List.generate(
      _modules.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );
    _btnAnims = _btnCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();

    for (int i = 0; i < _btnCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 250 + i * 130), () {
        if (mounted) _btnCtrls[i].forward();
      });
    }

    _loadWeather();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _btnCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });
    try {
      final d = await _weatherSvc.fetchWeather();
      if (mounted)
        setState(() {
          _weather = d;
          _weatherLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _weatherLoading = false;
          _weatherError = 'Could not load weather';
        });
    }
  }

  // ── Navigation — only change this method to connect new screens ───────────
  void _openScreen(DashboardItem item) {
    Widget screen;
    switch (item.screenName) {
      case 'grading':
        screen = const QualityGradingScreen();
        break;
      // Uncomment when team members finish their screens:
      // case 'soil':
      //   screen = const SoilAnalysisScreen();
      //   break;
      // case 'growth':
      //   screen = const FruitGrowthScreen();
      //   break;
      // case 'disease':
      //   screen = const DiseaseDetectionScreen();
      //   break;
      default:
        screen = ComingSoonScreen(title: item.title, color: item.color);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ── Time helpers ──────────────────────────────────────────────────────────
  String get _clock {
    return '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _date {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${wd[_now.weekday - 1]}, ${_now.day} ${mo[_now.month - 1]} ${_now.year}';
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — background image
          Image.asset(
            AppConstants.bgImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D0A12),
                    Color(0xFF5C1A28),
                    Color(0xFF1A0A0E),
                  ],
                ),
              ),
            ),
          ),

          // Layer 2 — dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.overlayTop,
                  AppColors.overlayMid,
                  AppColors.overlayBottom,
                ],
              ),
            ),
          ),

          // Layer 3 — content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                12,
                AppConstants.screenPadding,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topRow(),
                  const SizedBox(height: 18),
                  _greeting2(),
                  const SizedBox(height: 18),

                  // ── Weather card (reusable widget) ───────────────────────
                  WeatherCard(
                    isLoading: _weatherLoading,
                    error: _weatherError,
                    data: _weather,
                    onRetry: _loadWeather,
                  ),

                  const SizedBox(height: AppConstants.sectionGap),
                  _sectionTitle(),
                  const SizedBox(height: 14),

                  // ── Module grid ──────────────────────────────────────────
                  GridView.count(
                    crossAxisCount: AppConstants.gridColumns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppConstants.gridSpacing,
                    mainAxisSpacing: AppConstants.gridSpacing,
                    childAspectRatio: AppConstants.gridAspectRatio,
                    children: List.generate(
                      _modules.length,
                      (i) => ScaleTransition(
                        scale: _btnAnims[i],
                        // ── Reusable ModuleButton widget ─────────────────
                        child: ModuleButton(
                          item: _modules[i],
                          onTap: () => _openScreen(_modules[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top row ────────────────────────────────────────────────────────────────
  Widget _topRow() => Row(
    children: [
      // Avatar
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.crimson, AppColors.rose],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
        ),
        child: Center(
          child: Text(
            AppConstants.farmerName.substring(0, 2).toUpperCase(),
            style: AppTextStyles.farmName.copyWith(fontSize: 15),
          ),
        ),
      ),
      const SizedBox(width: 12),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.farmName, style: AppTextStyles.farmName),
            Text(
              _date,
              style: TextStyle(color: AppColors.textWhiteFaint, fontSize: 11),
            ),
          ],
        ),
      ),

      // Live clock — uses GlassBox
      GlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        radius: AppConstants.clockRadius,
        child: Text(_clock, style: AppTextStyles.clock),
      ),
    ],
  );

  // ── Greeting ───────────────────────────────────────────────────────────────
  Widget _greeting2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            '$_greeting  ',
            style: TextStyle(color: AppColors.textWhiteSoft, fontSize: 14),
          ),
          const Text('🌾', style: TextStyle(fontSize: 16)),
        ],
      ),
      Text(AppConstants.farmerName, style: AppTextStyles.farmerName),
    ],
  );

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _sectionTitle() => Row(
    children: [
      Container(
        width: 4,
        height: 22,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farm Management', style: AppTextStyles.sectionTitle),
          Text(
            'Select a module to get started',
            style: TextStyle(color: AppColors.textWhiteFaint, fontSize: 12),
          ),
        ],
      ),
    ],
  );
}
