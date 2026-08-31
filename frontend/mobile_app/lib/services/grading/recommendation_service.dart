// lib/services/grading/recommendation_service.dart

/// Offline waste-utilization recommendation service.
///
/// Recommendations are embedded in the application, so they work without
/// Firestore or an internet connection.
///
/// Important:
/// Weight thresholds follow the supplied project dataset.
/// Export acceptance must still be confirmed through manual inspection,
/// because weight alone is not sufficient for export certification.
class RecommendationService {
  RecommendationService._();

  static final RecommendationService instance = RecommendationService._();

  static const double _maximumSeverity = 100.0;
  static const int _maximumWeight = 999999;

  static final List<Map<String, dynamic>> _rules = [
    // ==============================================================
    // HIGH QUALITY — WEIGHT-BASED RECOMMENDATIONS
    // ==============================================================
    {
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 250,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Export Grade A Candidate — International Fresh-Fruit Market',
      'explanation':
          'The fruit is classified as high quality, has no detected surface '
          'defect, and weighs 250 g or more. Based on the project dataset, '
          'it qualifies as an Export Grade A candidate.',
      'waste_usage':
          'No waste-utilization process is required because the fruit is '
          'suitable for fresh consumption. Grade, pack, label, and store it '
          'under suitable cool conditions for fresh-market distribution.',
      'safety_note':
          'Final export acceptance should also confirm fruit maturity, colour, '
          'shape, cleanliness, pest damage, residue limits, packaging, and the '
          'requirements of the destination market.',
    },

    {
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 150,
      'weight_max': 249,
      'recommended_usage':
          'Export Grade B Candidate or Premium Local Fresh Market',
      'explanation':
          'The fruit is classified as high quality and has no detected defect, '
          'but its weight is between 150 g and 249 g. Based on the dataset, '
          'it is suitable for Export Grade B consideration or premium local sale.',
      'waste_usage':
          'Use the fruit for fresh consumption rather than waste processing. '
          'It can be sorted, cleaned, packed, and sold through premium local '
          'markets. Export use requires confirmation of buyer specifications.',
      'safety_note':
          'Weight is only one grading factor. Export suitability must be '
          'confirmed through manual quality and phytosanitary inspection.',
    },

    {
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 1,
      'weight_max': 149,
      'recommended_usage':
          'Standard Local Fresh Market — Small High-Quality Fruit',
      'explanation':
          'The fruit is high quality and defect-free, but its weight is below '
          '150 g. It is below the project dataset’s export and premium weight '
          'ranges but remains suitable for fresh local consumption.',
      'waste_usage':
          'Sell as a smaller fresh-market fruit or combine it into value packs. '
          'If fresh-market demand is limited, the edible arils may be used for '
          'juice, ready-to-eat packs, syrup, or other food products.',
      'safety_note':
          'Inspect the fruit for hidden damage before sale or food processing.',
    },

    // ==============================================================
    // MEDIUM QUALITY
    // ==============================================================
    {
      'quality_level': 'medium_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 1,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Local Fresh Market',
      'explanation':
          'The fruit is classified as medium quality with minor cosmetic or '
          'appearance-related imperfections but no specific severe defect was '
          'identified. It is more suitable for local use than premium export.',
      'waste_usage':
          'After manual inspection and washing, acceptable fruits may be sold '
          'in the local market. Fruits with reduced visual appeal can be used '
          'for juice, pulp, concentrate, syrup, jam, aril packs, or other '
          'processed products when the edible portion remains sound.',
      'safety_note':
          'Cut and inspect suspicious fruit before food processing. Do not use '
          'fruit showing internal rot, mould, fermentation, or unpleasant odour.',
    },

    // ==============================================================
    // LOW QUALITY — ROT
    // ==============================================================
    {
      'quality_level': 'low_quality',
      'defect_type': 'rot',
      'severity_min': 0.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Composting or Controlled Organic-Fertilizer Production Only',
      'explanation':
          'Rot indicates active microbial decay and may extend beyond the '
          'visible damaged region. Therefore, the fruit is excluded from fresh '
          'sale, juice extraction, pulp processing, animal feed, and cosmetic '
          'or peel-based processing regardless of the measured severity.',
      'waste_usage':
          'Place the fruit in a controlled composting system with dry plant '
          'material to balance moisture. Maintain aeration and suitable '
          'composting temperature. Do not place heavily diseased or rotten '
          'material directly near healthy pomegranate plants.',
      'safety_note':
          'Zero tolerance is applied for food use. Wear gloves when handling '
          'mouldy fruit and clean tools and containers after disposal.',
    },

    // ==============================================================
    // LOW QUALITY — DISEASE
    // ==============================================================
    {
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 0.0,
      'severity_max': 9.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Manual Inspection Before Any Food or Waste-Utilization Decision',
      'explanation':
          'Disease symptoms affect less than 10% of the detected fruit area. '
          'The visible damage is limited, but image analysis cannot confirm '
          'whether the internal edible portion is safe.',
      'waste_usage':
          'Separate the fruit from healthy produce. An agricultural or food '
          'quality inspector should examine the affected and internal sections. '
          'Only confirmed healthy portions may be considered for immediate '
          'processing; otherwise, route the fruit to controlled composting.',
      'safety_note':
          'Do not recommend direct fresh consumption based only on the image result.',
    },

    {
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 10.0,
      'severity_max': 29.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Restricted Non-Food Peel Processing After Expert Inspection',
      'explanation':
          'Disease symptoms affect approximately 10–29% of the fruit surface. '
          'The fruit is not recommended for fresh sale or normal food processing '
          'because disease may extend beyond the visible region.',
      'waste_usage':
          'After expert inspection, unaffected peel sections may be separated '
          'for research-scale extraction of natural dye, tannin, pectin, or '
          'non-food cosmetic ingredients. Diseased sections must be discarded '
          'through controlled composting.',
      'safety_note':
          'Do not use diseased peel or edible arils. Industrial extraction must '
          'include contamination control and product-safety testing.',
    },

    {
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 30.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Controlled Composting or Organic-Fertilizer Production',
      'explanation':
          'Disease symptoms affect 30% or more of the fruit surface. The high '
          'affected area increases the possibility of internal damage and '
          'cross-contamination, making food and peel processing unsuitable.',
      'waste_usage':
          'Isolate the fruit from healthy produce and process it through a '
          'controlled composting system. Combine it with dry organic matter, '
          'maintain aeration, and allow sufficient decomposition before using '
          'the finished compost.',
      'safety_note':
          'Do not use the affected fruit for human consumption, animal feed, '
          'juice, pulp, peel powder, or cosmetic extraction.',
    },

    // ==============================================================
    // LOW QUALITY — CRACK
    // ==============================================================
    {
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 0.0,
      'severity_max': 14.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Immediate Juice Extraction from Inspected Healthy Arils',
      'explanation':
          'The crack affects less than 15% of the fruit surface. The fruit has '
          'reduced storage life, but clean and unaffected arils may still be '
          'suitable for immediate juice extraction after inspection.',
      'waste_usage':
          'Wash the fruit, remove the cracked rind and any exposed, discoloured, '
          'soft, mouldy, or contaminated tissue. Extract juice only from firm, '
          'normal-smelling arils and process it immediately under hygienic conditions.',
      'safety_note':
          'Do not use the fruit if the crack contains mould, insects, soil, '
          'fermentation, leakage, soft tissue, or an unpleasant odour.',
    },

    {
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 15.0,
      'severity_max': 39.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Immediate Pulp or Juice-Concentrate Processing After Inspection',
      'explanation':
          'The crack affects approximately 15–39% of the fruit surface. The '
          'larger opening creates a higher contamination risk and makes the '
          'fruit unsuitable for storage or normal fresh-market sale.',
      'waste_usage':
          'Process the fruit immediately in a controlled facility. Remove all '
          'exposed and damaged sections before using acceptable arils for '
          'pasteurised juice, pulp, concentrate, syrup, or similar products. '
          'Compost the rejected rind and damaged material.',
      'safety_note':
          'Food processing is allowed only after manual internal inspection. '
          'Reject the entire fruit if contamination or decay is present.',
    },

    {
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 40.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Controlled Composting Due to High Contamination Risk',
      'explanation':
          'The crack affects 40% or more of the surface. Extensive exposure '
          'creates a high risk of microbial contamination, moisture loss, '
          'insect entry, and internal deterioration.',
      'waste_usage':
          'Remove the fruit from the food-processing stream and place it in a '
          'controlled composting system. Mix with dry organic material and '
          'maintain suitable moisture, aeration, and decomposition time.',
      'safety_note':
          'Do not use for fresh consumption, juice, pulp, animal feed, or peel extraction.',
    },

    // ==============================================================
    // LOW QUALITY — SUNBURN
    // ==============================================================
    {
      'quality_level': 'low_quality',
      'defect_type': 'sunburn',
      'severity_min': 0.0,
      'severity_max': 9.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Peel Powder, Natural Dye, or Non-Food Pigment Extraction',
      'explanation':
          'Sunburn affects less than 10% of the fruit surface. The damage is '
          'mainly external and dry, so inspected unaffected peel may be suitable '
          'for non-food value-added processing.',
      'waste_usage':
          'Remove the burned section, wash the unaffected peel, dry it under '
          'controlled hygienic conditions, and process it into peel powder or '
          'extract natural pigments, tannins, and antioxidant compounds for '
          'approved non-food research or industrial applications.',
      'safety_note':
          'Confirm that there is no rot, mould, cracking, or internal heat damage '
          'before using any part of the fruit.',
    },

    {
      'quality_level': 'low_quality',
      'defect_type': 'sunburn',
      'severity_min': 10.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Non-Food Industrial Processing or Controlled Composting',
      'explanation':
          'Sunburn affects 10% or more of the fruit surface. The fruit has '
          'reduced fresh-market value and may have dry, hardened, or heat-damaged '
          'tissue that requires separation.',
      'waste_usage':
          'After inspection, unaffected peel may be considered for natural dye, '
          'tannin, pectin, bio-adsorbent, or cosmetic-ingredient research. If '
          'the damage is extensive or internal quality is uncertain, compost '
          'the entire fruit instead.',
      'safety_note':
          'This recommendation is for non-food utilization. Do not use damaged '
          'sections in edible products without professional safety assessment.',
    },
  ];

