class FarmTree {
  final String id;
  final String farmId;
  final String farmerId;
  final double treeAge;
  final double? trunkWidth;
  final DateTime? plantingDate;
  final String growthStage;

  const FarmTree({
    required this.id,
    required this.farmId,
    required this.farmerId,
    required this.treeAge,
    this.trunkWidth,
    this.plantingDate,
    this.growthStage = '',
  });

  factory FarmTree.fromFirestore(String id, Map<String, dynamic> data) {
    return FarmTree(
      id: id,
      farmId: data['farmId']?.toString() ?? '',
      farmerId: data['farmerId']?.toString() ?? '',
      treeAge: (data['treeAge'] as num?)?.toDouble() ?? 0,
      trunkWidth: (data['trunkWidth'] as num?)?.toDouble(),
      plantingDate: _parseTime(data['plantingDate']),
      growthStage: data['growthStage']?.toString() ?? '',
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
