import 'dart:math';

import '../../l10n/d_app_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ALL TREATMENT + PREVENTION DATA — ONE FILE (English / Tamil / Sinhala)
//
//  Disease names must match DiseaseLabels.diseaseClasses exactly.
//  Severity order everywhere: Mild → Moderate → Severe.
//
//  HOW IT WORKS ON THE SCREEN
//    • User picks ORGANIC  → organic plan for the detected severity
//                            (recommendation + product image + schedule)
//    • User picks CHEMICAL → chemical plan for the detected severity
//                            (recommendation + product image + schedule)
//    • Prevention tips are the SAME for Organic and Chemical
//      (3 or 4 picked per detection from the disease list).
//
//  SECTIONS IN THIS FILE
//    A. TreatmentImages      → asset paths (organic + chemical)
//    B. _plans               → ORGANIC and CHEMICAL plans
//                              (interval, applications, image, 3-language text)
//    C. _preventionTips      → 6–7 tips per disease, 3 languages, same order
//    D. _summary             → short 3-language text saved with the result
//
//  NOTE: have the content verified by an agriculture expert before
//  production use. Healthy fruit has no treatment on purpose.
// ═══════════════════════════════════════════════════════════════════════════

enum TreatmentType { organic, chemical }

enum Severity { mild, moderate, severe }

// ═══════════════════════════════════════════════════════════════════════════
//  A. PRODUCT IMAGES
//  Put the files in assets/images/treatments/ and list that folder in
//  pubspec.yaml. Change only the file names here if yours are different.
// ═══════════════════════════════════════════════════════════════════════════
class TreatmentImages {
  TreatmentImages._();

  static const String _dir = 'assets/images/treatments';

  // ── ORGANIC (12) ──
  static const String alternariaMild = '$_dir/alternaria_mild.png';
  static const String alternariaModerate = '$_dir/alternaria_moderate.png';
  static const String alternariaSevere = '$_dir/alternaria_severe.png';

  static const String anthracnoseMild = '$_dir/anthracnose_mild.png';
  static const String anthracnoseModerate = '$_dir/anthracnose_moderate.png';
  static const String anthracnoseSevere = '$_dir/anthracnose_severe.png';

  static const String bacterialBlightMild = '$_dir/bacterial_blight_mild.png';
  static const String bacterialBlightModerate =
      '$_dir/bacterial_blight_moderate.png';
  static const String bacterialBlightSevere =
      '$_dir/bacterial_blight_severe.png';

  static const String cercosporaMild = '$_dir/anthracnose_mild.png';
  static const String cercosporaModerate = '$_dir/alternaria_severe.png';
  static const String cercosporaSevere = '$_dir/anthracnose_severe.png';

  // ── CHEMICAL (12) — names as in your folder (C + disease + level) ──
  static const String chemAlternariaMild = '$_dir/Calternaria_mild.png';
  static const String chemAlternariaModerate = '$_dir/Calternaria_moderate.png';
  static const String chemAlternariaSevere = '$_dir/Calternaria_severe.jpeg';

  static const String chemAnthracnoseMild = '$_dir/Canthrocnose_mild.png';
  static const String chemAnthracnoseModerate =
      '$_dir/Canthrocnose_moderate.png';
  static const String chemAnthracnoseSevere = '$_dir/Canthrocnose_severe.png';

  static const String chemBlightMild = '$_dir/Cblight_mild.png';
  static const String chemBlightModerate = '$_dir/Ccercospora_severe.png';
  static const String chemBlightSevere = '$_dir/Calternaria_mild.png';

  static const String chemCercosporaMild = '$_dir/Ccercospora_mild.png';
  static const String chemCercosporaModerate = '$_dir/Ccercospora_moderate.png';
  static const String chemCercosporaSevere = '$_dir/Ccercospora_severe.png';
}

/// Shown on the result page and the history detail page.
class TreatmentContent {
  final String recommendation;
  final List<String> prevention;

  /// Asset path of the product image (null → no image shown).
  final String? image;

  const TreatmentContent({
    required this.recommendation,
    required this.prevention,
    this.image,
  });
}

/// Saved with the result (Firestore) — used by disease_service.dart.
class DiseaseTreatmentInfo {
  final String treatment;
  final List<String> prevention;
  final int followUpDays;

  const DiseaseTreatmentInfo({
    required this.treatment,
    required this.prevention,
    required this.followUpDays,
  });
}

/// Re-apply interval + number of applications.
class TreatmentSchedule {
  final int everyDays;
  final int applications;
  const TreatmentSchedule(this.everyDays, this.applications);

  int get totalDays => everyDays * applications;
}

/// One treatment option for one disease + severity.
class TreatmentPlan {
  final TreatmentSchedule schedule;
  final String? image;

  /// Recommendation text by language code: 'en' / 'ta' / 'si'.
  final Map<String, String> text;

  const TreatmentPlan({required this.schedule, required this.text, this.image});
}

class _Summary {
  final String treatment;
  final List<String> prevention;
  const _Summary({required this.treatment, required this.prevention});
}

// ═══════════════════════════════════════════════════════════════════════════
//  PUBLIC API — TreatmentData (schedule + short summary)
// ═══════════════════════════════════════════════════════════════════════════
class TreatmentData {
  TreatmentData._();

