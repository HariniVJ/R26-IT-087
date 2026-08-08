class IrrigationLogic {
  static Map<String, dynamic> offlineDecision({
    required double soilMoisture,
  }) {
    if (soilMoisture <= 0 || soilMoisture > 100) {
      return {
        'success': false,
        'mode': 'offline',
        'final_prediction': 'INVALID_INPUT',
        'status': 'Cannot Predict',
        'reason': 'Invalid soil moisture reading. Please check the sensor.',
      };
    }

    if (soilMoisture >= 70) {
      return {
        'success': true,
        'mode': 'offline',
        'final_prediction': 'SKIP_SOIL_ALREADY_WET',
        'status': 'Not Suitable Now',
        'reason': 'Soil is already wet. Weather forecast is unavailable.',
      };
    }

    if (soilMoisture < 45) {
      return {
        'success': true,
        'mode': 'offline',
        'final_prediction': 'SUITABLE_BASED_ON_SOIL',
        'status': 'Suitable Based on Soil',
        'reason':
            'Soil moisture is low. Weather forecast is unavailable in offline mode.',
      };
    }

    return {
      'success': true,
      'mode': 'offline',
      'final_prediction': 'NO_URGENT_IRRIGATION',
      'status': 'No Urgent Irrigation Needed',
      'reason': 'Soil moisture is moderate. Weather forecast is unavailable.',
    };
  }
}