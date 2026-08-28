// lib/services/grading/recommendation_service.dart

/// Waste-utilization recommendation rules — embedded directly in code.
/// No Firestore dependency for lookups, so recommendations always work
/// regardless of network state or collection-seeding status.
class RecommendationService {
  RecommendationService._();
  static final RecommendationService instance = RecommendationService._();

  static final List<Map<String, dynamic>> _rules = [
    {
      "quality_level": "high_quality",
      "defect_type": "no_defect",
      "severity_min": 0,
      "severity_max": 0,
      "weight_min": 250,
      "weight_max": 999999,
      "recommended_usage": "Export Grade A (International Market)",
      "explanation":
          "High quality, no visible defects, 250g or above — meets the export weight threshold.",
    },
    {
      "quality_level": "high_quality",
      "defect_type": "no_defect",
      "severity_min": 0,
      "severity_max": 0,
      "weight_min": 150,
      "weight_max": 249,
      "recommended_usage": "Local Fresh Market (Premium Grade)",
      "explanation":
          "High quality, no defects, but below the export weight threshold — routed to premium local sale.",
    },
    {
      "quality_level": "high_quality",
      "defect_type": "no_defect",
      "severity_min": 0,
      "severity_max": 0,
      "weight_min": 0,
      "weight_max": 149,
      "recommended_usage": "Local Fresh Market (Standard Grade)",
      "explanation":
          "High quality, no defects, but too small for export or premium pricing — safe for direct sale.",
    },
    {
      "quality_level": "medium_quality",
      "defect_type": "no_defect",
      "severity_min": 0,
      "severity_max": 0,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Local Market Sale / Food Processing",
      "explanation":
          "Minor cosmetic imperfections, no internal damage — suitable for local sale or processing.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "rot",
      "severity_min": 0,
      "severity_max": 100,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Composting / Organic Fertilizer Production",
      "explanation":
          "Rot indicates active decay that can spread internally — excluded from food/industrial use regardless of severity.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "disease",
      "severity_min": 0,
      "severity_max": 9,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Manual Inspection Required Before Processing",
      "explanation":
          "Disease damage under 10% — requires manual inspection before assigning a final usage.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "disease",
      "severity_min": 10,
      "severity_max": 29,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage":
          "Non-Food Industrial Processing (Peel-Based Extraction)",
      "explanation":
          "Disease damage 10-29% — unaffected peel usable for dye/cosmetic extraction after removing diseased sections.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "disease",
      "severity_min": 30,
      "severity_max": 100,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Composting / Organic Fertilizer Production",
      "explanation":
          "Disease damage 30% or more — significant internal spread, routed to composting.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "crack",
      "severity_min": 0,
      "severity_max": 14,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Fresh Juice Extraction",
      "explanation":
          "Small crack under 15% — processed promptly into fresh juice using unaffected arils.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "crack",
      "severity_min": 15,
      "severity_max": 39,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Immediate Pulp Processing for Juice Concentrate",
      "explanation":
          "Larger crack 15-39% — must be processed immediately before spoilage.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "crack",
      "severity_min": 40,
      "severity_max": 100,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Composting / Organic Fertilizer Production",
      "explanation":
          "Crack 40% or more — high contamination risk, unsafe for food processing.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "sunburn",
      "severity_min": 0,
      "severity_max": 9,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Peel Powder and Natural Dye Extraction",
      "explanation":
          "Minor sunburn under 10% — dry, cosmetic-only, well-suited for pigment extraction.",
    },
    {
      "quality_level": "low_quality",
      "defect_type": "sunburn",
      "severity_min": 10,
      "severity_max": 100,
      "weight_min": 0,
      "weight_max": 999999,
      "recommended_usage": "Non-Food Industrial Processing (Cosmetic/Dye Use)",
      "explanation":
          "Sunburn 10% or more — routed to general non-food industrial/dye processing.",
    },
  ];

  Future<Map<String, dynamic>?> getRecommendation({
    required String quality,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    if (quality == 'high_quality' || quality == 'medium_quality') {
      final weight = weightGrams ?? 0;
      for (final rule in _rules) {
        if (rule['quality_level'] == quality &&
            weight >= (rule['weight_min'] as num) &&
            weight <= (rule['weight_max'] as num)) {
          return rule;
        }
      }
    } else {
      final severity = severityPercent ?? 0;
      final defect = defectType ?? 'rot';
      for (final rule in _rules) {
        if (rule['quality_level'] == quality &&
            rule['defect_type'] == defect &&
            severity >= (rule['severity_min'] as num) &&
            severity <= (rule['severity_max'] as num)) {
          return rule;
        }
      }
    }
    return null;
  }
}