  Future<Map<String, dynamic>?> getRecommendation({
    required String quality,
    String? defectType,
    double? severityPercent,
    int? weightGrams,
  }) async {
    final normalizedQuality = _normalizeValue(quality);
    final normalizedDefect = _normalizeValue(defectType ?? 'no_defect');

    if (!_isSupportedQuality(normalizedQuality)) {
      return _manualInspectionResult(
        explanation:
            'The quality classification "$quality" is not recognised by the '
            'recommendation system.',
      );
    }

    // High-quality and medium-quality recommendations depend on weight.
    if (normalizedQuality == 'high_quality' ||
        normalizedQuality == 'medium_quality') {
      if (weightGrams == null || weightGrams <= 0) {
        return _manualInspectionResult(
          quality: normalizedQuality,
          explanation:
              'A valid fruit weight was not provided. Weight is required to '
              'select the correct fresh-market or export candidate category.',
          action:
              'Measure the whole fruit in grams and run the recommendation again.',
        );
      }

      for (final rule in _rules) {
        if (_matchesQualityAndWeight(
          rule: rule,
          quality: normalizedQuality,
          weight: weightGrams,
        )) {
          return Map<String, dynamic>.from(rule);
        }
      }

      return _manualInspectionResult(
        quality: normalizedQuality,
        explanation:
            'No weight-based recommendation rule matched the supplied fruit.',
      );
    }

    // Low-quality recommendations require both defect and severity.
    if (normalizedQuality == 'low_quality') {
      if (defectType == null || normalizedDefect == 'no_defect') {
        return _manualInspectionResult(
          quality: normalizedQuality,
          explanation:
              'The fruit is classified as low quality, but no valid defect type '
              'was detected. Automatically assuming rot would be unsafe.',
          action:
              'Inspect the fruit and confirm whether the defect is rot, disease, '
              'crack, or sunburn.',
        );
      }

      if (!_isSupportedDefect(normalizedDefect)) {
        return _manualInspectionResult(
          quality: normalizedQuality,
          explanation:
              'The detected defect "$defectType" does not have a configured '
              'waste-utilization rule.',
          action:
              'Send the fruit for manual inspection before sale, processing, or disposal.',
        );
      }

      if (severityPercent == null ||
          severityPercent.isNaN ||
          severityPercent.isInfinite) {
        return _manualInspectionResult(
          quality: normalizedQuality,
          defect: normalizedDefect,
          explanation:
              'A reliable severity percentage is unavailable, so a safe '
              'automatic waste-utilization decision cannot be made.',
          action: 'Repeat the image analysis or inspect the fruit manually.',
        );
      }

      final severity = severityPercent.clamp(0.0, _maximumSeverity);

      for (final rule in _rules) {
        if (_matchesLowQualityRule(
          rule: rule,
          quality: normalizedQuality,
          defect: normalizedDefect,
          severity: severity,
        )) {
          final result = Map<String, dynamic>.from(rule);
          result['measured_severity'] = double.parse(
            severity.toStringAsFixed(2),
          );
          result['measured_weight'] = weightGrams;
          return result;
        }
      }
    }

    return _manualInspectionResult(
      quality: normalizedQuality,
      defect: normalizedDefect,
      explanation:
          'No recommendation rule matched the supplied grading result.',
    );
  }

