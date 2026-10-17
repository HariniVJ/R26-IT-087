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
    // R01–R03  HIGH QUALITY — WEIGHT-BASED RECOMMENDATIONS
    // ==============================================================
    {
      'rule_id': 'R01',
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 200,
      'weight_max': 300,
      'recommended_usage': 'Export Grade A – International Fresh Fruit Market',
      'explanation':
          'The fruit is classified as high quality, no surface defect was '
          'detected, and it weighs between 200 g and 300 g. This is the '
          "project's Export Grade A weight range, so the fruit is a candidate "
          'for the international fresh-fruit market.',
      'waste_usage':
          'No waste-utilization process is needed because the fruit is '
          'suitable for fresh consumption. Clean, grade, pack in export '
          'cartons, label, and keep in cool storage (about 5–7 °C) until '
          'dispatch to the international fresh-fruit market.',
      'safety_note':
          'Final export acceptance must also confirm maturity, colour, shape, '
          'cleanliness, pest damage, pesticide-residue limits, packaging, '
          "phytosanitary certification, and the destination market's "
          'requirements.',
    },

    {
      'rule_id': 'R02',
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 180,
      'weight_max': 199,
      'recommended_usage': 'Export Grade B – International Fresh Fruit Market',
      'explanation':
          'The fruit is high quality and defect-free, and it weighs between '
          '180 g and 199 g. It is slightly below the Grade A weight range, so '
          'it is classified as an Export Grade B candidate for the '
          'international fresh-fruit market.',
      'waste_usage':
          'Use the fruit for fresh consumption, not waste processing. Clean, '
          "grade, and pack it as Export Grade B. If the buyer's minimum weight "
          'is not met, sell it through premium local fresh markets instead.',
      'safety_note':
          'Weight is only one grading factor. Confirm buyer specifications, '
          'phytosanitary requirements, and residue limits through manual '
          'inspection before export.',
    },

    {
      'rule_id': 'R03',
      'quality_level': 'high_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 1,
      'weight_max': 179,
      'recommended_usage': 'Standard Local Fresh Market',
      'explanation':
          'The fruit is high quality and defect-free, but it weighs less than '
          '180 g, which is below the export weight ranges. It remains fully '
          'suitable for fresh local consumption.',
      'waste_usage':
          'Sell through standard local fresh markets, supermarkets, or as '
          'value packs of smaller fruit. If fresh demand is low, the arils can '
          'be used for ready-to-eat aril packs, fresh juice, or syrup.',
      'safety_note':
          'Check the fruit for hidden damage, soft spots, or insect holes '
          'before sale.',
    },

    // ==============================================================
    // R04–R05  MEDIUM QUALITY — WEIGHT-BASED RECOMMENDATIONS
    // ==============================================================
    {
      'rule_id': 'R04',
      'quality_level': 'medium_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 200,
      'weight_max': 300,
      'recommended_usage': 'Local Fresh Market',
      'explanation':
          'The fruit is medium quality with minor cosmetic imperfections '
          '(colour, shape, or small surface marks) and weighs between 200 g '
          'and 300 g. It is not suitable for export but is good for local '
          'fresh sale.',
      'waste_usage':
          'Wash, sort, and sell the fruit in local fresh markets or retail '
          'shops. Fruit with lower visual appeal can also be used for fresh '
          'juice, aril packs, jam, or syrup when the edible part is sound.',
      'safety_note':
          'Inspect each fruit by hand before sale. Do not sell fruit with soft '
          'areas, mould, fermentation, or an unpleasant odour.',
    },

    {
      'rule_id': 'R05',
      'quality_level': 'medium_quality',
      'defect_type': 'no_defect',
      'severity_min': 0.0,
      'severity_max': 0.0,
      'weight_min': 1,
      'weight_max': 199,
      'recommended_usage': 'Farm-Gate Sale – Direct to Local Customers',
      'explanation':
          'The fruit is medium quality and weighs less than 200 g. Its size '
          'and appearance make it less suitable for market sale, but it is '
          'still good to eat, so it can be sold directly by the farmer.',
      'waste_usage':
          'Sell directly at the farm gate, roadside stalls, or to neighbours '
          'and local customers at a lower price. Unsold fruit can be used at '
          'home or sold to small juice shops for fresh juice.',
      'safety_note':
          'Inspect the fruit before sale and remove any fruit with cracks, '
          'soft spots, mould, or a bad smell.',
    },

    // ==============================================================
    // R06  LOW QUALITY — ROT
    // ==============================================================
    {
      'rule_id': 'R06',
      'quality_level': 'low_quality',
      'defect_type': 'rot',
      'severity_min': 0.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Composting – Organic Fertilizer (Manure) for the Field',
      'explanation':
          'Rot means active microbial decay that can spread beyond the visible '
          'area. The fruit is therefore not safe for fresh sale, juice, pulp, '
          'animal feed, or peel processing at any rot level.',
      'waste_usage':
          'Put the fruit in a compost pit or bin with dry plant material '
          '(leaves, straw) to balance moisture. Turn the pile regularly for '
          'aeration. After full decomposition (about 2–3 months), use the '
          'compost as organic manure/fertilizer in the field.',
      'safety_note':
          'Zero tolerance for food use. Wear gloves when handling rotten fruit, '
          'keep the compost away from healthy pomegranate plants, and clean '
          'tools and containers after use.',
    },

    // ==============================================================
    // R07–R09  LOW QUALITY — DISEASE
    // ==============================================================
    {
      'rule_id': 'R07',
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 0.0,
      'severity_max': 4.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage':
          'Healthy Aril Extraction for Immediate Juice or Aril Packs After '
          'Inspection',
      'explanation':
          'Disease symptoms cover less than 5% of the fruit surface. Many '
          'pomegranate diseases at this early stage affect only the outer '
          'peel, so the internal arils (seeds) may still be healthy and usable.',
      'waste_usage':
          'Separate the fruit from healthy produce. Cut it open and check the '
          'inside. If the arils are firm, bright, and normal-smelling, remove '
          'them and use them immediately for fresh juice or ready-to-eat aril '
          'packs. Discard the diseased peel by composting.',
      'safety_note':
          'Use the arils only if no internal browning, rot, mould, or bad '
          'odour is found. If any internal damage is seen, compost the whole '
          'fruit. Do not sell the whole fruit as fresh fruit.',
    },

    {
      'rule_id': 'R08',
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 5.0,
      'severity_max': 39.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Manual Inspection Before Any Usage Decision',
      'explanation':
          'Disease symptoms cover about 5–39% of the fruit surface. At this '
          'level the disease may have reached the inside of the fruit, and '
          'image analysis alone cannot confirm whether the edible part is safe.',
      'waste_usage':
          'Separate the fruit from healthy produce. An agricultural officer or '
          'experienced farmer should cut and inspect it. If the inside is '
          'healthy, the arils may be used immediately for juice. If not, send '
          'the fruit for controlled composting.',
      'safety_note':
          'Do not use the fruit for fresh sale or food until it has been '
          'inspected. Do not use diseased peel for peel powder or dye.',
    },

    {
      'rule_id': 'R09',
      'quality_level': 'low_quality',
      'defect_type': 'disease',
      'severity_min': 40.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Composting or Safe Disposal',
      'explanation':
          'Disease symptoms cover 40% or more of the fruit surface. The fruit '
          'is heavily infected, with a high risk of internal damage and of '
          'spreading the disease to healthy fruit and plants.',
      'waste_usage':
          'Remove the fruit from the farm area immediately. Compost it in a '
          'closed, hot compost system away from the orchard, or dispose of it '
          'safely by burying it deep in soil.',
      'safety_note':
          'Do not use for human consumption, animal feed, juice, pulp, peel '
          'powder, or dye. Do not leave infected fruit on the ground in the '
          'orchard, as it can spread the disease.',
    },

    // ==============================================================
    // R10–R12  LOW QUALITY — CRACK
    // ==============================================================
    {
      'rule_id': 'R10',
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 0.0,
      'severity_max': 14.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Immediate Juice Extraction',
      'explanation':
          'The crack covers less than 15% of the fruit surface. The fruit '
          'cannot be stored for long, but the clean, unaffected arils are '
          'still suitable for juice if processed immediately.',
      'waste_usage':
          'Wash the fruit, remove the cracked rind and any exposed or '
          'discoloured arils, then extract juice from the firm, '
          'normal-smelling arils on the same day. Store the juice chilled or '
          'pasteurise it.',
      'safety_note':
          'Do not use the fruit if the crack contains mould, insects, soil, '
          'leakage, fermentation, or a bad smell.',
    },

    {
      'rule_id': 'R11',
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 15.0,
      'severity_max': 39.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Peel Powder and Natural Dye Preparation',
      'explanation':
          'The crack covers about 15–39% of the fruit surface. The exposed '
          'arils have a higher contamination risk, but the pomegranate peel is '
          'rich in tannins and natural pigments and can still be used.',
      'waste_usage':
          'Separate the peel from the arils. Wash the clean peel, cut it into '
          'small pieces, and dry it in the shade or a dryer. Grind it into '
          'peel powder for natural dye, herbal or cosmetic uses. Compost the '
          'damaged arils and rind.',
      'safety_note':
          'Use only clean, mould-free peel. Peel powder made from damaged '
          'fruit is for non-food uses (dye, research, cosmetics) unless it is '
          'tested for safety.',
    },

    {
      'rule_id': 'R12',
      'quality_level': 'low_quality',
      'defect_type': 'crack',
      'severity_min': 40.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Composting – Organic Fertilizer',
      'explanation':
          'The crack covers 40% or more of the fruit surface. The large '
          'opening creates a high risk of microbial contamination, insect '
          'entry, and internal spoilage.',
      'waste_usage':
          'Remove the fruit from the food stream and place it in a compost pit '
          'with dry organic material. Maintain moisture and aeration until '
          'fully decomposed, then use the compost as field fertilizer.',
      'safety_note':
          'Do not use for fresh consumption, juice, pulp, animal feed, or peel '
          'powder.',
    },

    // ==============================================================
    // R13–R14  LOW QUALITY — SUNBURN
    // ==============================================================
    {
      'rule_id': 'R13',
      'quality_level': 'low_quality',
      'defect_type': 'sunburn',
      'severity_min': 0.0,
      'severity_max': 9.99,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Peel Powder and Natural Dye Preparation',
      'explanation':
          'Sunburn covers less than 10% of the fruit surface. The damage is '
          'external and dry, so the unaffected peel can be used for '
          'value-added products such as peel powder and natural dye.',
      'waste_usage':
          'Remove the burned section, wash the remaining peel, dry it under '
          'clean conditions, and grind it into peel powder or extract natural '
          'dye and tannins. The healthy arils can be used for juice after '
          'inspection.',
      'safety_note':
          'Confirm that there is no rot, mould, crack, or internal heat damage '
          'before using any part of the fruit.',
    },

    {
      'rule_id': 'R14',
      'quality_level': 'low_quality',
      'defect_type': 'sunburn',
      'severity_min': 10.0,
      'severity_max': _maximumSeverity,
      'weight_min': 0,
      'weight_max': _maximumWeight,
      'recommended_usage': 'Manual Inspection Before Any Usage Decision',
      'explanation':
          'Sunburn covers 10% or more of the fruit surface. The fruit may have '
          'hard, dry, or heat-damaged tissue inside, so the correct use cannot '
          'be decided from the image alone.',
      'waste_usage':
          'Cut and inspect the fruit. If the arils are healthy, use them for '
          'juice and the unaffected peel for peel powder or natural dye. If '
          'the damage reaches the inside, send the whole fruit for composting.',
      'safety_note':
          'Do not use damaged sections in food products. Decide the final use '
          'only after manual inspection.',
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

      // Round to 2 decimals so values like 4.995 % do not fall into the
      // gap between two rules (e.g. 4.99 and 5.0).
      final severity = double.parse(
        severityPercent.clamp(0.0, _maximumSeverity).toStringAsFixed(2),
      );

      for (final rule in _rules) {
        if (_matchesLowQualityRule(
          rule: rule,
          quality: normalizedQuality,
          defect: normalizedDefect,
          severity: severity,
        )) {
          final result = Map<String, dynamic>.from(rule);
          result['measured_severity'] = severity;
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
