class FertilizerAdvice {
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
  });
}
