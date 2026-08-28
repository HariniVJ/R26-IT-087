// lib/localization/app_strings.dart
class AppStrings {
  static String currentLang = "en"; // "en" or "ta"

  static const Map<String, Map<String, String>> _strings = {
    "en": {
      "quality_grading": "Quality Grading",
      "tap_to_upload": "Tap to Upload Fruit Image",
      "analyse_quality": "Analyse Quality",
      "detected_result": "Detected Result",
      "recommendation": "Recommendation",
      "scan_another": "Scan Another Fruit",
      "not_pomegranate": "Not recognized as a pomegranate",
      "enter_weight": "Enter fruit weight (grams)",
    },
    "ta": {
      "quality_grading": "தர வகைப்படுத்தல்",
      "tap_to_upload": "பழத்தின் படத்தை பதிவேற்றவும்",
      "analyse_quality": "தரத்தை பகுப்பாய்வு செய்",
      "detected_result": "கண்டறியப்பட்ட முடிவு",
      "recommendation": "பரிந்துரை",
      "scan_another": "மற்றொரு பழத்தை ஸ்கேன் செய்",
      "not_pomegranate": "மாதுளை பழமாக அடையாளம் காணப்படவில்லை",
      "enter_weight": "பழத்தின் எடையை உள்ளிடவும் (கிராம்)",
    },
  };

  static String get(String key) => _strings[currentLang]?[key] ?? key;
}
