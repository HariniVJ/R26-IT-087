import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/growth/growth_advisory_service.dart';
import '../services/growth/growth_tflite_service.dart';
import 'result_screen.dart';

const Color kPrimary = Color(0xFFB22222);
const Color kPrimaryPink = Color(0xFFE14D75);
const Color kBg = Color(0xFFFFF5F7);
const Color kGray = Color(0xFF6B7280);
const Color kGreen = Color(0xFF2E7D32);
const Color kBlack = Color(0xFF111111);

class DetectingScreen extends StatefulWidget {
  final XFile xfile;

  const DetectingScreen({
    super.key,
    required this.xfile,
  });

  @override
  State<DetectingScreen> createState() =>
      _DetectingScreenState();
}

class _DetectingScreenState extends State<DetectingScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _ringAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  int _currentStep = 0;

  final List<String> _steps = [
    'Analyzing image...',
    'Detecting fruit region...',
    'Classifying growth stage...',
    'Calculating harvest time...',
    'Almost done...',
  ];

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _ringAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_ringController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    _runSteps();
    _startAnalysis();
  }

  Future<void> _runSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 950),
      );

      if (!mounted) return;

      setState(() {
        _currentStep = i;
      });
    }
  }

  Future<void> _startAnalysis() async {
    await Future.delayed(
      const Duration(seconds: 3),
    );

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'STARTING LOCAL TFLITE GROWTH ANALYSIS',
        );
        debugPrint(
          'Image: ${widget.xfile.name}',
        );
        debugPrint(
          'Path: ${widget.xfile.path}',
        );
        debugPrint(
          '==========================================',
        );
      }

      final File imageFile = File(
        widget.xfile.path,
      );

      final detection =
          await GrowthTfliteService.instance.analyse(
        imageFile,
      );

      if (kDebugMode) {
        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'TFLITE GROWTH RESULT',
        );

        debugPrint(
          'Detected: ${detection.detected}',
        );

        debugPrint(
          'YOLO score: '
          '${(detection.detectionScore * 100).toStringAsFixed(2)}%',
        );

        debugPrint(
          'Stage: ${detection.stage}',
        );

        debugPrint(
          'CNN confidence: '
          '${(detection.confidence * 100).toStringAsFixed(2)}%',
        );

        debugPrint(
          'CNN probabilities: '
          '${detection.allProbabilities}',
        );

        debugPrint(
          'Rejection reason: '
          '${detection.rejectionReason}',
        );

        debugPrint(
          '==========================================',
        );
        debugPrint('');
      }

      if (!mounted) return;

      if (!detection.detected ||
          detection.stage == null) {
        _showNotPomegranateDialog(
          tip: detection.rejectionReason ??
              'No pomegranate was detected. '
                  'Please select a clear image of a pomegranate.',
        );

        return;
      }

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Please login before performing growth analysis.',
        );
      }

      final String farmerId = user.uid;

      final String captureDate =
          DateTime.now()
              .toIso8601String()
              .split('T')
              .first;

      final Map<String, double> probabilities =
          detection.allProbabilities.map(
        (key, value) => MapEntry(
          key,
          value.toDouble(),
        ),
      );

      if (kDebugMode) {
        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'FARMER / SOIL SENSOR LOOKUP',
        );
        debugPrint(
          'Farmer ID: $farmerId',
        );
        debugPrint(
          '==========================================',
        );
        debugPrint('');
      }

      final Map<String, dynamic> resultData =
          await GrowthAdvisoryService.getAdvisory(
        predictedClass:
            detection.stage!,
        confidence:
            detection.confidence,
        allProbabilities:
            probabilities,
        captureDate:
            captureDate,
        lat:
            9.7,
        lon:
            80.0,
        farmerId:
            farmerId,
      );

      resultData['detection_score'] =
          detection.detectionScore * 100;

      if (kDebugMode) {
        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'BACKEND GROWTH ADVISORY',
        );

        debugPrint(
          'Stage: '
          '${resultData['growth_stage']?['detected']}',
        );

        debugPrint(
          'Next stage: '
          '${resultData['next_stage']}',
        );

        debugPrint(
          'Transition: '
          '${resultData['transition_prediction']?['range']}',
        );

        debugPrint(
          'Capture date: '
          '${resultData['transition_prediction']?['capture_date']}',
        );

        debugPrint(
          'Estimated start: '
          '${resultData['transition_prediction']?['estimated_start_date']}',
        );

        debugPrint(
          'Estimated end: '
          '${resultData['transition_prediction']?['estimated_end_date']}',
        );

        debugPrint(
          'Estimated date range: '
          '${resultData['transition_prediction']?['estimated_date_range']}',
        );

        debugPrint(
          'Weather available: '
          '${resultData['weather']?['available']}',
        );

        debugPrint(
          'Weather condition: '
          '${resultData['weather']?['condition']}',
        );

        debugPrint(
          'Air temperature: '
          '${resultData['weather']?['temperature_celsius']}',
        );

        debugPrint(
          'Humidity: '
          '${resultData['weather']?['humidity_percent']}',
        );

        debugPrint(
          'Soil available: '
          '${resultData['soil']?['available']}',
        );

        debugPrint(
          'Soil temperature: '
          '${resultData['soil']?['temperature_celsius']}',
        );

        debugPrint(
          'Soil timestamp: '
          '${resultData['soil']?['timestamp']}',
        );

        debugPrint(
          'Soil source: '
          '${resultData['soil']?['source']}',
        );

        debugPrint(
          'Environment level: '
          '${resultData['environment']?['level']}',
        );

        debugPrint(
          'Environment status: '
          '${resultData['environment']?['status']}',
        );

        debugPrint(
          '==========================================',
        );
        debugPrint('');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (
            _,
            __,
            ___,
          ) =>
              ResultScreen(
            xfile:
                widget.xfile,
            resultData:
                resultData,
          ),
          transitionsBuilder: (
            _,
            animation,
            __,
            child,
          ) {
            return FadeTransition(
              opacity:
                  animation,
              child:
                  child,
            );
          },
          transitionDuration:
              const Duration(
            milliseconds: 500,
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'GROWTH ANALYSIS ERROR',
        );
        debugPrint(
          '$e',
        );
        debugPrint(
          '$stackTrace',
        );
        debugPrint(
          '==========================================',
        );
        debugPrint('');
      }

      if (!mounted) return;

      _showError(
        'The growth analysis could not be completed.\n\n'
        '$e',
      );
    }
  }

  void _showNotPomegranateDialog({
    required String tip,
  }) {
    if (!mounted) return;

    showDialog(
      context:
          context,
      barrierDismissible:
          false,
      builder:
          (_) =>
              AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
        contentPadding:
            const EdgeInsets.all(
          24,
        ),
        content:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width:
                  72,
              height:
                  72,
              decoration:
                  const BoxDecoration(
                color:
                    Color(
                  0xFFFFEDD5,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .no_photography_rounded,
                color:
                    Color(
                  0xFFE76F51,
                ),
                size:
                    34,
              ),
            ),
            const SizedBox(
              height:
                  16,
            ),
            const Text(
              'Not a Pomegranate Image',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w800,
                color:
                    kBlack,
              ),
            ),
            const SizedBox(
              height:
                  10,
            ),
            Text(
              'The system could not detect a '
              'pomegranate fruit in this image.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    13,
                color:
                    Colors.grey[600],
                height:
                    1.5,
              ),
            ),
            if (tip.isNotEmpty) ...[
              const SizedBox(
                height:
                    8,
              ),
              Text(
                tip,
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize:
                      12,
                  color:
                      Colors.grey[500],
                  height:
                      1.4,
                ),
              ),
            ],
            const SizedBox(
              height:
                  16,
            ),
            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    kPrimary.withOpacity(
                  0.06,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      kPrimary.withOpacity(
                    0.2,
                  ),
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons
                            .lightbulb_outline_rounded,
                        color:
                            kPrimary,
                        size:
                            16,
                      ),
                      const SizedBox(
                        width:
                            6,
                      ),
                      Text(
                        'For best results:',
                        style:
                            TextStyle(
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height:
                        8,
                  ),
                  _tipRow(
                    'Take a clear photo of pomegranate fruit',
                  ),
                  _tipRow(
                    'Make sure the fruit is visible and well-lit',
                  ),
                  _tipRow(
                    'Avoid blurry or distant shots',
                  ),
                  _tipRow(
                    'Do not upload unrelated images',
                  ),
                ],
              ),
            ),
            const SizedBox(
              height:
                  20,
            ),
            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    () {
                  Navigator.pop(
                    context,
                  );
                  Navigator.pop(
                    context,
                  );
                },
                icon:
                    const Icon(
                  Icons
                      .camera_alt_rounded,
                  color:
                      Colors.white,
                  size:
                      18,
                ),
                label:
                    const Text(
                  'Try Another Image',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w700,
                    fontSize:
                        15,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      kPrimary,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical:
                        14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            4,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style:
                TextStyle(
              color:
                  kPrimary,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          Expanded(
            child:
                Text(
              text,
              style:
                  TextStyle(
                fontSize:
                    12,
                color:
                    Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    showDialog(
      context:
          context,
      builder:
          (_) =>
              AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        title:
            const Text(
          'Error',
        ),
        content:
            Text(
          message,
        ),
        actions: [
          TextButton(
            onPressed:
                () {
              Navigator.pop(
                context,
              );
              Navigator.pop(
                context,
              );
            },
            child:
                Text(
              'Go Back',
              style:
                  TextStyle(
                color:
                    kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildUploadedImage() {
    return FutureBuilder<Uint8List>(
      future:
          widget.xfile.readAsBytes(),
      builder:
          (
        context,
        snapshot,
      ) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit:
                BoxFit.cover,
            width:
                double.infinity,
            height:
                double.infinity,
          );
        }

        return Container(
          color:
              kBg,
          child:
              Icon(
            Icons.eco_rounded,
            color:
                kPrimary,
            size:
                60,
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,
      body:
          FadeTransition(
        opacity:
            _fadeAnim,
        child:
            SafeArea(
          child:
              Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      16,
                  vertical:
                      12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  border:
                      Border(
                    bottom:
                        BorderSide(
                      color:
                          Colors.grey.shade100,
                      width:
                          1,
                    ),
                  ),
                ),
                child:
                    Row(
                  children: [
                    GestureDetector(
                      onTap:
                          () =>
                              Navigator.pop(
                        context,
                      ),
                      child:
                          Container(
                        width:
                            38,
                        height:
                            38,
                        decoration:
                            BoxDecoration(
                          color:
                              kBg,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border:
                              Border.all(
                            color:
                                kPrimary.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        child:
                            Icon(
                          Icons
                              .arrow_back_ios_new_rounded,
                          size:
                              16,
                          color:
                              kPrimary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child:
                          Text(
                        'Detecting Image',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize:
                              16,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              kBlack,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width:
                          38,
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        20,
                    vertical:
                        16,
                  ),
                  child:
                      Column(
                    children: [
                      RichText(
                        textAlign:
                            TextAlign.center,
                        text:
                            const TextSpan(
                          style:
                              TextStyle(
                            fontSize:
                                26,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                kBlack,
                            height:
                                1.2,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Detecting\n',
                            ),
                            TextSpan(
                              text:
                                  'Pomegranate',
                              style:
                                  TextStyle(
                                color:
                                    kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height:
                            6,
                      ),
                      Text(
                        'Please wait while we analyze your image...',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize:
                              13,
                          color:
                              kGray,
                          height:
                              1.4,
                        ),
                      ),
                      const SizedBox(
                        height:
                            20,
                      ),
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            28,
                          ),
                          border:
                              Border.all(
                            color:
                                kPrimary.withOpacity(
                              0.15,
                            ),
                            width:
                                1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  kPrimary.withOpacity(
                                0.08,
                              ),
                              blurRadius:
                                  24,
                              spreadRadius:
                                  2,
                              offset:
                                  const Offset(
                                0,
                                6,
                              ),
                            ),
                          ],
                        ),
                        child:
                            Column(
                          children: [
                            ScaleTransition(
                              scale:
                                  _pulseAnim,
                              child:
                                  SizedBox(
                                width:
                                    220,
                                height:
                                    220,
                                child:
                                    Stack(
                                  alignment:
                                      Alignment.center,
                                  children: [
                                    Container(
                                      width:
                                          180,
                                      height:
                                          180,
                                      decoration:
                                          BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                kPrimary.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius:
                                                16,
                                            spreadRadius:
                                                2,
                                          ),
                                        ],
                                      ),
                                      child:
                                          ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),
                                        child:
                                            _buildUploadedImage(),
                                      ),
                                    ),
                                    RotationTransition(
                                      turns:
                                          _ringAnim,
                                      child:
                                          CustomPaint(
                                        size:
                                            const Size(
                                          220,
                                          220,
                                        ),
                                        painter:
                                            _GradientRingPainter(
                                          color1:
                                              kPrimary,
                                          color2:
                                              kPrimaryPink,
                                        ),
                                      ),
                                    ),
                                    ..._scanCorners(),
                                    Positioned(
                                      bottom:
                                          12,
                                      right:
                                          12,
                                      child:
                                          Container(
                                        width:
                                            36,
                                        height:
                                            36,
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors.white,
                                          shape:
                                              BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  kPrimary.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius:
                                                  8,
                                            ),
                                          ],
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .eco_rounded,
                                          color:
                                              kGreen,
                                          size:
                                              20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  16,
                            ),
                            AnimatedSwitcher(
                              duration:
                                  const Duration(
                                milliseconds:
                                    400,
                              ),
                              child:
                                  Text(
                                _steps[
                                    _currentStep.clamp(
                                  0,
                                  _steps.length -
                                      1,
                                )],
                                key:
                                    ValueKey(
                                  _currentStep,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize:
                                      15,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      kBlack,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  4,
                            ),
                            Text(
                              'Our AI is analyzing the fruit stage, growth\n'
                              'pattern and health...',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color:
                                    kGray,
                                height:
                                    1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height:
                            16,
                      ),
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                          border:
                              Border.all(
                            color:
                                kPrimary.withOpacity(
                              0.1,
                            ),
                            width:
                                1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(
                                0.04,
                              ),
                              blurRadius:
                                  12,
                              offset:
                                  const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .auto_awesome_rounded,
                                  color:
                                      kPrimary,
                                  size:
                                      16,
                                ),
                                const SizedBox(
                                  width:
                                      6,
                                ),
                                Text(
                                  'AI Processing Steps',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        kPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height:
                                  16,
                            ),
                            ...List.generate(
                              _steps.length,
                              (i) {
                                final isDone =
                                    i <
                                        _currentStep;

                                final isActive =
                                    i ==
                                        _currentStep;

                                return _StepItem(
                                  label:
                                      _steps[i],
                                  isDone:
                                      isDone,
                                  isActive:
                                      isActive,
                                  isLast:
                                      i ==
                                          _steps.length -
                                              1,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height:
                            16,
                      ),
                    ],
                  ),
                ),
              ),
              _BottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _scanCorners() {
    const double s =
        24;

    const double t =
        2.5;

    Widget corner(
      double top,
      double left,
      bool isTop,
      bool isLeft,
    ) {
      return Positioned(
        top:
            top,
        left:
            left,
        child:
            SizedBox(
          width:
              s,
          height:
              s,
          child:
              CustomPaint(
            painter:
                _CornerPainter(
              isTop:
                  isTop,
              isLeft:
                  isLeft,
              thickness:
                  t,
              color:
                  kPrimary,
            ),
          ),
        ),
      );
    }

    return [
      corner(
        20,
        20,
        true,
        true,
      ),
      corner(
        20,
        176,
        true,
        false,
      ),
      corner(
        176,
        20,
        false,
        true,
      ),
      corner(
        176,
        176,
        false,
        false,
      ),
    ];
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _StepItem({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    400,
              ),
              width:
                  26,
              height:
                  26,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    isDone
                        ? kGreen
                        : isActive
                            ? Colors.white
                            : Colors.grey.shade100,
                border:
                    Border.all(
                  color:
                      isDone
                          ? kGreen
                          : isActive
                              ? kPrimary
                              : Colors.grey.shade300,
                  width:
                      isActive
                          ? 2
                          : 1.5,
                ),
              ),
              child:
                  isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size:
                              14,
                          color:
                              Colors.white,
                        )
                      : isActive
                          ? SizedBox(
                              width:
                                  12,
                              height:
                                  12,
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets.all(
                                  5,
                                ),
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      kPrimary,
                                ),
                              ),
                            )
                          : null,
            ),
            if (!isLast)
              Container(
                width:
                    1.5,
                height:
                    24,
                color:
                    isDone
                        ? kGreen.withOpacity(
                            0.4,
                          )
                        : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(
          width:
              12,
        ),
        Padding(
          padding:
              const EdgeInsets.only(
            top:
                4,
            bottom:
                24,
          ),
          child:
              Text(
            label,
            style:
                TextStyle(
              fontSize:
                  13,
              color:
                  isDone
                      ? kGreen
                      : isActive
                          ? kBlack
                          : Colors.grey[400],
              fontWeight:
                  isDone ||
                          isActive
                      ? FontWeight.w600
                      : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientRingPainter
    extends CustomPainter {
  final Color color1;
  final Color color2;

  _GradientRingPainter({
    required this.color1,
    required this.color2,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final rect =
        Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final gradient =
        SweepGradient(
      colors: [
        color1,
        color2,
        color1.withOpacity(
          0.1,
        ),
      ],
      stops:
          const [
        0.0,
        0.5,
        1.0,
      ],
    );

    final paint =
        Paint()
          ..shader =
              gradient.createShader(
                rect,
              )
          ..strokeWidth =
              3.5
          ..style =
              PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round;

    canvas.drawArc(
      rect.deflate(
        2,
      ),
      -math.pi /
          2,
      math.pi *
          1.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}

class _CornerPainter
    extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color =
              color
          ..strokeWidth =
              thickness
          ..strokeCap =
              StrokeCap.round
          ..style =
              PaintingStyle.stroke;

    final x =
        isLeft
            ? 0.0
            : size.width;

    final y =
        isTop
            ? 0.0
            : size.height;

    canvas.drawLine(
      Offset(
        x,
        y,
      ),
      Offset(
        x +
            (isLeft
                    ? 1
                    : -1) *
                size.width *
                0.7,
        y,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        x,
        y,
      ),
      Offset(
        x,
        y +
            (isTop
                    ? 1
                    : -1) *
                size.height *
                0.7,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            const BorderRadius.vertical(
          top:
              Radius.circular(
            24,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.07,
            ),
            blurRadius:
                16,
            offset:
                const Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_rounded,
            'Home',
            false,
          ),
          _navItem(
            Icons.history_rounded,
            'History',
            false,
          ),
          Container(
            width:
                52,
            height:
                52,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              gradient:
                  const LinearGradient(
                colors: [
                  kPrimary,
                  kPrimaryPink,
                ],
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      kPrimary.withOpacity(
                    0.4,
                  ),
                  blurRadius:
                      14,
                  offset:
                      const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),
            child:
                const Icon(
              Icons
                  .document_scanner_rounded,
              color:
                  Colors.white,
              size:
                  24,
            ),
          ),
          _navItem(
            Icons.bar_chart_rounded,
            'Reports',
            false,
          ),
          _navItem(
            Icons.person_rounded,
            'Profile',
            false,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
  ) {
    final color =
        active
            ? kPrimary
            : Colors.grey[400]!;

    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          color:
              color,
          size:
              22,
        ),
        const SizedBox(
          height:
              3,
        ),
        Text(
          label,
          style:
              TextStyle(
            fontSize:
                10,
            color:
                color,
            fontWeight:
                active
                    ? FontWeight.w700
                    : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}