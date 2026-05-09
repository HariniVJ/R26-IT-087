import 'dart:async';
import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import 'quality_grading_screen.dart';

// Later team members can add real imports here:
// import 'soil_analysis_screen.dart';
// import 'fruit_growth_screen.dart';
// import 'disease_detection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // USER DETAILS
  static const String userName = 'Akaran';
  static const String farmName = "Akaran's Farm";

  // COMMON COLORS
  static const Color glassBaseColor = Color(0xFF8B1A2F);
  static const Color glassBorderColor = Color(0xFFD44060);

  // TRANSPARENCY CONTROL
  // Decrease value = more transparent
  static const double glassOpacity = 0.40;
  static const double cardOpacity = 0.99;
  static const double borderOpacity = 0.32;
  static const double chipOpacity = 0.22;

  // COMMON SIZE
  static const double cardRadius = 22;

  late Timer _timer;
  late DateTime _now;

  final WeatherService _weatherService = WeatherService();
  WeatherData? _weather;
  bool _weatherLoading = true;
  String? _weatherError;

  late final List<AnimationController> _buttonControllers;
  late final List<Animation<double>> _buttonAnimations;

  late final List<DashboardItem> _items;

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _buttonControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _buttonAnimations = _buttonControllers
        .map(
          (controller) =>
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        )
        .toList();

    for (int i = 0; i < _buttonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 250 + i * 130), () {
        if (mounted) _buttonControllers[i].forward();
      });
    }

    _items = const [
      DashboardItem(
        title: 'Soil Analysis',
        subtitle: 'NPK & Moisture',
        emoji: '🌱',
        color: Color.fromARGB(255, 191, 143, 12),
        screenName: 'soil',
      ),
      DashboardItem(
        title: 'Fruit Growth',
        subtitle: 'Stage & Harvest',
        emoji: '🌿',
        color: Color.fromARGB(255, 240, 92, 92),
        screenName: 'growth',
      ),
      DashboardItem(
        title: 'Disease Detect',
        subtitle: 'Scan & Treat',
        emoji: '🔬',
        color: Color.fromARGB(255, 12, 191, 128),
        screenName: 'disease',
      ),
      DashboardItem(
        title: 'Quality Grading',
        subtitle: 'AI Analysis',
        emoji: '🍎',
        color: Color.fromARGB(255, 140, 12, 191),
        screenName: 'grading',
      ),
    ];

    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final data = await _weatherService.fetchWeather();

      if (mounted) {
        setState(() {
          _weather = data;
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

  @override
  void dispose() {
    _timer.cancel();

    for (final controller in _buttonControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  String get _clock {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _greeting {
    final h = _now.hour;

    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _date {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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

    return '${weekDays[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  Widget _glassBox({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    double radius = 20,
    double opacity = glassOpacity,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: glassBaseColor.withOpacity(opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: glassBorderColor.withOpacity(borderOpacity),
            width: 1.2,
          ),
        ),
        child: child,
      ),
    );
  }

  void _openScreen(DashboardItem item) {
    Widget screen;

    switch (item.screenName) {
      case 'grading':
        screen = const QualityGradingScreen();
        break;

      // When other members finish pages, uncomment and replace here:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/farm_bg1.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
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
              );
            },
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A0408).withOpacity(0.60),
                  const Color(0xFF3D0C18).withOpacity(0.25),
                  const Color(0xFF1A0408).withOpacity(0.68),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topRow(),
                  const SizedBox(height: 18),
                  _greetingSection(),
                  const SizedBox(height: 18),
                  _weatherCard(),
                  const SizedBox(height: 28),
                  _sectionTitle(),
                  const SizedBox(height: 14),
                  _dashboardGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topRow() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [glassBaseColor, glassBorderColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
          ),
          child: Center(
            child: Text(
              userName.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                farmName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                _date,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        _glassBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          radius: 30,
          opacity: 0.16,
          child: Text(
            _clock,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _greetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$_greeting  ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 14,
              ),
            ),
            const Text('🌾', style: TextStyle(fontSize: 16)),
          ],
        ),
        const Text(
          userName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _weatherCard() {
    if (_weatherLoading) {
      return _glassBox(
        padding: const EdgeInsets.all(20),
        opacity: 0.13,
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white60,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Fetching weather...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_weatherError != null || _weather == null) {
      return _glassBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: 0.13,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.white54,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _weatherError ?? 'Weather unavailable',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadWeather,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final w = _weather!;

    return _glassBox(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      opacity: 0.80,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(w.weatherEmoji, style: const TextStyle(fontSize: 46)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.temp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          w.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 70,
                color: Colors.white.withOpacity(0.14),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _weatherRow('💧', 'Humidity', w.humidity),
                  const SizedBox(height: 10),
                  _weatherRow('💨', 'Wind', w.wind),
                  const SizedBox(height: 10),
                  _weatherRow('🌡️', 'Feels', w.feelsLike),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: glassBorderColor.withOpacity(0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${w.location}, ${w.country}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _loadWeather,
                child: Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherRow(String icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.48),
                fontSize: 9,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: glassBorderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farm Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Select a module to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.52),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.88,
      children: List.generate(
        _items.length,
        (index) => ScaleTransition(
          scale: _buttonAnimations[index],
          child: DashboardModuleButton(
            item: _items[index],
            onTap: () => _openScreen(_items[index]),
          ),
        ),
      ),
    );
  }
}

class DashboardItem {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String screenName;

  const DashboardItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.screenName,
  });
}

class DashboardModuleButton extends StatefulWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const DashboardModuleButton({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<DashboardModuleButton> createState() => _DashboardModuleButtonState();
}

class _DashboardModuleButtonState extends State<DashboardModuleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              _DashboardScreenState.cardRadius,
            ),
            color: Color.lerp(
              _DashboardScreenState.glassBaseColor.withOpacity(
                _DashboardScreenState.cardOpacity,
              ),
              item.color.withOpacity(_DashboardScreenState.cardOpacity),
              0.5,
            ),
            border: Border.all(
              color: item.color.withOpacity(
                _DashboardScreenState.borderOpacity,
              ),
              width: 1.1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -35,
                left: -35,
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withOpacity(0.16),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.color.withOpacity(0.36),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(
                            _DashboardScreenState.chipOpacity,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final Color color;

  const ComingSoonScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.withOpacity(0.06),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title page will be connected by team member',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
