import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/sensor/soil_bluetooth_service.dart';
import '../services/firebase/firestore_service.dart';

const Color kPrimary = Color(0xFFC13B57);
const Color kPrimaryPink = Color(0xFFE14D75);
const Color kBg = Color(0xFFFFF5F7);
const Color kGreen = Color(0xFF2E7D32);
const Color kOrange = Color(0xFFE76F51);
const Color kGray = Color(0xFF6B7280);
const Color kBlack = Color(0xFF111111);

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
  
  // Soil sensor state
  late final SoilBluetoothService _soilService;
  double? _liveSoilTemperature;

  final List<String> _tabs = [
    'Growth Progress',
    'Care Basics',
    'Care Actions',
  ];

  final List<Map<String, dynamic>> _stagesCartoon = [
    {
      'key': 'Bud',
      'label': 'Bud',
      'cartoon': 'assets/images/bud.png',
    },
    {
      'key': 'Flower',
      'label': 'Flower',
      'cartoon': 'assets/images/Flower.jpg',
    },
    {
      'key': 'EarlyFruit',
      'label': 'Early Fruit',
      'cartoon': 'assets/images/early_fruit.png',
    },
    {
      'key': 'MidGrowth',
      'label': 'Mid Growth',
      'cartoon': 'assets/images/mid_growth.png',
    },
    {
      'key': 'MatureFruit',
      'label': 'Mature',
      'cartoon': 'assets/images/Mature.png',
    },
  ];

  final Map<String, String> _stageRealPhotos = {
    'Bud': 'assets/images/bud.png',
    'Flower': 'assets/images/Flower.jpg',
    'EarlyFruit': 'assets/images/Early_Fruit.jpg',
    'MidGrowth': 'assets/images/Mid_Growth.jpg',
    'MatureFruit': 'assets/images/Mature_fruit.jpg',
  };

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
    
    // Initialize soil service and listen to latest readings
    _soilService = SoilBluetoothService.instance;
    _soilService.latestReading.addListener(_onSoilReadingChanged);
    _soilService.isConnected.addListener(_onSensorConnectionChanged);
    
    // Set initial value if available
    if (_soilService.latestReading.value != null) {
      _liveSoilTemperature = _soilService.latestReading.value!.temp;
    }
    
    // Start soil sensor connection
    _initializeSoilSensor();
    
    // Save growth detection result to Firebase
    _saveResultsToDatabase();
  }
  
  Future<void> _saveResultsToDatabase() async {
    try {
      await FirestoreService.instance.saveGrowthDetectionResult(
        resultData: widget.resultData,
        imagePath: widget.xfile.path,
        soilTemperature: _liveSoilTemperature,
        captureTime: DateTime.now(),
      );
      debugPrint('✓ Growth detection result saved to Firebase');
    } catch (e) {
      debugPrint('✗ Failed to save growth detection result: $e');
    }
  }

  Future<void> _initializeSoilSensor() async {
    try {
      // Only connect if not already connected
      if (!_soilService.isConnected.value) {
        await _soilService.connect();
      }
    } catch (e) {
      debugPrint('Failed to initialize soil sensor: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _soilService.latestReading.removeListener(_onSoilReadingChanged);
    _soilService.isConnected.removeListener(_onSensorConnectionChanged);
    super.dispose();
  }
  
  void _onSoilReadingChanged() {
    if (mounted) {
      setState(() {
        if (_soilService.latestReading.value != null) {
          _liveSoilTemperature = _soilService.latestReading.value!.temp;
        }
      });
    }
  }
  
  void _onSensorConnectionChanged() {
    if (mounted) {
      setState(() {
        // Trigger UI update when connection status changes
      });
    }
  }

  String get _detectedStage =>
      widget.resultData['growth_stage']?['detected'] ?? 'Unknown';

  String get _displayName =>
      widget.resultData['growth_stage']?['display_name'] ?? 'Unknown';

  double get _confidence =>
      (widget.resultData['growth_stage']?['confidence_percent'] ?? 0)
          .toDouble();

  String get _nextStage =>
      widget.resultData['next_stage'] ?? '';

  String get _transitionRange =>
      widget.resultData['transition_prediction']?['range'] ?? '';

  String get _captureDate =>
      widget.resultData['transition_prediction']?['capture_date'] ?? '';

  String get _estimatedStartDate =>
      widget.resultData['transition_prediction']?['estimated_start_date'] ?? '';

  String get _estimatedEndDate =>
      widget.resultData['transition_prediction']?['estimated_end_date'] ?? '';

  String get _estimatedDateRange =>
      widget.resultData['transition_prediction']?['estimated_date_range'] ?? '';

  String get _harvestRange =>
      widget.resultData['harvest_prediction']?['range'] ?? '';

  String get _careTip =>
      widget.resultData['recommendations']?['care_tip'] ?? '';

  String get _careAction =>
      widget.resultData['recommendations']?['care_action'] ?? '';

  String get _riskWarning =>
      widget.resultData['recommendations']?['risk_warning'] ?? '';

  bool get _weatherAvailable =>
      widget.resultData['weather']?['available'] ?? false;

  String get _weatherCondition =>
      widget.resultData['weather']?['condition'] ?? 'Unavailable';

  double? get _weatherTemperature =>
      (widget.resultData['weather']?['temperature_celsius'] as num?)
          ?.toDouble();

  double? get _humidity =>
      (widget.resultData['weather']?['humidity_percent'] as num?)
          ?.toDouble();

  bool get _soilAvailable =>
      _liveSoilTemperature != null ||
      widget.resultData['soil']?['available'] ?? false;

  double? get _soilTemperature =>
      _liveSoilTemperature ??
      (widget.resultData['soil']?['temperature_celsius'] as num?)
          ?.toDouble();
  
  String get _soilTemperatureDisplay {
    if (_liveSoilTemperature != null) {
      return '${_liveSoilTemperature!.toStringAsFixed(1)}°C (Live)';
    } else if (_soilTemperature != null) {
      return '${_soilTemperature!.toStringAsFixed(1)}°C';
    } else if (_soilService.isScanning.value) {
      return 'Scanning...';
    } else if (!_soilService.isConnected.value && _soilService.status.value.contains('not found')) {
      return 'Sensor not found';
    } else {
      return 'Connecting...';
    }
  }

  String get _environmentLevel =>
      widget.resultData['environment']?['level'] ?? 'Unknown';

  String get _environmentStatus =>
      widget.resultData['environment']?['status'] ??
      'Environmental status unavailable';

  String get _environmentReason =>
      widget.resultData['environment']?['reason'] ?? '';

  String get _environmentFarmerMessage =>
      widget.resultData['environment']?['farmer_message'] ?? '';

  String get _environmentHarvestImpact =>
      widget.resultData['environment']?['harvest_impact'] ?? '';

  int get _currentStageIndex {
    final index = _stagesCartoon.indexWhere(
      (stage) => stage['key'] == _detectedStage,
    );

    if (index < 0) {
      return 0;
    }

    return index;
  }

  String get _cleanStageName {
    switch (_detectedStage) {
      case 'Bud':
        return 'Bud Stage';
      case 'Flower':
        return 'Flower Stage';
      case 'EarlyFruit':
        return 'Early Fruit Stage';
      case 'MidGrowth':
        return 'Mid-Growth Stage';
      case 'MatureFruit':
        return 'Mature Fruit Stage';
      default:
        return _displayName;
    }
  }

  String get _nextStageName {
    switch (_nextStage) {
      case 'Flower':
        return 'Flower Stage';
      case 'EarlyFruit':
        return 'Early Fruit Stage';
      case 'MidGrowth':
        return 'Mid-Growth Stage';
      case 'MatureFruit':
        return 'Mature Fruit Stage';
      default:
        return '';
    }
  }

  String get _currentRealPhoto =>
      _stageRealPhotos[_detectedStage] ??
      'assets/images/bud.png';

  String get _nextRealPhoto =>
      _stageRealPhotos[_nextStage] ??
      'assets/images/Mature_fruit.jpg';

  Color get _environmentColor {
    switch (_environmentLevel.toLowerCase()) {
      case 'favourable':
        return kGreen;

      case 'caution':
        return kOrange;

      default:
        return kGray;
    }
  }

  IconData get _environmentIcon {
    switch (_environmentLevel.toLowerCase()) {
      case 'favourable':
        return Icons.check_circle_outline_rounded;

      case 'caution':
        return Icons.warning_amber_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _cartoonImg(
    String assetPath, {
    double size = 36,
  }) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco_rounded,
        color: kPrimary,
        size: size * 0.6,
      ),
    );
  }

  Widget _realPhotoImg(
    String assetPath, {
    double width = 64,
    double height = 64,
    double radius = 14,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(
            Icons.eco_rounded,
            color: kPrimary,
            size: width * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _uploadedImg({
    double width = 60,
    double height = 60,
    double radius = 12,
  }) {
    return FutureBuilder<Uint8List>(
      future: widget.xfile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: kPrimary,
            size: 28,
          ),
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
                _topBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detected Result',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kBlack,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'AI-powered pomegranate growth stage detection',
                          style: TextStyle(
                            fontSize: 12,
                            color: kGray,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _detectedStageCard(),

                        const SizedBox(height: 10),

                        _nextStageCard(),

                        if (_detectedStage != 'MatureFruit') ...[
                          const SizedBox(height: 12),
                          _predictionDateCard(),
                        ],

                        const SizedBox(height: 12),

                        _environmentCard(),

                        const SizedBox(height: 14),

                        _tabsBar(),

                        const SizedBox(height: 14),

                        _activeSection(),

                        const SizedBox(height: 14),

                        _scanAgainButton(),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: kPrimary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: kPrimary,
              ),
            ),
          ),

          const Expanded(
            child: Text(
              'Results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kBlack,
              ),
            ),
          ),

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: kPrimary.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.share_rounded,
              size: 16,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectedStageCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kPrimary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _uploadedImg(),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETECTED STAGE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kGray,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _cleanStageName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kBlack,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        'Confidence Score ${_confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _realPhotoImg(
            _currentRealPhoto,
            width: 56,
            height: 56,
            radius: 12,
          ),
        ],
      ),
    );
  }

  Widget _nextStageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_detectedStage == 'MatureFruit')
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: kGreen,
                  size: 34,
                ),
              ),
            )
          else
            _realPhotoImg(
              _nextRealPhoto,
              width: 68,
              height: 68,
              radius: 14,
            ),

          const SizedBox(width: 14),

          Expanded(
            child: _detectedStage == 'MatureFruit'
                ? _matureStageInfo()
                : _nextStageInfo(),
          ),
        ],
      ),
    );
  }

  Widget _nextStageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coming Next',
          style: TextStyle(
            fontSize: 10.5,
            color: kGray,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          _nextStageName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kBlack,
          ),
        ),

        const SizedBox(height: 10),

        _predictionInfo(
          icon: Icons.schedule_rounded,
          label: 'Estimated transition',
          value: _transitionRange,
        ),

        const SizedBox(height: 9),

        _predictionInfo(
          icon: Icons.calendar_month_rounded,
          label: 'Expected period',
          value: _estimatedDateRange,
        ),
      ],
    );
  }

  Widget _matureStageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Harvest Status',
          style: TextStyle(
            fontSize: 10.5,
            color: kGray,
          ),
        ),

        const SizedBox(height: 2),

        const Text(
          'Mature Fruit Stage Reached',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kGreen,
          ),
        ),

        const SizedBox(height: 10),

        _predictionInfo(
          icon: Icons.check_circle_outline_rounded,
          label: 'Current status',
          value: 'Ready for maturity assessment',
        ),
      ],
    );
  }

  Widget _predictionInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 14,
            color: kGray,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: kGray,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value.isNotEmpty
                    ? value
                    : 'Not available',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _predictionDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C978).withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 18,
                color: Color(0xFF9B6B00),
              ),

              SizedBox(width: 7),

              Text(
                'Growth Date Estimation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9B6B00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _dateRow(
            'Capture Date',
            _captureDate,
          ),

          const Divider(height: 17),

          _dateRow(
            'Earliest Estimated Date',
            _estimatedStartDate,
          ),

          const Divider(height: 17),

          _dateRow(
            'Latest Estimated Date',
            _estimatedEndDate,
          ),

          if (_harvestRange.isNotEmpty) ...[
            const Divider(height: 17),

            _dateRow(
              'Remaining to Mature',
              _harvestRange,
            ),
          ],

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'The expected dates are estimated from the farmer-observed stage timeline. Weather and soil conditions do not add or subtract days from this range.',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[700],
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: kGray,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Flexible(
          child: Text(
            value.isNotEmpty
                ? value
                : 'N/A',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: kBlack,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _environmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _environmentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _environmentColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _environmentIcon,
                color: _environmentColor,
                size: 19,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Development Condition',
                      style: TextStyle(
                        fontSize: 10,
                        color: kGray,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _environmentStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _environmentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _conditionValue(
                  title: 'Weather',
                  value: _weatherAvailable
                      ? _weatherCondition
                      : 'Unavailable',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _conditionValue(
                  title: 'Air Temperature',
                  value: _weatherTemperature != null
                      ? '${_weatherTemperature!.toStringAsFixed(1)}°C'
                      : 'N/A',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _conditionValue(
                  title: 'Soil Temperature',
                  value: _soilAvailable
                      ? _soilTemperatureDisplay
                      : 'Not connected',
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _conditionValue(
                  title: 'Humidity',
                  value: _humidity != null
                      ? '${_humidity!.toStringAsFixed(0)}%'
                      : 'N/A',
                ),
              ),
            ],
          ),

          if (_environmentReason.isNotEmpty) ...[
            const SizedBox(height: 12),

            Text(
              _environmentReason,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[700],
                height: 1.45,
              ),
            ),
          ],

          if (_environmentFarmerMessage.isNotEmpty) ...[
            const SizedBox(height: 9),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _environmentFarmerMessage,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kBlack,
                  height: 1.45,
                ),
              ),
            ),
          ],

          if (_environmentHarvestImpact.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              _environmentHarvestImpact,
              style: TextStyle(
                fontSize: 10.5,
                color: kGray,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conditionValue({
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 58,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              color: kGray,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: kBlack,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabsBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == _activeTab;

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeTab = i;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [
                          kPrimary,
                          kPrimaryPink,
                        ],
                      )
                    : null,
                color:
                    active ? null : Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                border: active
                    ? null
                    : Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
              ),
              child: Text(
                _tabs[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      active ? Colors.white : kGray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activeSection() {
    if (_activeTab == 0) {
      return _growthProgressSection();
    }

    if (_activeTab == 1) {
      return _tipCard(
        icon: Icons.water_drop_outlined,
        title: 'Care Basics',
        content: _careTip.isNotEmpty
            ? _careTip
            : 'No care information is available.',
        isWarning: false,
      );
    }

    return _careActionsSection();
  }

  Widget _careActionsSection() {
    return Column(
      children: [
        _tipCard(
          icon: Icons.task_alt_rounded,
          title: 'Care Action',
          content: _careAction.isNotEmpty
              ? _careAction
              : 'Continue regular crop monitoring.',
          isWarning: false,
        ),

        const SizedBox(height: 10),

        _tipCard(
          icon: Icons.warning_amber_rounded,
          title: 'Risk Warning',
          content: _riskWarning.isNotEmpty
              ? _riskWarning
              : 'No specific warning is available.',
          isWarning: true,
        ),
      ],
    );
  }

  Widget _growthProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth Progress',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kBlack,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: List.generate(
            _stagesCartoon.length,
            (i) {
              final isPast =
                  i < _currentStageIndex;

              final isCurrent =
                  i == _currentStageIndex;

              final cartoon =
                  _stagesCartoon[i]['cartoon']
                      as String;

              final label =
                  _stagesCartoon[i]['label']
                      as String;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  i <= _currentStageIndex
                                      ? kGreen
                                      : Colors.grey.shade200,
                            ),
                          ),

                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 400),
                          width:
                              isCurrent ? 48 : 38,
                          height:
                              isCurrent ? 48 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isPast ? kGreen : Colors.white,
                            border: Border.all(
                              color: isCurrent
                                  ? kPrimary
                                  : isPast
                                      ? kGreen
                                      : Colors.grey.shade300,
                              width:
                                  isCurrent ? 2.5 : 1.5,
                            ),
                          ),
                          child: isPast
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : ClipOval(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(3),
                                    child: _cartoonImg(
                                      cartoon,
                                      size:
                                          isCurrent ? 36 : 28,
                                    ),
                                  ),
                                ),
                        ),

                        if (i <
                            _stagesCartoon.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  i < _currentStageIndex
                                      ? kGreen
                                      : Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 8.5,
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
                  ],
                ),
              );
            },
          ),
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
    final color =
        isWarning ? kOrange : kGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanAgainButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              kPrimary,
              kPrimaryPink,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 18,
            ),

            SizedBox(width: 8),

            Text(
              'Scan Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

}