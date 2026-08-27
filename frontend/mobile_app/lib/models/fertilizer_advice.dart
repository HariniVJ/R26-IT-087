class FertilizerAdvice {
  final String? id;
  final String fertilizerClass;
  final double deficiencyScore;
  final double treeAge;
  final int stage;
  final String stageName;
  final double ureaG;
  final double tspG;
  final double mopG;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double? moisture;
  final double? temp;
  final double? ph;
  final DateTime? createdAt;

  const FertilizerAdvice({
    required this.fertilizerClass,
    required this.deficiencyScore,
    required this.treeAge,
    required this.stage,
    required this.stageName,
    required this.ureaG,
    required this.tspG,
    required this.mopG,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    this.id,
    this.moisture,
    this.temp,
    this.ph,
    this.createdAt,
  });

  factory FertilizerAdvice.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final soil = data['soilData'] as Map<String, dynamic>? ?? {};
    final recommendation =
        data['recommendation'] as Map<String, dynamic>? ?? {};

    return FertilizerAdvice(
      id: id,
      fertilizerClass: data['fertilizerClass']?.toString() ?? '',
      deficiencyScore: (data['deficiencyScore'] as num?)?.toDouble() ?? 0,
      treeAge: (data['treeAge'] as num?)?.toDouble() ?? 0,
      stage: (data['growthStage'] as num?)?.toInt() ?? 0,
      stageName: data['stageName']?.toString() ?? '',
      ureaG: (recommendation['ureaG'] as num?)?.toDouble() ?? 0,
      tspG: (recommendation['tspG'] as num?)?.toDouble() ?? 0,
      mopG: (recommendation['mopG'] as num?)?.toDouble() ?? 0,
      nitrogen: (soil['nitrogen'] as num?)?.toDouble() ?? 0,
      phosphorus: (soil['phosphorus'] as num?)?.toDouble() ?? 0,
      potassium: (soil['potassium'] as num?)?.toDouble() ?? 0,
      moisture: (soil['moisture'] as num?)?.toDouble(),
      temp: (soil['temperature'] as num?)?.toDouble(),
      ph: (soil['ph'] as num?)?.toDouble(),
      createdAt: _parseTime(data['timestamp']),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value.toString());
    }
  }
}