  /// 'Mild' / 'Moderate' / 'Severe' → enum. Anything else ('N/A', old data)
  /// is treated as Moderate.
  static Severity severityFrom(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'mild':
        return Severity.mild;
      case 'severe':
        return Severity.severe;
      default:
        return Severity.moderate;
    }
  }

  /// Short treatment text + follow-up days (saved with the result).
  /// followUpDays = ORGANIC schedule (default choice on the result page).
  static DiseaseTreatmentInfo forDisease(
    String diseaseName,
    AppLanguage language, {
    String? severityLevel,
  }) {
    final table = _summary[language.code] ?? _summary['en']!;
    final text = table[diseaseName] ?? table['Healthy']!;
    final days = diseaseName == 'Healthy'
        ? 14
        : scheduleFor(diseaseName, severityLevel).everyDays;
    return DiseaseTreatmentInfo(
      treatment: text.treatment,
      prevention: text.prevention,
      followUpDays: days,
    );
  }

  /// Interval + applications for this disease, severity and treatment type.
  /// Organic and Chemical have DIFFERENT schedules.
  static TreatmentSchedule scheduleFor(
    String diseaseName,
    String? severityLevel, {
    TreatmentType type = TreatmentType.organic,
  }) =>
      TreatmentOptionsData
          ._plans[type]?[diseaseName]?[severityFrom(severityLevel)]
          ?.schedule ??
      const TreatmentSchedule(10, 3);

  /// How many times the treatment should be applied.
  static int applicationCount(
    String diseaseName, {
    String? severityLevel,
    TreatmentType type = TreatmentType.organic,
  }) => scheduleFor(diseaseName, severityLevel, type: type).applications;

  // ── D. SUMMARY — short 3-language text saved with the result (unchanged) ──
  static const Map<String, Map<String, _Summary>> _summary = {
    'en': {
      'Healthy': _Summary(
        treatment: 'No disease detected. Continue regular care and monitoring.',
        prevention: [
          'Maintain balanced irrigation and fertilization',
          'Prune regularly for good air circulation',
          'Inspect fruit weekly for early signs of disease',
        ],
      ),
      'Alternaria': _Summary(
        treatment:
            'Remove and destroy infected fruit and leaves. Apply a recommended '
            'copper-based fungicide every 10-14 days until symptoms subside.',
        prevention: [
          'Avoid overhead irrigation that wets fruit surface',
          'Improve canopy ventilation through pruning',
          'Remove fallen infected debris from the orchard floor',
        ],
      ),
      'Anthracnose': _Summary(
        treatment:
            'Prune and destroy affected twigs and fruit. Apply a suitable '
            'fungicide spray at early symptom onset, per local extension advice.',
        prevention: [
          'Avoid injuring fruit during handling',
          'Thin fruit clusters to reduce humidity',
          'Store harvested fruit in a cool, dry place',
        ],
      ),
      'Bacterial_Blight': _Summary(
        treatment:
            'Remove and burn infected plant parts. Apply copper-based '
            'bactericide sprays; disinfect pruning tools between plants.',
        prevention: [
          'Avoid orchard work during wet weather',
          'Use disease-free planting material',
          'Disinfect tools regularly',
        ],
      ),
      'Cercospora': _Summary(
        treatment:
            'Remove heavily spotted leaves and apply a recommended foliar '
            'fungicide. Ensure good drainage and avoid excess nitrogen.',
        prevention: [
          'Avoid excess nitrogen fertilizer',
          'Improve field drainage',
          'Rotate fungicide types to prevent resistance',
        ],
      ),
    },
    'ta': {
      'Healthy': _Summary(
        treatment:
            'நோய் எதுவும் கண்டறியப்படவில்லை. வழக்கமான பராமரிப்பைத் தொடரவும்.',
        prevention: [
          'சீரான நீர்ப்பாசனம் மற்றும் உரமிடுதல்',
          'நல்ல காற்றோட்டத்திற்காக வழக்கமாக கத்தரிக்கவும்',
          'ஆரம்ப அறிகுறிகளுக்காக வாரந்தோறும் பரிசோதிக்கவும்',
        ],
      ),
      'Alternaria': _Summary(
        treatment:
            'பாதிக்கப்பட்ட பழங்கள், இலைகளை அகற்றி அழிக்கவும். செம்பு அடிப்படையிலான '
            'பூஞ்சைக்கொல்லியை 10-14 நாட்களுக்கு ஒருமுறை தெளிக்கவும்.',
        prevention: [
          'மேலிருந்து நீர் பாய்ச்சுவதைத் தவிர்க்கவும்',
          'கத்தரித்தல் மூலம் காற்றோட்டத்தை மேம்படுத்தவும்',
          'விழுந்த பாதிக்கப்பட்ட இலைகளை அகற்றவும்',
        ],
      ),
      'Anthracnose': _Summary(
        treatment:
            'பாதிக்கப்பட்ட கிளைகள், பழங்களை கத்தரித்து அழிக்கவும். ஆரம்ப அறிகுறியில் '
            'பொருத்தமான பூஞ்சைக்கொல்லியை தெளிக்கவும்.',
        prevention: [
          'பழங்களை கையாளும்போது காயப்படுத்தாதீர்கள்',
          'கொத்துகளை நீர்த்துப்போக்கி ஈரப்பதத்தைக் குறைக்கவும்',
          'அறுவடை செய்த பழத்தை குளிர்ந்த இடத்தில் சேமிக்கவும்',
        ],
      ),
      'Bacterial_Blight': _Summary(
        treatment:
            'பாதிக்கப்பட்ட பகுதிகளை அகற்றி எரிக்கவும். செம்பு அடிப்படையிலான '
            'பாக்டீரியா கொல்லியை தெளிக்கவும்; கருவிகளை தூய்மைப்படுத்தவும்.',
        prevention: [
          'ஈரமான வானிலையில் தோட்ட வேலை தவிர்க்கவும்',
          'நோய் இல்லாத நடவு பொருளைப் பயன்படுத்தவும்',
          'கருவிகளை தவறாமல் தூய்மைப்படுத்தவும்',
        ],
      ),
      'Cercospora': _Summary(
        treatment:
            'கடுமையாக பாதிக்கப்பட்ட இலைகளை அகற்றி பூஞ்சைக்கொல்லியை தெளிக்கவும். '
            'நல்ல வடிகால் மற்றும் மிதமான நைட்ரஜன் உரமிடுதலை உறுதி செய்யவும்.',
        prevention: [
          'அதிக நைட்ரஜன் உரத்தைத் தவிர்க்கவும்',
          'வயல் வடிகாலை மேம்படுத்தவும்',
          'பூஞ்சைக்கொல்லி வகைகளை மாற்றி பயன்படுத்தவும்',
        ],
      ),
    },
    'si': {
      'Healthy': _Summary(
        treatment: 'රෝගයක් හඳුනාගෙන නැත. සාමාන්‍ය රැකවරණය දිගටම කරගෙන යන්න.',
        prevention: [
          'සමතුලිත ජල සම්පාදනය සහ පොහොර යෙදීම පවත්වා ගන්න',
          'හොඳ වායු සංසරණය සඳහා නිතිපතා කප්පාදු කරන්න',
          'මුල් රෝග ලක්ෂණ සඳහා සතිපතා පරීක්ෂා කරන්න',
        ],
      ),
      'Alternaria': _Summary(
        treatment:
            'බලපෑමට ලක් වූ ගෙඩි, කොළ ඉවත් කර විනාශ කරන්න. තඹ පදනම් වූ දිලීර නාශකයක් '
            'දින 10-14 කට වරක් ඉසින්න.',
        prevention: [
          'මතුපිට තෙත් කරන ජල සම්පාදනය වළක්වන්න',
          'කප්පාදුව මගින් වායු සංසරණය වැඩි දියුණු කරන්න',
          'වැටුණු බලපෑමට ලක් වූ කොළ ඉවත් කරන්න',
        ],
      ),
      'Anthracnose': _Summary(
        treatment:
            'බලපෑමට ලක් වූ අතු, ගෙඩි කප්පාදු කර විනාශ කරන්න. මුල් අවධියේදීම '
            'සුදුසු දිලීර නාශකයක් ඉසින්න.',
        prevention: [
          'ගෙඩි හැසිරවීමේදී හානි නොකරන්න',
          'තුනීකරණය මගින් තෙතමනය අඩු කරන්න',
          'අස්වනු නෙළූ ගෙඩි සිසිල් ස්ථානයක ගබඩා කරන්න',
        ],
      ),
      'Bacterial_Blight': _Summary(
        treatment:
            'බලපෑමට ලක් වූ කොටස් ඉවත් කර පුළුස්සන්න. තඹ පදනම් වූ බැක්ටීරියා නාශකයක් '
            'ඉසින්න; මෙවලම් නිසි ලෙස පිරිසිදු කරන්න.',
        prevention: [
          'තෙත් කාලගුණයේදී ගොවිපොළේ වැඩ කිරීම වළක්වන්න',
          'රෝග රහිත රෝපණ ද්‍රව්‍ය භාවිතා කරන්න',
          'මෙවලම් නිතිපතා පිරිසිදු කරන්න',
        ],
      ),
      'Cercospora': _Summary(
        treatment:
            'දැඩි ලෙස පැල්ලම් වූ කොළ ඉවත් කර දිලීර නාශකයක් ඉසින්න. '
            'හොඳ ජලාපවහනය සහ මධ්‍යස්ථ නයිට්‍රජන් සහතික කරන්න.',
        prevention: [
          'අධික නයිට්‍රජන් පොහොර වළක්වන්න',
          'කෙත් ජලාපවහනය වැඩි දියුණු කරන්න',
          'දිලීර නාශක වර්ග මාරුවෙන් මාරුවට භාවිතා කරන්න',
        ],
      ),
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  PUBLIC API — TreatmentOptionsData (Organic / Chemical on the screens)
// ═══════════════════════════════════════════════════════════════════════════
class TreatmentOptionsData {
  TreatmentOptionsData._();

  static const Map<String, String> _fallbackText = {
    'en':
        'Consult a local agricultural expert for a tailored treatment plan '
        'for this condition.',
    'ta':
        'இந்த நிலைக்கு ஏற்ற சிகிச்சைத் திட்டத்திற்கு உள்ளூர் வேளாண் '
        'நிபுணரை அணுகவும்.',
    'si':
        'මෙම තත්ත්වයට ගැළපෙන ප්‍රතිකාර සැලැස්මක් සඳහා ප්‍රාදේශීය කෘෂිකර්ම '
        'විශේෂඥයෙකුගෙන් උපදෙස් ලබා ගන්න.',
  };

  static const Map<String, String> _fallbackTip = {
    'en': 'Monitor the fruit regularly for changes',
    'ta': 'பழத்தில் ஏற்படும் மாற்றங்களைத் தொடர்ந்து கண்காணிக்கவும்',
    'si': 'ගෙඩියේ වෙනස්කම් නිතිපතා නිරීක්ෂණය කරන්න',
  };

  /// Recommendation + image for the chosen type and severity,
  /// plus 3–4 prevention tips (same for Organic and Chemical).
  ///
  /// [language] defaults to the app language (LanguageController).
  /// [seed] keeps the tips the SAME for one detection (result page and
  /// history detail match) but DIFFERENT between detections — use [seedFor].
  static TreatmentContent forDisease(
    String disease,
    TreatmentType type, {
    String? severityLevel,
    int seed = 0,
    AppLanguage? language,
  }) {
    final code = (language ?? LanguageController.instance.language).code;
    final tips = preventionTips(disease, seed: seed, languageCode: code);

    final plan =
        _plans[type]?[disease]?[TreatmentData.severityFrom(severityLevel)];
    if (plan == null) {
      return TreatmentContent(
        recommendation: _fallbackText[code] ?? _fallbackText['en']!,
        prevention: tips,
      );
    }
    return TreatmentContent(
      recommendation: plan.text[code] ?? plan.text['en']!,
      prevention: tips,
      image: plan.image,
    );
  }

  /// Picks 3 or 4 tips — same seed → same tips in EVERY language
  /// (the lists have the same order in en / ta / si).
  static List<String> preventionTips(
    String disease, {
    int seed = 0,
    String languageCode = 'en',
  }) {
    final table = _preventionTips[languageCode] ?? _preventionTips['en']!;
    final all = table[disease];
    if (all == null || all.isEmpty) {
      return [_fallbackTip[languageCode] ?? _fallbackTip['en']!];
    }
    final rng = Random(seed);
    final count = min(all.length, 3 + rng.nextInt(2)); // 3 or 4
    final indexes = List<int>.generate(all.length, (i) => i)..shuffle(rng);
    final picked = indexes.take(count).toList()..sort(); // keep list order
    return [for (final i in picked) all[i]];
  }

  /// Stable number for one detection (predictionId, else detection time).
  /// Own hash on purpose — gives the same value on every app start.
  static int seedFor(String? predictionId, DateTime detectedAt) {
    final key = (predictionId != null && predictionId.isNotEmpty)
        ? predictionId
        : '${detectedAt.millisecondsSinceEpoch ~/ 1000}';
    var hash = 17;
    for (final c in key.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return hash;
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  B. TREATMENT PLANS
  //     TreatmentSchedule(days between applications, number of applications)
  // ═════════════════════════════════════════════════════════════════════════
  static const Map<TreatmentType, Map<String, Map<Severity, TreatmentPlan>>>
  _plans = {
    // ───────────────────────────────────────────────────────────────────────
    //  🌿 ORGANIC
    // ───────────────────────────────────────────────────────────────────────
    TreatmentType.organic: {
      'Alternaria': {
        // Bordeaux mixture 0.5% — 80 g + 80 g / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(14, 2),
          image: TreatmentImages.alternariaMild,
          text: {
            'en':
                'Apply 0.5% Bordeaux mixture using 80 g copper sulphate and '
                '80 g lime, made up to a final volume of 16 L. Repeat after '
                '14 days for two applications in total. Monitor for new or '
                'expanding spots.',
            'ta':
                '80 கிராம் காப்பர் சல்பேட் மற்றும் 80 கிராம் சுண்ணாம்பு கொண்டு, '
                'மொத்தம் 16 லிட்டராக தயாரித்த 0.5% போர்டோ கலவையைத் தெளிக்கவும். '
                '14 நாட்களுக்குப் பிறகு மீண்டும் தெளிக்கவும் — மொத்தம் இரண்டு '
                'முறை. புதிய அல்லது பரவும் புள்ளிகளைக் கண்காணிக்கவும்.',
            'si':
                'තඹ සල්ෆේට් ග්‍රෑම් 80 ක් සහ හුනු ග්‍රෑම් 80 ක් භාවිතයෙන්, මුළු '
                'පරිමාව ලීටර් 16 ක් වන සේ සාදාගත් 0.5% බෝඩෝ මිශ්‍රණය යොදන්න. '
                'දින 14 කට පසු නැවත යොදන්න — මුළු වාර දෙකකි. නව හෝ පැතිරෙන '
                'පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Bordeaux mixture 0.75% — 120 g + 120 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(10, 3),
          image: TreatmentImages.alternariaModerate,
          text: {
            'en':
                'Clear infected fruits and fallen debris. Apply 0.75% '
                'Bordeaux mixture using 120 g copper sulphate and 120 g lime, '
                'made up to a final volume of 16 L. Repeat every 10 days for '
                'three applications in total.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் விழுந்த கழிவுகளையும் அகற்றவும். '
                '120 கிராம் காப்பர் சல்பேட் மற்றும் 120 கிராம் சுண்ணாம்பு கொண்டு, '
                'மொத்தம் 16 லிட்டராக தயாரித்த 0.75% போர்டோ கலவையைத் '
                'தெளிக்கவும். 10 நாட்களுக்கு ஒருமுறை, மொத்தம் மூன்று முறை '
                'தெளிக்கவும்.',
            'si':
                'ආසාදිත ගෙඩි සහ වැටුණු අපද්‍රව්‍ය ඉවත් කරන්න. තඹ සල්ෆේට් '
                'ග්‍රෑම් 120 ක් සහ හුනු ග්‍රෑම් 120 ක් භාවිතයෙන්, මුළු පරිමාව '
                'ලීටර් 16 ක් වන සේ සාදාගත් 0.75% බෝඩෝ මිශ්‍රණය යොදන්න. දින 10 '
                'කට වරක්, මුළු වාර තුනක් යොදන්න.',
          },
        ),
        // Bordeaux mixture 1% — 160 g + 160 g / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(7, 4),
          image: TreatmentImages.alternariaSevere,
          text: {
            'en':
                'Remove badly affected and rotting fruits promptly. Apply 1% '
                'Bordeaux mixture using 160 g copper sulphate and 160 g lime, '
                'made up to a final volume of 16 L. Repeat every 7 days for '
                'four applications in total.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட மற்றும் அழுகிய பழங்களை உடனடியாக '
                'அகற்றவும். 160 கிராம் காப்பர் சல்பேட் மற்றும் 160 கிராம் '
                'சுண்ணாம்பு கொண்டு, மொத்தம் 16 லிட்டராக தயாரித்த 1% போர்டோ '
                'கலவையைத் தெளிக்கவும். 7 நாட்களுக்கு ஒருமுறை, மொத்தம் நான்கு '
                'முறை தெளிக்கவும்.',
            'si':
                'දැඩි ලෙස බලපෑමට ලක් වූ සහ කුණු වූ ගෙඩි වහාම ඉවත් කරන්න. තඹ '
                'සල්ෆේට් ග්‍රෑම් 160 ක් සහ හුනු ග්‍රෑම් 160 ක් භාවිතයෙන්, මුළු '
                'පරිමාව ලීටර් 16 ක් වන සේ සාදාගත් 1% බෝඩෝ මිශ්‍රණය යොදන්න. '
                'දින 7 කට වරක්, මුළු වාර හතරක් යොදන්න.',
          },
        ),
      },
      'Anthracnose': {
        // Copper oxychloride 35% WP — 1 g/L, 16 g / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(15, 2),
          image: TreatmentImages.anthracnoseMild,
          text: {
            'en':
                'Apply copper oxychloride 35% WP at 16 g per 16 L tank. '
                'Repeat after 15 days for two applications in total. Monitor '
                'for new or expanding spots.',
            'ta':
                'காப்பர் ஆக்ஸிகுளோரைடு 35% WP-ஐ 16 லிட்டர் தொட்டிக்கு 16 '
                'கிராம் அளவில் தெளிக்கவும். 15 நாட்களுக்குப் பிறகு மீண்டும் '
                'தெளிக்கவும் — மொத்தம் இரண்டு முறை. புதிய அல்லது பரவும் '
                'புள்ளிகளைக் கண்காணிக்கவும்.',
            'si':
                'කොපර් ඔක්සික්ලෝරයිඩ් 35% WP, ලීටර් 16 ටැංකියකට ග්‍රෑම් 16 '
                'බැගින් යොදන්න. දින 15 කට පසු නැවත යොදන්න — මුළු වාර දෙකකි. '
                'නව හෝ පැතිරෙන පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Copper oxychloride 50% WP — 1.5 g/L, 24 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(12, 3),
          image: TreatmentImages.anthracnoseModerate,
          text: {
            'en':
                'Remove infected fruits and improve airflow. Apply copper '
                'oxychloride 50% WP at 24 g per 16 L tank. Repeat every 12 '
                'days for three applications in total.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களை அகற்றி காற்றோட்டத்தை மேம்படுத்தவும். '
                'காப்பர் ஆக்ஸிகுளோரைடு 50% WP-ஐ 16 லிட்டர் தொட்டிக்கு 24 கிராம் '
                'அளவில் தெளிக்கவும். 12 நாட்களுக்கு ஒருமுறை, மொத்தம் மூன்று '
                'முறை தெளிக்கவும்.',
            'si':
                'ආසාදිත ගෙඩි ඉවත් කර වාතාශ්‍රය වැඩි දියුණු කරන්න. කොපර් '
                'ඔක්සික්ලෝරයිඩ් 50% WP, ලීටර් 16 ටැංකියකට ග්‍රෑම් 24 බැගින් '
                'යොදන්න. දින 12 කට වරක්, මුළු වාර තුනක් යොදන්න.',
          },
        ),
        // Copper oxychloride 50% WP — 2 g/L, 32 g / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(10, 4),
          image: TreatmentImages.anthracnoseSevere,
          text: {
            'en':
                'Remove heavily affected and rotting fruits promptly. Apply '
                'copper oxychloride 50% WP at 32 g per 16 L tank. Repeat every '
                '10 days for four applications in total. Inspect nearby fruits '
                'for further infection.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட மற்றும் அழுகிய பழங்களை உடனடியாக '
                'அகற்றவும். காப்பர் ஆக்ஸிகுளோரைடு 50% WP-ஐ 16 லிட்டர் தொட்டிக்கு '
                '32 கிராம் அளவில் தெளிக்கவும். 10 நாட்களுக்கு ஒருமுறை, மொத்தம் '
                'நான்கு முறை தெளிக்கவும். அருகிலுள்ள பழங்களில் தொற்று '
                'பரவுகிறதா என சோதிக்கவும்.',
            'si':
                'දැඩි ලෙස බලපෑමට ලක් වූ සහ කුණු වූ ගෙඩි වහාම ඉවත් කරන්න. කොපර් '
                'ඔක්සික්ලෝරයිඩ් 50% WP, ලීටර් 16 ටැංකියකට ග්‍රෑම් 32 බැගින් '
                'යොදන්න. දින 10 කට වරක්, මුළු වාර හතරක් යොදන්න. අසල ඇති '
                'ගෙඩිවල තවදුරටත් ආසාදනය ඇත්දැයි පරීක්ෂා කරන්න.',
          },
        ),
      },
      'Bacterial_Blight': {
        // Garlic bulb extract 30% — 4.8 L extract + 11.2 L water
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(14, 2),
          image: TreatmentImages.bacterialBlightMild,
          text: {
            'en':
                'Apply the prepared 30% garlic extract using 4.8 L extract '
                'and 11.2 L water for a 16 L tank. Repeat after 14 days for '
                'two applications in total. Monitor for new spots.',
            'ta':
                'தயாரித்த 30% பூண்டு சாற்றை, 16 லிட்டர் தொட்டிக்கு 4.8 லிட்டர் '
                'சாறு மற்றும் 11.2 லிட்டர் நீர் கலந்து தெளிக்கவும். 14 '
                'நாட்களுக்குப் பிறகு மீண்டும் தெளிக்கவும் — மொத்தம் இரண்டு '
                'முறை. புதிய புள்ளிகளைக் கண்காணிக்கவும்.',
            'si':
                'සකස් කළ 30% සුදුළූණු සාරය, ලීටර් 16 ටැංකියකට සාරය ලීටර් 4.8 ක් '
                'සහ ජලය ලීටර් 11.2 ක් මිශ්‍ර කර යොදන්න. දින 14 කට පසු නැවත '
                'යොදන්න — මුළු වාර දෙකකි. නව පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Tulsi leaf extract 40%, then neem seed oil
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(10, 2),
          image: TreatmentImages.bacterialBlightModerate,
          text: {
            'en':
                'Clear infected fruits and fallen debris. Spray the prepared '
                '40% Tulsi extract using 6.4 L extract and 9.6 L water. Follow '
                'with a separate neem seed oil application at its label dose '
                'and timing. Repeat the sequence after 10 days.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் விழுந்த கழிவுகளையும் அகற்றவும். '
                'தயாரித்த 40% துளசி சாற்றை 6.4 லிட்டர் சாறு மற்றும் 9.6 லிட்டர் '
                'நீர் கலந்து தெளிக்கவும். அதன் பின் வேப்ப விதை எண்ணெயை, அதன் '
                'லேபிளில் உள்ள அளவு மற்றும் நேரப்படி தனியாக தெளிக்கவும். 10 '
                'நாட்களுக்குப் பிறகு இதே வரிசையை மீண்டும் செய்யவும்.',
            'si':
                'ආසාදිත ගෙඩි සහ වැටුණු අපද්‍රව්‍ය ඉවත් කරන්න. සකස් කළ 40% තුලසි '
                'සාරය, සාරය ලීටර් 6.4 ක් සහ ජලය ලීටර් 9.6 ක් මිශ්‍ර කර ඉසින්න. '
                'ඉන්පසු කොහොඹ ඇට තෙල් එහි ලේබලයේ සඳහන් මාත්‍රාව හා වේලාව අනුව '
                'වෙනම යොදන්න. දින 10 කට පසු මෙම අනුපිළිවෙල නැවත කරන්න.',
          },
        ),
        // Tulsi leaf extract 40%, then neem seed oil
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(7, 3),
          image: TreatmentImages.bacterialBlightSevere,
          text: {
            'en':
                'Remove severely infected fruits and branches. Spray 40% '
                'Tulsi extract (6.4 L extract + 9.6 L water), then apply neem '
                'oil separately as labelled. Repeat every 7 days for three '
                'rounds and check nearby trees.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட பழங்களையும் கிளைகளையும் அகற்றவும். 40% '
                'துளசி சாற்றை (6.4 லிட்டர் சாறு + 9.6 லிட்டர் நீர்) தெளித்து, '
                'பின்னர் வேப்ப எண்ணெயை லேபிளின்படி தனியாக தெளிக்கவும். 7 '
                'நாட்களுக்கு ஒருமுறை மூன்று சுற்றுகள் செய்து, அருகிலுள்ள '
                'மரங்களையும் சோதிக்கவும்.',
            'si':
                'දැඩි ලෙස ආසාදිත ගෙඩි සහ අතු ඉවත් කරන්න. 40% තුලසි සාරය (සාරය '
                'ලීටර් 6.4 + ජලය ලීටර් 9.6) ඉස, ඉන්පසු කොහොඹ තෙල් ලේබලයේ පරිදි '
                'වෙනම යොදන්න. දින 7 කට වරක් වට තුනක් කර, අසල ගස් ද පරීක්ෂා '
                'කරන්න.',
          },
        ),
      },
      'Cercospora': {
        // Copper oxychloride 35% WP — 2 g/L, 32 g / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(15, 2),
          image: TreatmentImages.cercosporaMild,
          text: {
            'en':
                'Apply copper oxychloride 35% WP at 2 g/L (32 g per 16 L '
                'tank). Repeat after 15 days, for two applications total. '
                'Monitor for new spots.',
            'ta':
                'காப்பர் ஆக்ஸிகுளோரைடு 35% WP-ஐ லிட்டருக்கு 2 கிராம் (16 '
                'லிட்டர் தொட்டிக்கு 32 கிராம்) அளவில் தெளிக்கவும். 15 '
                'நாட்களுக்குப் பிறகு மீண்டும் தெளிக்கவும் — மொத்தம் இரண்டு '
                'முறை. புதிய புள்ளிகளைக் கண்காணிக்கவும்.',
            'si':
                'කොපර් ඔක්සික්ලෝරයිඩ් 35% WP, ලීටරයකට ග්‍රෑම් 2 බැගින් (ලීටර් '
                '16 ටැංකියකට ග්‍රෑම් 32) යොදන්න. දින 15 කට පසු නැවත යොදන්න — '
                'මුළු වාර දෙකකි. නව පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Bordeaux mixture 1% — 160 g + 160 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(10, 3),
          image: TreatmentImages.cercosporaModerate,
          text: {
            'en':
                'Remove infected fruits and fallen leaves. Apply 1% Bordeaux '
                'mixture using 10 g copper sulphate + 10 g lime per 1 L final '
                'mixture (160 g + 160 g per 16 L). Repeat every 10 days, for '
                '3 applications total.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் விழுந்த இலைகளையும் அகற்றவும். ஒரு '
                'லிட்டர் கலவைக்கு 10 கிராம் காப்பர் சல்பேட் + 10 கிராம் '
                'சுண்ணாம்பு (16 லிட்டருக்கு 160 கிராம் + 160 கிராம்) கொண்ட 1% '
                'போர்டோ கலவையைத் தெளிக்கவும். 10 நாட்களுக்கு ஒருமுறை, மொத்தம் '
                '3 முறை தெளிக்கவும்.',
            'si':
                'ආසාදිත ගෙඩි සහ වැටුණු කොළ ඉවත් කරන්න. අවසන් මිශ්‍රණ ලීටරයකට '
                'තඹ සල්ෆේට් ග්‍රෑම් 10 + හුනු ග්‍රෑම් 10 (ලීටර් 16 කට ග්‍රෑම් '
                '160 + ග්‍රෑම් 160) භාවිතයෙන් 1% බෝඩෝ මිශ්‍රණය යොදන්න. දින 10 '
                'කට වරක්, මුළු වාර 3 ක් යොදන්න.',
          },
        ),
        // Copper oxychloride 50% WP — 3 g/L, 48 g / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(7, 4),
          image: TreatmentImages.cercosporaSevere,
          text: {
            'en':
                'Clear heavily infected fruits and fallen leaves promptly. '
                'Spray copper oxychloride 50% WP at 3 g/L (48 g per 16 L tank) '
                'every 7 days, for 4 applications total. Check nearby trees '
                'for spread.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட பழங்களையும் விழுந்த இலைகளையும் '
                'உடனடியாக அகற்றவும். காப்பர் ஆக்ஸிகுளோரைடு 50% WP-ஐ '
                'லிட்டருக்கு 3 கிராம் (16 லிட்டர் தொட்டிக்கு 48 கிராம்) அளவில் '
                '7 நாட்களுக்கு ஒருமுறை, மொத்தம் 4 முறை தெளிக்கவும். '
                'அருகிலுள்ள மரங்களில் பரவல் உள்ளதா என சோதிக்கவும்.',
            'si':
                'දැඩි ලෙස ආසාදිත ගෙඩි සහ වැටුණු කොළ වහාම ඉවත් කරන්න. කොපර් '
                'ඔක්සික්ලෝරයිඩ් 50% WP, ලීටරයකට ග්‍රෑම් 3 බැගින් (ලීටර් 16 '
                'ටැංකියකට ග්‍රෑම් 48) දින 7 කට වරක්, මුළු වාර 4 ක් ඉසින්න. අසල '
                'ගස්වලට පැතිරී ඇත්දැයි පරීක්ෂා කරන්න.',
          },
        ),
      },
    },

    // ───────────────────────────────────────────────────────────────────────
    //  🧪 CHEMICAL
    // ───────────────────────────────────────────────────────────────────────
    TreatmentType.chemical: {
      'Alternaria': {
        // Mancozeb 75% WP — 2.666 g/L, ≈42.66 g / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(15, 2),
          image: TreatmentImages.chemAlternariaMild,
          text: {
            'en':
                'Remove affected fruits. Apply mancozeb 75% WP at 2.666 g/L '
                '(approximately 42.66 g per 16 L tank). Repeat after 15 days '
                'for 2 applications total. Monitor for new spots.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களை அகற்றவும். மான்கோசெப் 75% WP-ஐ '
                'லிட்டருக்கு 2.666 கிராம் (16 லிட்டர் தொட்டிக்கு சுமார் 42.66 '
                'கிராம்) அளவில் தெளிக்கவும். 15 நாட்களுக்குப் பிறகு மீண்டும் '
                'தெளிக்கவும் — மொத்தம் 2 முறை. புதிய புள்ளிகளைக் '
                'கண்காணிக்கவும்.',
            'si':
                'බලපෑමට ලක් වූ ගෙඩි ඉවත් කරන්න. මැන්කොසෙබ් 75% WP, ලීටරයකට '
                'ග්‍රෑම් 2.666 බැගින් (ලීටර් 16 ටැංකියකට ආසන්න වශයෙන් ග්‍රෑම් '
                '42.66) යොදන්න. දින 15 කට පසු නැවත යොදන්න — මුළු වාර 2 කි. නව '
                'පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Captan 50% WP — 2.5 g/L, 40 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(10, 3),
          image: TreatmentImages.chemAlternariaModerate,
          text: {
            'en':
                'Clear infected fruits and fallen debris. Apply captan 50% WP '
                'at 2.5 g/L (40 g per 16 L tank). Repeat every 10 days for 3 '
                'applications total. Inspect nearby fruits.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் விழுந்த கழிவுகளையும் அகற்றவும். '
                'கேப்டான் 50% WP-ஐ லிட்டருக்கு 2.5 கிராம் (16 லிட்டர் தொட்டிக்கு '
                '40 கிராம்) அளவில் தெளிக்கவும். 10 நாட்களுக்கு ஒருமுறை, மொத்தம் '
                '3 முறை தெளிக்கவும். அருகிலுள்ள பழங்களைச் சோதிக்கவும்.',
            'si':
                'ආසාදිත ගෙඩි සහ වැටුණු අපද්‍රව්‍ය ඉවත් කරන්න. කැප්ටන් 50% WP, '
                'ලීටරයකට ග්‍රෑම් 2.5 බැගින් (ලීටර් 16 ටැංකියකට ග්‍රෑම් 40) '
                'යොදන්න. දින 10 කට වරක්, මුළු වාර 3 ක් යොදන්න. අසල ගෙඩි '
                'පරීක්ෂා කරන්න.',
          },
        ),
        // Propiconazole 25% EC — 1 ml/L, 16 ml / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(7, 4),
          image: TreatmentImages.chemAlternariaSevere,
          text: {
            'en':
                'Remove heavily affected and rotting fruits. Apply '
                'propiconazole 25% EC at 1 ml/L (16 ml per 16 L tank). Repeat '
                'every 7 days for 4 applications total.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட மற்றும் அழுகிய பழங்களை அகற்றவும். '
                'புரோபிகோனசோல் 25% EC-ஐ லிட்டருக்கு 1 மி.லி (16 லிட்டர் '
                'தொட்டிக்கு 16 மி.லி) அளவில் தெளிக்கவும். 7 நாட்களுக்கு '
                'ஒருமுறை, மொத்தம் 4 முறை தெளிக்கவும்.',
            'si':
                'දැඩි ලෙස බලපෑමට ලක් වූ සහ කුණු වූ ගෙඩි ඉවත් කරන්න. '
                'ප්‍රොපිකොනසෝල් 25% EC, ලීටරයකට මි.ලී. 1 බැගින් (ලීටර් 16 '
                'ටැංකියකට මි.ලී. 16) යොදන්න. දින 7 කට වරක්, මුළු වාර 4 ක් '
                'යොදන්න.',
          },
        ),
      },
      'Anthracnose': {
        // Mancozeb 45% WG — 3.33 g/L, 53.33 g / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(10, 2),
          image: TreatmentImages.chemAnthracnoseMild,
          text: {
            'en':
                'Apply mancozeb 45% WG at approximately 3.33 g/L (53.33 g per '
                '16 L tank). Repeat after 10 days for two applications total. '
                'Monitor fruits for new or expanding spots.',
            'ta':
                'மான்கோசெப் 45% WG-ஐ லிட்டருக்கு சுமார் 3.33 கிராம் (16 லிட்டர் '
                'தொட்டிக்கு 53.33 கிராம்) அளவில் தெளிக்கவும். 10 நாட்களுக்குப் '
                'பிறகு மீண்டும் தெளிக்கவும் — மொத்தம் இரண்டு முறை. புதிய அல்லது '
                'பரவும் புள்ளிகளுக்காக பழங்களைக் கண்காணிக்கவும்.',
            'si':
                'මැන්කොසෙබ් 45% WG, ලීටරයකට ආසන්න වශයෙන් ග්‍රෑම් 3.33 බැගින් '
                '(ලීටර් 16 ටැංකියකට ග්‍රෑම් 53.33) යොදන්න. දින 10 කට පසු නැවත '
                'යොදන්න — මුළු වාර දෙකකි. නව හෝ පැතිරෙන පැල්ලම් සඳහා ගෙඩි '
                'නිරීක්ෂණය කරන්න.',
          },
        ),
        // Thiophanate-methyl 70% WP — 0.625 g/L, 10 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(7, 3),
          image: TreatmentImages.chemAnthracnoseModerate,
          text: {
            'en':
                'Remove infected fruits and twigs. Apply thiophanate-methyl '
                '70% WP at 0.625 g/L (10 g per 16 L tank), every 7 days for '
                'three applications total. Improve airflow around the fruits.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் கிளைகளையும் அகற்றவும். '
                'தயோஃபனேட்-மெத்தில் 70% WP-ஐ லிட்டருக்கு 0.625 கிராம் (16 '
                'லிட்டர் தொட்டிக்கு 10 கிராம்) அளவில், 7 நாட்களுக்கு ஒருமுறை, '
                'மொத்தம் மூன்று முறை தெளிக்கவும். பழங்களைச் சுற்றி '
                'காற்றோட்டத்தை மேம்படுத்தவும்.',
            'si':
                'ආසාදිත ගෙඩි සහ අතු ඉවත් කරන්න. තයෝෆැනේට්-මෙතිල් 70% WP, '
                'ලීටරයකට ග්‍රෑම් 0.625 බැගින් (ලීටර් 16 ටැංකියකට ග්‍රෑම් 10) '
                'දින 7 කට වරක්, මුළු වාර තුනක් යොදන්න. ගෙඩි වටා වාතාශ්‍රය '
                'වැඩි දියුණු කරන්න.',
          },
        ),
        // Difenoconazole 25% EC — 1 ml/L, 16 ml / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(5, 3),
          image: TreatmentImages.chemAnthracnoseSevere,
          text: {
            'en':
                'Remove heavily affected and rotting fruits promptly. Apply '
                'difenoconazole 25% EC at 1 ml/L (16 ml per 16 L tank), every '
                '5 days for three applications total. Inspect nearby fruits '
                'for further infection.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட மற்றும் அழுகிய பழங்களை உடனடியாக '
                'அகற்றவும். டைஃபெனோகோனசோல் 25% EC-ஐ லிட்டருக்கு 1 மி.லி (16 '
                'லிட்டர் தொட்டிக்கு 16 மி.லி) அளவில், 5 நாட்களுக்கு ஒருமுறை, '
                'மொத்தம் மூன்று முறை தெளிக்கவும். அருகிலுள்ள பழங்களில் தொற்று '
                'பரவுகிறதா என சோதிக்கவும்.',
            'si':
                'දැඩි ලෙස බලපෑමට ලක් වූ සහ කුණු වූ ගෙඩි වහාම ඉවත් කරන්න. '
                'ඩයිෆෙනොකොනසෝල් 25% EC, ලීටරයකට මි.ලී. 1 බැගින් (ලීටර් 16 '
                'ටැංකියකට මි.ලී. 16) දින 5 කට වරක්, මුළු වාර තුනක් යොදන්න. '
                'අසල ගෙඩිවල තවදුරටත් ආසාදනය ඇත්දැයි පරීක්ෂා කරන්න.',
          },
        ),
      },
      'Bacterial_Blight': {
        // Streptomycin sulphate + copper oxychloride — 0.5 g + 2.5 g / L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(14, 2),
          image: TreatmentImages.chemBlightMild,
          text: {
            'en':
                'Remove infected fruits and disinfect pruning tools. The '
                'proposed schedule uses streptomycin sulphate 0.5 g/L + copper '
                'oxychloride 2.5 g/L (8 g + 40 g per 16 L tank), repeated '
                'after 14 days for two applications total.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களை அகற்றி, கத்தரிக்கும் கருவிகளைக் கிருமி '
                'நீக்கம் செய்யவும். பரிந்துரைக்கப்பட்ட அட்டவணை: '
                'ஸ்ட்ரெப்டோமைசின் சல்பேட் லிட்டருக்கு 0.5 கிராம் + காப்பர் '
                'ஆக்ஸிகுளோரைடு லிட்டருக்கு 2.5 கிராம் (16 லிட்டர் தொட்டிக்கு 8 '
                'கிராம் + 40 கிராம்), 14 நாட்களுக்குப் பிறகு மீண்டும் — மொத்தம் '
                'இரண்டு முறை.',
            'si':
                'ආසාදිත ගෙඩි ඉවත් කර කප්පාදු මෙවලම් විෂබීජහරණය කරන්න. යෝජිත '
                'කාලසටහන: ස්ට්‍රෙප්ටොමයිසින් සල්ෆේට් ලීටරයකට ග්‍රෑම් 0.5 + කොපර් '
                'ඔක්සික්ලෝරයිඩ් ලීටරයකට ග්‍රෑම් 2.5 (ලීටර් 16 ටැංකියකට ග්‍රෑම් '
                '8 + ග්‍රෑම් 40), දින 14 කට පසු නැවත — මුළු වාර දෙකකි.',
          },
        ),
        // Carbendazim 50% WP — 1 g/L, 16 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(7, 2),
          image: TreatmentImages.chemBlightModerate,
          text: {
            'en':
                'Clear infected fruits and affected branches. The proposed '
                'programme includes carbendazim 50% WP at 1 g/L (16 g per '
                '16 L tank), every 7 days for two applications total, as a '
                'fungicide component—not a stand-alone bacterial-blight '
                'treatment.',
            'ta':
                'பாதிக்கப்பட்ட பழங்களையும் கிளைகளையும் அகற்றவும். இந்த '
                'திட்டத்தில் கார்பென்டாசிம் 50% WP லிட்டருக்கு 1 கிராம் (16 '
                'லிட்டர் தொட்டிக்கு 16 கிராம்), 7 நாட்களுக்கு ஒருமுறை, மொத்தம் '
                'இரண்டு முறை சேர்க்கப்பட்டுள்ளது — இது பூஞ்சைக்கொல்லி பகுதி '
                'மட்டுமே, பாக்டீரியா கருகல் நோய்க்கான தனி சிகிச்சை அல்ல.',
            'si':
                'ආසාදිත ගෙඩි සහ බලපෑමට ලක් වූ අතු ඉවත් කරන්න. යෝජිත '
                'වැඩසටහනට කාබෙන්ඩසිම් 50% WP ලීටරයකට ග්‍රෑම් 1 (ලීටර් 16 '
                'ටැංකියකට ග්‍රෑම් 16), දින 7 කට වරක්, මුළු වාර දෙකක් ඇතුළත් '
                'වේ — මෙය දිලීර නාශක කොටසක් පමණි, බැක්ටීරියා අංගමාරයට තනි '
                'ප්‍රතිකාරයක් නොවේ.',
          },
        ),
        // Mancozeb 75% WP — 2 g/L, 32 g / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(5, 4),
          image: TreatmentImages.chemBlightSevere,
          text: {
            'en':
                'Remove heavily infected fruits and branches promptly. The '
                'proposed programme includes mancozeb 75% WP at 2 g/L (32 g '
                'per 16 L tank), every 5 days for four applications total. It '
                'must not replace the bacterial-blight treatment.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட பழங்களையும் கிளைகளையும் உடனடியாக '
                'அகற்றவும். இந்த திட்டத்தில் மான்கோசெப் 75% WP லிட்டருக்கு 2 '
                'கிராம் (16 லிட்டர் தொட்டிக்கு 32 கிராம்), 5 நாட்களுக்கு '
                'ஒருமுறை, மொத்தம் நான்கு முறை சேர்க்கப்பட்டுள்ளது. இது '
                'பாக்டீரியா கருகல் நோய்க்கான சிகிச்சைக்கு மாற்றாகாது.',
            'si':
                'දැඩි ලෙස ආසාදිත ගෙඩි සහ අතු වහාම ඉවත් කරන්න. යෝජිත '
                'වැඩසටහනට මැන්කොසෙබ් 75% WP ලීටරයකට ග්‍රෑම් 2 (ලීටර් 16 '
                'ටැංකියකට ග්‍රෑම් 32), දින 5 කට වරක්, මුළු වාර හතරක් ඇතුළත් '
                'වේ. මෙය බැක්ටීරියා අංගමාර ප්‍රතිකාරය වෙනුවට භාවිතා නොකළ '
                'යුතුය.',
          },
        ),
      },
      'Cercospora': {
        // Propiconazole 25% EC — 1 ml/L, 16 ml / 16 L
        Severity.mild: TreatmentPlan(
          schedule: TreatmentSchedule(15, 2),
          image: TreatmentImages.chemCercosporaMild,
          text: {
            'en':
                'Remove infected fallen leaves. Apply propiconazole 25% EC at '
                '1 ml/L (16 ml per 16 L tank). Repeat after 15 days for two '
                'applications total. Monitor leaves and fruits for new spots.',
            'ta':
                'விழுந்த பாதிக்கப்பட்ட இலைகளை அகற்றவும். புரோபிகோனசோல் 25% '
                'EC-ஐ லிட்டருக்கு 1 மி.லி (16 லிட்டர் தொட்டிக்கு 16 மி.லி) '
                'அளவில் தெளிக்கவும். 15 நாட்களுக்குப் பிறகு மீண்டும் '
                'தெளிக்கவும் — மொத்தம் இரண்டு முறை. இலைகளிலும் பழங்களிலும் '
                'புதிய புள்ளிகளைக் கண்காணிக்கவும்.',
            'si':
                'වැටුණු ආසාදිත කොළ ඉවත් කරන්න. ප්‍රොපිකොනසෝල් 25% EC, '
                'ලීටරයකට මි.ලී. 1 බැගින් (ලීටර් 16 ටැංකියකට මි.ලී. 16) '
                'යොදන්න. දින 15 කට පසු නැවත යොදන්න — මුළු වාර දෙකකි. කොළ සහ '
                'ගෙඩිවල නව පැල්ලම් නිරීක්ෂණය කරන්න.',
          },
        ),
        // Chlorothalonil 75% WP — 2.5 g/L, 40 g / 16 L
        Severity.moderate: TreatmentPlan(
          schedule: TreatmentSchedule(10, 3),
          image: TreatmentImages.chemCercosporaModerate,
          text: {
            'en':
                'Clear spotted fruits and prune infected twigs. Apply '
                'chlorothalonil 75% WP at 2.5 g/L (40 g per 16 L tank). Repeat '
                'every 10 days for three applications total. Avoid overhead '
                'irrigation to reduce leaf wetness.',
            'ta':
                'புள்ளிகள் உள்ள பழங்களை அகற்றி, பாதிக்கப்பட்ட கிளைகளைக் '
                'கத்தரிக்கவும். குளோரோதலோனில் 75% WP-ஐ லிட்டருக்கு 2.5 கிராம் '
                '(16 லிட்டர் தொட்டிக்கு 40 கிராம்) அளவில் தெளிக்கவும். 10 '
                'நாட்களுக்கு ஒருமுறை, மொத்தம் மூன்று முறை தெளிக்கவும். இலை '
                'ஈரத்தைக் குறைக்க மேலிருந்து நீர் பாய்ச்சுவதைத் தவிர்க்கவும்.',
            'si':
                'පැල්ලම් සහිත ගෙඩි ඉවත් කර ආසාදිත අතු කප්පාදු කරන්න. '
                'ක්ලෝරොතැලොනිල් 75% WP, ලීටරයකට ග්‍රෑම් 2.5 බැගින් (ලීටර් 16 '
                'ටැංකියකට ග්‍රෑම් 40) යොදන්න. දින 10 කට වරක්, මුළු වාර තුනක් '
                'යොදන්න. කොළ තෙත්බව අඩු කිරීමට ඉහළින් ජලය ඉසීම වළක්වන්න.',
          },
        ),
        // Carbendazim 50% WP — 1 g/L, 16 g / 16 L
        Severity.severe: TreatmentPlan(
          schedule: TreatmentSchedule(7, 3),
          image: TreatmentImages.chemCercosporaSevere,
          text: {
            'en':
                'Remove heavily affected fruits and infected leaves. Apply '
                'carbendazim 50% WP at 1 g/L (16 g per 16 L tank). Repeat '
                'every 7 days for three applications total. Check nearby trees '
                'for further infection.',
            'ta':
                'கடுமையாக பாதிக்கப்பட்ட பழங்களையும் பாதிக்கப்பட்ட இலைகளையும் '
                'அகற்றவும். கார்பென்டாசிம் 50% WP-ஐ லிட்டருக்கு 1 கிராம் (16 '
                'லிட்டர் தொட்டிக்கு 16 கிராம்) அளவில் தெளிக்கவும். 7 '
                'நாட்களுக்கு ஒருமுறை, மொத்தம் மூன்று முறை தெளிக்கவும். '
                'அருகிலுள்ள மரங்களில் தொற்று பரவுகிறதா என சோதிக்கவும்.',
            'si':
                'දැඩි ලෙස බලපෑමට ලක් වූ ගෙඩි සහ ආසාදිත කොළ ඉවත් කරන්න. '
                'කාබෙන්ඩසිම් 50% WP, ලීටරයකට ග්‍රෑම් 1 බැගින් (ලීටර් 16 '
                'ටැංකියකට ග්‍රෑම් 16) යොදන්න. දින 7 කට වරක්, මුළු වාර තුනක් '
                'යොදන්න. අසල ගස්වල තවදුරටත් ආසාදනය ඇත්දැයි පරීක්ෂා කරන්න.',
          },
        ),
      },
    },
  };

  // ═════════════════════════════════════════════════════════════════════════
  //  C. PREVENTION TIPS — same for Organic and Chemical.
  //     Keep the SAME ORDER in en / ta / si (tips are picked by position).
  // ═════════════════════════════════════════════════════════════════════════
  static const Map<String, Map<String, List<String>>> _preventionTips = {
    'en': {
      'Alternaria': [
        'Remove dried fruits left on trees before the next flowering season.',
        'Collect infected and rotting fruits from the orchard floor.',
        'Protect fruits from punctures caused by thorns, insects and birds.',
        'Check flowers and young fruits closely after rain.',
        'Separate unusually light, discoloured or shrivelled fruits during '
            'harvest sorting.',
        'Do not assume a healthy-looking skin means the fruit is free from '
            'internal rot.',
      ],
      'Anthracnose': [
        'Prune crowded branches during dry weather so leaves and fruits dry '
            'faster.',
        'Leave enough space between trees to prevent dense, overlapping '
            'canopies.',
        'Avoid irrigation that wets flowers, leaves and fruits.',
        'Remove infected leaves, dead twigs and fruits with sunken spots.',
        'Check flowers and developing fruits closely during prolonged wet '
            'weather.',
        'Disinfect pruning tools after removing diseased growth.',
      ],
      'Bacterial_Blight': [
        'Use disease-free seedlings and cuttings for planting.',
        'Never take planting cuttings from infected trees.',
        'Disinfect pruning tools between plants and after cutting infected '
            'branches.',
        'Avoid pruning or handling plants while they are wet.',
        'Avoid sprinkler irrigation that splashes water between trees.',
        'Remove infected branches and fruits during dry weather.',
        'Work on healthy trees first, infected trees last.',
      ],
      'Cercospora': [
        'Remove old infected fallen leaves before the rainy season.',
        'Collect fruits with spreading dark spots and remove them from the '
            'orchard.',
        'Prune twigs with raised black lesions or dieback.',
        'Keep drains clear to prevent waterlogged soil.',
        'Direct irrigation to the root zone to reduce prolonged leaf wetness.',
        'Check both leaves and fruits during warm, rainy weather.',
        'Watch for yellow leaves and early leaf fall.',
      ],
    },
    'ta': {
      'Alternaria': [
        'அடுத்த பூக்கும் பருவத்திற்கு முன் மரங்களில் உள்ள காய்ந்த பழங்களை '
            'அகற்றவும்.',
        'தோட்டத் தரையில் உள்ள பாதிக்கப்பட்ட மற்றும் அழுகிய பழங்களைச் '
            'சேகரிக்கவும்.',
        'முட்கள், பூச்சிகள் மற்றும் பறவைகளால் பழங்களில் ஏற்படும் '
            'துளைகளிலிருந்து பாதுகாக்கவும்.',
        'மழைக்குப் பிறகு பூக்களையும் இளம் பழங்களையும் கவனமாகச் சோதிக்கவும்.',
        'அறுவடை வகைப்படுத்தலின் போது வழக்கத்திற்கு மாறாக எடை குறைந்த, நிறம் '
            'மாறிய அல்லது சுருங்கிய பழங்களைப் பிரிக்கவும்.',
        'தோல் ஆரோக்கியமாகத் தெரிந்தாலும், பழம் உள்ளே அழுகாமல் இருக்கும் என்று '
            'கருத வேண்டாம்.',
      ],
      'Anthracnose': [
        'இலைகளும் பழங்களும் விரைவாக உலர, வறண்ட காலநிலையில் நெருக்கமான '
            'கிளைகளைக் கத்தரிக்கவும்.',
        'அடர்த்தியான, ஒன்றோடொன்று மூடும் மரக்கூரையைத் தவிர்க்க மரங்களுக்கு '
            'இடையே போதுமான இடைவெளி விடவும்.',
        'பூக்கள், இலைகள் மற்றும் பழங்களை நனைக்கும் நீர்ப்பாசனத்தைத் '
            'தவிர்க்கவும்.',
        'பாதிக்கப்பட்ட இலைகள், காய்ந்த கிளைகள் மற்றும் குழிந்த புள்ளிகள் உள்ள '
            'பழங்களை அகற்றவும்.',
        'நீண்ட ஈரமான காலநிலையில் பூக்களையும் வளரும் பழங்களையும் கவனமாகச் '
            'சோதிக்கவும்.',
        'நோயுற்ற பகுதிகளை அகற்றிய பின் கத்தரிக்கும் கருவிகளைக் கிருமி நீக்கம் '
            'செய்யவும்.',
      ],
      'Bacterial_Blight': [
        'நடவுக்கு நோயில்லாத நாற்றுகளையும் தண்டுக் குச்சிகளையும் '
            'பயன்படுத்தவும்.',
        'பாதிக்கப்பட்ட மரங்களிலிருந்து நடவுக் குச்சிகளை ஒருபோதும் எடுக்க '
            'வேண்டாம்.',
        'ஒவ்வொரு மரத்திற்கும் இடையிலும், பாதிக்கப்பட்ட கிளைகளை வெட்டிய '
            'பின்னும் கத்தரிக்கும் கருவிகளைக் கிருமி நீக்கம் செய்யவும்.',
        'செடிகள் ஈரமாக இருக்கும்போது கத்தரிப்பதையோ கையாள்வதையோ '
            'தவிர்க்கவும்.',
        'மரங்களுக்கு இடையே நீரைத் தெறிக்கச் செய்யும் தெளிப்பு நீர்ப்பாசனத்தைத் '
            'தவிர்க்கவும்.',
        'வறண்ட காலநிலையில் பாதிக்கப்பட்ட கிளைகளையும் பழங்களையும் அகற்றவும்.',
        'முதலில் ஆரோக்கியமான மரங்களிலும், கடைசியாக பாதிக்கப்பட்ட மரங்களிலும் '
            'வேலை செய்யவும்.',
      ],
      'Cercospora': [
        'மழைக்காலத்திற்கு முன் விழுந்த பழைய பாதிக்கப்பட்ட இலைகளை அகற்றவும்.',
        'பரவும் கரும்புள்ளிகள் உள்ள பழங்களைச் சேகரித்து தோட்டத்திலிருந்து '
            'அகற்றவும்.',
        'உயர்ந்த கரும் புண்கள் அல்லது நுனி கருகல் உள்ள கிளைகளைக் '
            'கத்தரிக்கவும்.',
        'மண்ணில் நீர் தேங்காமல் இருக்க வடிகால்களைச் சுத்தமாக '
            'வைத்திருக்கவும்.',
        'இலைகள் நீண்ட நேரம் ஈரமாக இருப்பதைக் குறைக்க, நீரை வேர்ப் பகுதிக்கு '
            'மட்டும் பாய்ச்சவும்.',
        'வெப்பமான, மழைக்காலத்தில் இலைகளையும் பழங்களையும் சோதிக்கவும்.',
        'மஞ்சள் இலைகள் மற்றும் முன்கூட்டிய இலை உதிர்வைக் கவனிக்கவும்.',
      ],
    },
    'si': {
      'Alternaria': [
        'ඊළඟ මල් පිපෙන කාලයට පෙර ගස්වල ඉතිරි වූ වියළි ගෙඩි ඉවත් කරන්න.',
        'වත්තේ බිම ඇති ආසාදිත සහ කුණු වූ ගෙඩි එකතු කරන්න.',
        'කටු, කෘමීන් සහ කුරුල්ලන් නිසා ගෙඩිවල ඇතිවන සිදුරුවලින් ආරක්ෂා '
            'කරන්න.',
        'වැස්සෙන් පසු මල් සහ ළපටි ගෙඩි හොඳින් පරීක්ෂා කරන්න.',
        'අස්වනු වර්ග කිරීමේදී අසාමාන්‍ය ලෙස සැහැල්ලු, වර්ණය වෙනස් වූ හෝ '
            'හැකිළුණු ගෙඩි වෙන් කරන්න.',
        'පොත්ත නිරෝගී ලෙස පෙනුනත් ගෙඩිය ඇතුළත කුණු වී නැතැයි නොසිතන්න.',
      ],
      'Anthracnose': [
        'කොළ සහ ගෙඩි ඉක්මනින් වියළීමට, වියළි කාලගුණයේදී තදබද අතු කප්පාදු '
            'කරන්න.',
        'ඝන, එකිනෙක වැසෙන ගස් වියන් වළක්වා ගැනීමට ගස් අතර ප්‍රමාණවත් ඉඩ '
            'තබන්න.',
        'මල්, කොළ සහ ගෙඩි තෙත් කරන ජල සම්පාදනය වළක්වන්න.',
        'ආසාදිත කොළ, මැරුණු අතු සහ ගිලුණු පැල්ලම් සහිත ගෙඩි ඉවත් කරන්න.',
        'දිගු තෙත් කාලගුණයේදී මල් සහ වැඩෙන ගෙඩි හොඳින් පරීක්ෂා කරන්න.',
        'රෝගී කොටස් ඉවත් කිරීමෙන් පසු කප්පාදු මෙවලම් විෂබීජහරණය කරන්න.',
      ],
      'Bacterial_Blight': [
        'සිටුවීම සඳහා රෝග රහිත පැළ සහ කැබලි භාවිතා කරන්න.',
        'ආසාදිත ගස්වලින් කිසි විටෙක සිටුවීමට කැබලි නොගන්න.',
        'ගස් අතරේ සහ ආසාදිත අතු කැපීමෙන් පසු කප්පාදු මෙවලම් විෂබීජහරණය '
            'කරන්න.',
        'ශාක තෙත්ව ඇති විට කප්පාදු කිරීම හෝ හැසිරවීම වළක්වන්න.',
        'ගස් අතර ජලය විසිරෙන ස්ප්‍රින්ක්ලර් ජල සම්පාදනය වළක්වන්න.',
        'වියළි කාලගුණයේදී ආසාදිත අතු සහ ගෙඩි ඉවත් කරන්න.',
        'පළමුව නිරෝගී ගස්වල ද, අවසානයේ ආසාදිත ගස්වල ද වැඩ කරන්න.',
      ],
      'Cercospora': [
        'වැසි සමයට පෙර වැටුණු පැරණි ආසාදිත කොළ ඉවත් කරන්න.',
        'පැතිරෙන කළු පැල්ලම් සහිත ගෙඩි එකතු කර වත්තෙන් ඉවත් කරන්න.',
        'උස් වූ කළු තුවාල හෝ අග මැරීම සහිත අතු කප්පාදු කරන්න.',
        'පස ජලයෙන් යට වීම වැළැක්වීමට කාණු පිරිසිදුව තබා ගන්න.',
        'කොළ දිගු වේලාවක් තෙත්ව තිබීම අඩු කිරීමට, ජලය මුල් කලාපයට පමණක් '
            'යොමු කරන්න.',
        'උණුසුම්, වැසි සහිත කාලගුණයේදී කොළ සහ ගෙඩි යන දෙකම පරීක්ෂා කරන්න.',
        'කහ පැහැ කොළ සහ කලින් කොළ හැලීම ගැන අවධානයෙන් සිටින්න.',
      ],
    },
  };
}
