class GrowthResult {
  final String stage;              
  final double confidence;         
  final double detectionScore;     
  final String? nextStage;
  final int daysToNextStage;
  final int daysToHarvest;
  final String careTip;
  final String riskWarning;
  final double? temperature;
  final String? weatherCondition;
  final DateTime createdAt;

  const GrowthResult({
    required this.stage,
    required this.confidence,
    required this.detectionScore,
    required this.nextStage,
    required this.daysToNextStage,
    required this.daysToHarvest,
    required this.careTip,
    required this.riskWarning,
    this.temperature,
    this.weatherCondition,
    required this.createdAt,
  });

  String get displayName => _stageInfo[stage]?['display'] ?? stage;

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'confidence': confidence,
        'detectionScore': detectionScore,
        'nextStage': nextStage,
        'daysToNextStage': daysToNextStage,
        'daysToHarvest': daysToHarvest,
        'careTip': careTip,
        'riskWarning': riskWarning,
        'temperature': temperature,
        'weatherCondition': weatherCondition,
        'createdAt': createdAt.toUtc(),
      };

  factory GrowthResult.fromJson(Map<String, dynamic> j) => GrowthResult(
        stage: j['stage'] ?? 'Unknown',
        confidence: (j['confidence'] ?? 0).toDouble(),
        detectionScore: (j['detectionScore'] ?? 0).toDouble(),
        nextStage: j['nextStage'],
        daysToNextStage: j['daysToNextStage'] ?? 0,
        daysToHarvest: j['daysToHarvest'] ?? 0,
        careTip: j['careTip'] ?? '',
        riskWarning: j['riskWarning'] ?? '',
        temperature: j['temperature']?.toDouble(),
        weatherCondition: j['weatherCondition'],
        createdAt: j['createdAt'] is DateTime
            ? j['createdAt']
            : DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      );

  // ── Build a result from a detected stage plus optional weather ──
  static GrowthResult fromStage(
    String stage,
    double confidence,
    double detectionScore, {
    double? temperature,
    bool isRainy = false,
  }) {
    final info = _stageInfo[stage] ?? _stageInfo['MidGrowth']!;

    final baseHarvest = info['harvestDays'] as int;
    final adjusted = _adjustForWeather(baseHarvest, temperature, isRainy);

    return GrowthResult(
      stage: stage,
      confidence: confidence,
      detectionScore: detectionScore,
      nextStage: info['next'] as String?,
      daysToNextStage: info['transitionDays'] as int,
      daysToHarvest: adjusted,
      careTip: info['careTip'] as String,
      riskWarning: info['riskWarning'] as String,
      temperature: temperature,
      weatherCondition: temperature == null
          ? null
          : (isRainy ? 'Rainy' : 'Clear/Dry'),
      createdAt: DateTime.now(),
    );
  }

  // Rainy weather slows ripening, heat speeds it up, cold slows it.
  static int _adjustForWeather(int base, double? temp, bool isRainy) {
    if (temp == null) return base;
    var adj = 0;
    if (isRainy) adj += 7;
    if (temp > 30) {
      adj -= 5;
    } else if (temp < 20) {
      adj += 10;
    }
    final result = base + adj;
    return result < 0 ? 0 : result;
  }
}

const Map<String, Map<String, dynamic>> _stageInfo = {
  'Bud': {
    'display': 'Bud Stage',
    'next': 'Flower',
    'transitionDays': 30,
    'harvestDays': 165,
    'careTip':
        'Ensure adequate irrigation. Apply balanced NPK fertilizer. '
        'Check for aphids and mites which attack young buds.',
    'riskWarning':
        'Frost or extreme heat can damage buds. '
        'Avoid over-watering to prevent root rot.',
  },
  'Flower': {
    'display': 'Flower Stage',
    'next': 'EarlyFruit',
    'transitionDays': 14,
    'harvestDays': 135,
    'careTip':
        'Reduce irrigation slightly during flowering. '
        'Avoid pesticides that harm pollinators. '
        'Hand-pollination can improve fruit set.',
    'riskWarning':
        'Heavy rain or wind can cause flower drop. '
        'Watch for fungal disease in humid conditions.',
  },
  'EarlyFruit': {
    'display': 'Early Fruit Stage',
    'next': 'MidGrowth',
    'transitionDays': 21,
    'harvestDays': 105,
    'careTip':
        'Increase potassium fertilizer to support fruit development. '
        'Thin excess fruitlets to improve size. '
        'Maintain consistent soil moisture.',
    'riskWarning':
        'Fruit cracking risk increases with irregular watering. '
        'Watch for pomegranate butterfly larva.',
  },
  'MidGrowth': {
    'display': 'Mid Growth Stage',
    'next': 'MatureFruit',
    'transitionDays': 30,
    'harvestDays': 67,
    'careTip':
        'Continue potassium and calcium fertilization. '
        'Maintain regular irrigation schedule. '
        'Remove damaged or diseased fruits promptly.',
    'riskWarning':
        'Cercospora fruit spot and bacterial blight may appear. '
        'High humidity increases disease risk.',
  },
  'MatureFruit': {
    'display': 'Mature Fruit',
    'next': null,
    'transitionDays': 0,
    'harvestDays': 7,
    'careTip':
        'Reduce irrigation 1-2 weeks before harvest to improve sugar content. '
        'Check fruit by tapping - a metallic sound means it is ready. '
        'Harvest with pruning shears, leaving a short stem.',
    'riskWarning':
        'Delay causes over-ripening and fruit drop. '
        'Birds and insects may damage mature fruits - use netting.',
  },
};
