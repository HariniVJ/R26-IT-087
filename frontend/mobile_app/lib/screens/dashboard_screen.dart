// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../theme/app_colors.dart';
import '../models/dashboard_item.dart';
import '../widgets/module_button.dart';
import '../widgets/weather_card.dart';
import '../services/weather_service.dart';
import '../../common/brand_color.dart';

import 'irrigation_screen.dart';
import 'fertilizer_screen.dart';
import 'quality_grading_screen.dart';
import '../screens/dashboard_view.dart';
import 'coming_soon_screen.dart';
import '../screens/capture_screen.dart';
import '../screens/profile_view.dart';

const _red = Color(0xFFC1121F);
const _redSoft = Color(0xFFFFEEF3);
const _redCard = Color(0xFFFFF1F5);
const _textDark = Color(0xFF1F2937);
const _textSoft = Color(0xFF6B7280);

const _modules = [
  DashboardItem(
    title: 'Irrigation Advice',
    subtitle: 'Check water suitability',
    emoji: '💧',
    color:  BrandColor.primary,
    screenName: 'irrigation',
  ),
  DashboardItem(
    title: 'Fruit Growth',
    subtitle: 'Stage & Harvest',
    emoji: '🌿',
    color:  BrandColor.primary,
    screenName: 'growth',
  ),
  DashboardItem(
    title: 'Disease Detect',
    subtitle: 'Scan & Treat',
    emoji: '🔬',
    color:  BrandColor.primary,
    screenName: 'disease',
  ),
  DashboardItem(
    title: 'Quality Grading',
    subtitle: 'AI Analysis',
    emoji: '🍎',
    color:  BrandColor.primary,
    screenName: 'grading',
  ),
  DashboardItem(
    title: 'Fertilizer',
    subtitle: 'NPK & fertilizer amount',
    emoji: '🧪',
    color:  BrandColor.primary,
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
          _weatherError = 'Could not load weather';
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
      bottomNavigationBar: const AppBottomNavBar(),
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

              Container(
                decoration: BoxDecoration(
                  color:  BrandColor.primary,
                  borderRadius: BorderRadius.circular(22),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: BrandColor.primary,
                  //     blurRadius: 18,
                  //     offset: const Offset(0, 6),
                  //   ),
                  // ],
                ),
                child: WeatherCard(
                  isLoading: _weatherLoading,
                  error: _weatherError,
                  data: _weather,
                  onRetry: _loadWeather,
                ),
              ),

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
        decoration: const BoxDecoration(shape: BoxShape.circle, color: BrandColor.primary,
        ),
        child: Center(
          child: Text(
            AppConstants.farmerName.substring(0, 2).toUpperCase(),
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
              AppConstants.farmName,
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
    ],
  );

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
        AppConstants.farmerName,
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
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Management',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Select a module to get started',
            style: TextStyle(
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

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const _red = Color(0xFFC1121F);
  static const _soft = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
          _NavItem(icon: Icons.history_rounded, label: 'History'),
          _ScanButton(),
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileView()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? BrandColor.primary : AppBottomNavBar._soft;

    return GestureDetector(
  onTap: onTap,
  child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: BrandColor.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppBottomNavBar._red.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 28),
    );
  }
}
