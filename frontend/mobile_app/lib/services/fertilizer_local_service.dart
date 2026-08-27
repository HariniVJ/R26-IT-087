import '../models/fertilizer_advice.dart';

/// On-device fertilizer rules copied from
/// `backend/app/services/fertilizer_service.py`.
/// EC is not used by the remaining fertilizer logic.
class FertilizerLocalService {
  FertilizerAdvice predict({
    required double moisture,
    required double temp,
    required double ph,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double treeAge,
  }) {
    if (treeAge <= 0) {
      throw ArgumentError('Please enter a valid tree age.');
    }

    final stage = _treeStage(treeAge);
    final classified = _classify(nitrogen, phosphorus, potassium);
    final amount = _amount(stage, classified.$1);

    return FertilizerAdvice(
      fertilizerClass: classified.$1,
      deficiencyScore: double.parse(classified.$2.toStringAsFixed(2)),
      treeAge: treeAge,
      stage: stage,
      stageName: _stageName(stage),
      ureaG: amount.$1,
      tspG: amount.$2,
      mopG: amount.$3,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      moisture: moisture,
      temp: temp,
      ph: ph,
      createdAt: DateTime.now().toUtc(),
    );
  }

  int _treeStage(double age) {
    if (age <= 1) return 1;
    if (age <= 2) return 2;
    if (age <= 3) return 3;
    return 4;
  }

  String _stageName(int stage) {
    switch (stage) {
      case 1:
        return 'first_year';
      case 2:
        return 'second_year';
      case 3:
        return 'third_year';
      default:
        return 'fourth_year_onwards';
    }
  }

  (String, double) _classify(double nitrogen, double phosphorus, double potassium) {
    const optimalN = 70.0;
    const optimalP = 50.0;
    const optimalK = 225.0;

    final nDeficiency = (optimalN - nitrogen).clamp(0, double.infinity);
    final pDeficiency = (optimalP - phosphorus).clamp(0, double.infinity);
    final kDeficiency = (optimalK - potassium).clamp(0, double.infinity);

    final score =
        0.50 * nDeficiency + 0.25 * pDeficiency + 0.25 * kDeficiency;

    final fertilizerClass = score > 40
        ? 'HIGH'
        : score >= 20
            ? 'MEDIUM'
            : 'LOW';

    return (fertilizerClass, score);
  }

  (double, double, double) _amount(int stage, String fertilizerClass) {
    const baseTable = {
      1: (40.0, 45.0, 40.0),
      2: (60.0, 70.0, 55.0),
      3: (150.0, 185.0, 125.0),
      4: (200.0, 275.0, 175.0),
    };
    const multiplier = {
      'LOW': 0.75,
      'MEDIUM': 1.00,
      'HIGH': 1.25,
    };

    final base = baseTable[stage]!;
    final factor = multiplier[fertilizerClass.toUpperCase()] ?? 1.0;
    return (
      double.parse((base.$1 * factor).toStringAsFixed(2)),
      double.parse((base.$2 * factor).toStringAsFixed(2)),
      double.parse((base.$3 * factor).toStringAsFixed(2)),
    );
  }
}
