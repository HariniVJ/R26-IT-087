// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../models/dashboard_item.dart';
import '../widgets/module_button.dart';
import '../widgets/weather_card.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../services/weather/weather_service.dart';
import '../../common/brand_color.dart';
import '../services/auth/auth_service.dart';
import '../services/firebase/firestore_service.dart';
import '../l10n/app_strings.dart';

import 'irrigation/irrigation_screen.dart';
import 'fertilizer/fertilizer_screen.dart';
import 'quality_grading_screen.dart';
import '../screens/dashboard_view/dashboard_view.dart';
import 'coming_soon_screen.dart';
import '../screens/capture_screen.dart';
import 'notifications/notifications_screen.dart';
import 'weather/weather_details_screen.dart';

const _red = Color(0xFFC1121F);
const _redSoft = Color(0xFFFFEEF3);
const _textDark = Color(0xFF1F2937);
const _textSoft = Color(0xFF6B7280);

const _modules = [
  DashboardItem(
    title: 'Irrigation Advice',
    subtitle: 'Check water suitability',
    emoji: '💧',
    color: BrandColor.primary,
    screenName: 'irrigation',
  ),
  DashboardItem(
    title: 'Fruit Growth',
    subtitle: 'Stage & Harvest',
    emoji: '🌿',
    color: BrandColor.primary,
    screenName: 'growth',
  ),
  DashboardItem(
    title: 'Disease Detect',
    subtitle: 'Scan & Treat',
    emoji: '🔬',
    color: BrandColor.primary,
    screenName: 'disease',
  ),
  DashboardItem(
    title: 'Quality Grading',
    subtitle: 'AI Analysis',
    emoji: '🍎',
    color: BrandColor.primary,
    screenName: 'grading',
  ),
  DashboardItem(
    title: 'Fertilizer',
    subtitle: 'NPK & fertilizer amount',
    emoji: '🧪',
    color: BrandColor.primary,
    screenName: 'fertilizer',
  ),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;

  final _weatherSvc = WeatherService();
  WeatherData? _weather;
  bool _weatherLoading = true;
  String? _weatherError;

  late final List<AnimationController> _btnCtrls;
  late final List<Animation<double>> _btnAnims;

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

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
    for (final c in _btnCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final d = await _weatherSvc.fetchWeather();
      if (d.raw != null) {
        await FirestoreService.instance.notifyRainIfNeeded(d.raw!);
        await FirestoreService.instance.saveWeather(weather: d.raw!);
      }
      if (mounted) {
        setState(() {
          _weather = d;
          _weatherLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
          _weatherError = t('weatherUnavailable');
        });
      }
    }
  }

  void _openScreen(DashboardItem item) {
    Widget screen;

    switch (item.screenName) {
      case 'irrigation':
        screen = const IrrigationScreen();
        break;
      case 'fertilizer':
        screen = const FertilizerScreen();
        break;
      case 'disease':
        screen = const DashboardView();
        break;
      case 'growth':
        screen = const CaptureScreen();
        break;
      case 'grading':
        screen = const QualityGradingScreen();
        break;
      default:
        screen = ComingSoonScreen(title: item.title, color: item.color);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String get _farmerName {
    return AuthService.instance.currentFarmer?.fullName ??
        AppConstants.farmerName;
  }

  String get _farmName {
    final name = AuthService.instance.currentFarmer?.fullName;
    if (name == null || name.isEmpty) return AppConstants.farmName;
    return "$name's Farm";
  }

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

  @override
  Widget build(BuildContext context) {
    final firstFour = _modules.take(4).toList();
    final fertilizer = _modules[4];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.home),
      body: SafeArea(
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

              WeatherCard(
                isLoading: _weatherLoading,
                error: _weatherError,
                data: _weather,
                onRetry: _loadWeather,
                onOpen: _weather == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WeatherDetailsScreen(data: _weather!),
                          ),
                        );
                      },
              ),

              const SizedBox(height: 16),

              const SizedBox(height: AppConstants.sectionGap),
              _sectionTitle(),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: AppConstants.gridColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppConstants.gridSpacing,
                mainAxisSpacing: AppConstants.gridSpacing,
                childAspectRatio: AppConstants.gridAspectRatio,
                children: List.generate(
                  firstFour.length,
                  (i) => ScaleTransition(
                    scale: _btnAnims[i],
                    child: _moduleCard(firstFour[i]),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.gridSpacing),

              ScaleTransition(
                scale: _btnAnims[4],
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: _moduleCard(fertilizer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleCard(DashboardItem item) {
    return Container(
      decoration: BoxDecoration(
        //color: _redCard,
        color: BrandColor.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ModuleButton(item: item, onTap: () => _openScreen(item)),
    );
  }

  Widget _topRow() => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: BrandColor.primary,
        ),
        child: Center(
          child: Text(
            _farmerName.length >= 2
                ? _farmerName.substring(0, 2).toUpperCase()
                : _farmerName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _farmName,
              style: const TextStyle(
                color: _textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _date,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _redSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _red.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: _red, size: 13),
            const SizedBox(width: 5),
            Text(
              _clock,
              style: const TextStyle(
                color: _red,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _bell(),
    ],
  );

  Widget _bell() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _redSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _red.withOpacity(0.15)),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _red),
          ),
        ],
      ),
    );
  }

  Widget _greeting2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            '$_greeting ',
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text('🌾', style: TextStyle(fontSize: 14)),
        ],
      ),
      Text(
        _farmerName,
        style: const TextStyle(
          color: _textDark,
          fontSize: 25,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    ],
  );

  Widget _sectionTitle() => Row(
    children: [
      Container(
        width: 4,
        height: 24,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: _red,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('farmManagement'),
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            t('selectModule'),
            style: const TextStyle(
              color: _textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}