  bool _matchesQualityAndWeight({
    required Map<String, dynamic> rule,
    required String quality,
    required int weight,
  }) {
    final minimumWeight = (rule['weight_min'] as num).toInt();
    final maximumWeight = (rule['weight_max'] as num).toInt();

    return rule['quality_level'] == quality &&
        rule['defect_type'] == 'no_defect' &&
        weight >= minimumWeight &&
        weight <= maximumWeight;
  }

  bool _matchesLowQualityRule({
    required Map<String, dynamic> rule,
    required String quality,
    required String defect,
    required double severity,
  }) {
    final minimumSeverity = (rule['severity_min'] as num).toDouble();
    final maximumSeverity = (rule['severity_max'] as num).toDouble();

    return rule['quality_level'] == quality &&
        rule['defect_type'] == defect &&
        severity >= minimumSeverity &&
        severity <= maximumSeverity;
  }

  bool _isSupportedQuality(String quality) {
    return quality == 'high_quality' ||
        quality == 'medium_quality' ||
        quality == 'low_quality';
  }

  bool _isSupportedDefect(String defect) {
    return defect == 'rot' ||
        defect == 'disease' ||
        defect == 'crack' ||
        defect == 'sunburn';
  }

  String _normalizeValue(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Map<String, dynamic> _manualInspectionResult({
    String? quality,
    String? defect,
    required String explanation,
    String action =
        'Keep the fruit separate and obtain a manual quality and safety assessment.',
  }) {
    return {
      'quality_level': quality ?? 'unknown',
      'defect_type': defect ?? 'unknown',
      'severity_min': 0.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Manual Inspection Required Before Utilization',
      'explanation': explanation,
      'waste_usage': action,
      'safety_note':
          'Do not use the fruit for fresh consumption, food processing, '
          'animal feed, or industrial extraction until it has been assessed.',
    };
  }
}
