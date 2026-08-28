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
  final double? modelConfidence;
  final DateTime? createdAt;
  final String? treeId;

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
    this.modelConfidence,
    this.createdAt,
    this.treeId,
  });

  factory FertilizerAdvice.fromFirestore(String id, Map<String, dynamic> data) {
    final soil = data['soilData'] as Map<String, dynamic>? ?? {};
    final recommendation =
        data['recommendation'] as Map<String, dynamic>? ?? {};

    return FertilizerAdvice(
      id: id,
      fertilizerClass:
          (data['predictedLevel'] ?? data['fertilizerClass'])?.toString() ?? '',
      deficiencyScore: (data['deficiencyScore'] as num?)?.toDouble() ?? 0,
      treeAge: (data['treeAge'] as num?)?.toDouble() ?? 0,
      stage: (data['growthStage'] as num?)?.toInt() ?? 0,
      stageName: data['stageName']?.toString() ?? '',
      ureaG:
          (data['ureaG'] as num?)?.toDouble() ??
          (recommendation['ureaG'] as num?)?.toDouble() ??
          0,
      tspG:
          (data['tspG'] as num?)?.toDouble() ??
          (recommendation['tspG'] as num?)?.toDouble() ??
          0,
      mopG:
          (data['mopG'] as num?)?.toDouble() ??
          (recommendation['mopG'] as num?)?.toDouble() ??
          0,
      nitrogen:
          (data['nitrogen'] as num?)?.toDouble() ??
          (soil['nitrogen'] as num?)?.toDouble() ??
          0,
      phosphorus:
          (data['phosphorus'] as num?)?.toDouble() ??
          (soil['phosphorus'] as num?)?.toDouble() ??
          0,
      potassium:
          (data['potassium'] as num?)?.toDouble() ??
          (soil['potassium'] as num?)?.toDouble() ??
          0,
      moisture:
          (data['soilMoisture'] as num?)?.toDouble() ??
          (soil['moisture'] as num?)?.toDouble(),
      temp:
          (data['soilTemperature'] as num?)?.toDouble() ??
          (soil['temperature'] as num?)?.toDouble(),
      ph:
          (data['soilPh'] as num?)?.toDouble() ??
          (soil['ph'] as num?)?.toDouble(),
      modelConfidence: (data['modelConfidence'] as num?)?.toDouble(),
      createdAt: _parseTime(data['predictedAt'] ?? data['timestamp']),
      treeId: data['treeId']?.toString(),
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
