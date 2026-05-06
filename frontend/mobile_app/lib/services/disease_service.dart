import 'dart:io';
import '../models/prediction_result_model.dart';

class DiseaseService {
  // ── Mock results list ───────────────────────────────────────
  static final List<Map<String, dynamic>> _mockData = [
    {
      'name': 'Anthracnose',
      'confidence': 92.5,
      'treatment':
          'Remove infected fruits immediately.\nAvoid overhead watering.\nApply Mancozeb or Carbendazim fungicide.\nKeep good air circulation around plants.\nRepeat spray every 10–14 days.',
    },
    {
      'name': 'Bacterial Blight',
      'confidence': 88.3,
      'treatment':
          'Remove and destroy all infected fruits.\nApply copper-based bactericide spray.\nAvoid working in wet field conditions.\nMaintain proper farm hygiene.\nPrune overcrowded branches.',
    },
    {
      'name': 'Cercospora',
      'confidence': 94.1,
      'treatment':
          'Spray Carbendazim 0.1% solution.\nRemove infected leaves and fruits.\nAvoid overhead irrigation.\nApply spray every 15 days during rainy season.\nImprove farm drainage.',
    },
    {
      'name': 'Alternaria',
      'confidence': 85.7,
      'treatment':
          'Apply Iprodione fungicide.\nStore harvested fruits in cool dry place.\nApply hot water treatment at 48°C for 10 min.\nRemove fallen infected fruits from farm.\nEnsure proper ventilation.',
    },
    {
      'name': 'Healthy',
      'confidence': 98.2,
      'treatment':
          'No treatment needed.\nContinue regular monitoring.\nMaintain proper watering schedule.\nKeep farm clean and well-drained.\nMonitor weekly for early disease signs.',
    },
  ];

  // ── Predict (Mock) ──────────────────────────────────────────
  static Future<PredictionResultModel> predictDisease(File imageFile) async {
    await Future.delayed(const Duration(seconds: 2));

    final pick = _mockData[DateTime.now().second % _mockData.length];

    return PredictionResultModel(
      diseaseName: pick['name'],
      confidence: pick['confidence'],
      treatment: pick['treatment'],
      imagePath: imageFile.path,
      detectedAt: DateTime.now(),
    );
  }
}
