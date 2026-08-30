import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GrowthHistoryService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<String?> saveGrowthHistory(
    Map<String, dynamic> resultData,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final Map<String, dynamic> growthStage =
        Map<String, dynamic>.from(
      resultData['growth_stage'] ?? {},
    );

    final Map<String, dynamic> transition =
        Map<String, dynamic>.from(
      resultData['transition_prediction'] ?? {},
    );

    final Map<String, dynamic> harvest =
        Map<String, dynamic>.from(
      resultData['harvest_prediction'] ?? {},
    );

    final Map<String, dynamic> weather =
        Map<String, dynamic>.from(
      resultData['weather'] ?? {},
    );

    final Map<String, dynamic> soil =
        Map<String, dynamic>.from(
      resultData['soil'] ?? {},
    );

    final Map<String, dynamic> environment =
        Map<String, dynamic>.from(
      resultData['environment'] ?? {},
    );

    final Map<String, dynamic> recommendations =
        Map<String, dynamic>.from(
      resultData['recommendations'] ?? {},
    );

    final document = await _firestore
        .collection('growth_history')
        .add({
      'farmerId': user.uid,

      'growthStage':
          growthStage['detected'],

      'displayName':
          growthStage['display_name'],

      'confidencePercent':
          growthStage['confidence_percent'],

      'nextStage':
          resultData['next_stage'],

      'captureDate':
          transition['capture_date'],

      'transitionMinDays':
          transition['min_days'],

      'transitionMaxDays':
          transition['max_days'],

      'transitionRange':
          transition['range'],

      'estimatedStartDate':
          transition['estimated_start_date'],

      'estimatedEndDate':
          transition['estimated_end_date'],

      'estimatedDateRange':
          transition['estimated_date_range'],

      'remainingToMature':
          harvest['range'],

      'soilAvailable':
          soil['available'] ?? false,

      'soilTemperature':
          soil['temperature_celsius'],

      'soilReadingTimestamp':
          soil['timestamp'],

      'soilSource':
          soil['source'],

      'weatherAvailable':
          weather['available'] ?? false,

      'weatherTemperature':
          weather['temperature_celsius'],

      'humidity':
          weather['humidity_percent'],

      'precipitation':
          weather['precipitation_mm'],

      'weatherCondition':
          weather['condition'],

      'environmentLevel':
          environment['level'],

      'environmentStatus':
          environment['status'],

      'environmentReason':
          environment['reason'],

      'environmentMessage':
          environment['farmer_message'],

      'careTip':
          recommendations['care_tip'],

      'careAction':
          recommendations['care_action'],

      'riskWarning':
          recommendations['risk_warning'],

      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getGrowthHistory() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('growth_history')
        .where(
          'farmerId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }
}