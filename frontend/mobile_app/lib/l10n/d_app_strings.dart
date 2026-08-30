import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  tamil('ta', 'தமிழ்'),
  sinhala('si', 'සිංහල');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class LanguageController extends ChangeNotifier {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;

  static const _prefKey = 'app_language_code';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _language = AppLanguage.fromCode(saved);
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.code);
    notifyListeners();
  }

  /// Shortcut: LanguageController.instance.t('key')
  String t(String key) => AppStrings.translate(key, _language);
}

class AppStrings {
  AppStrings._();

  static String translate(String key, AppLanguage lang) {
    return _values[lang.code]?[key] ?? _values['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app_name': 'Pomegranate Care',
      'dashboard_title': 'Akaran Farm',
      'start_detection': 'Start Detection',
      'analyze_subtitle': 'Analyze fruit',
      'history': 'History',
      'history_subtitle': 'View past results',
      'capture_photo': 'Capture Photo',
      'choose_gallery': 'Choose from Gallery',
      'analyze_image': 'Analyze Image',
      'analyzing': 'Analyzing Image...',
      'detection_result': 'Detection Result',
      'confidence_score': 'Confidence Score',
      'view_severity': 'View Severity Analysis',
      'view_treatment': 'View Treatment Options',
      'recommended_treatment': 'Recommended Treatment',
      'prevention': 'Prevention',
      'settings_language': 'Language',
      'not_pomegranate':
          'This does not look like a pomegranate fruit. Please capture a clear photo.',
      'sign_in_required': 'You must be signed in to run detection.',
      'follow_up_due': 'Follow-up due',
      'follow_up_completed': 'Follow-up completed',
      'mark_follow_up_done': 'Mark follow-up as done',
    },
    'ta': {
      'app_name': 'மாதுளை பராமரிப்பு',
      'dashboard_title': 'அகரன் பண்ணை',
      'start_detection': 'கண்டறிதலைத் தொடங்கு',
      'analyze_subtitle': 'பழத்தை பகுப்பாய்வு செய்',
      'history': 'வரலாறு',
      'history_subtitle': 'முந்தைய முடிவுகளை பார்க்க',
      'capture_photo': 'புகைப்படம் எடு',
      'choose_gallery': 'கேலரியில் இருந்து தேர்வு செய்',
      'analyze_image': 'படத்தை பகுப்பாய்வு செய்',
      'analyzing': 'பகுப்பாய்வு செய்யப்படுகிறது...',
      'detection_result': 'கண்டறிதல் முடிவு',
      'confidence_score': 'நம்பகத்தன்மை மதிப்பெண்',
      'view_severity': 'தீவிரத்தன்மை பகுப்பாய்வைக் காண்க',
      'view_treatment': 'சிகிச்சை விருப்பங்களைக் காண்க',
      'recommended_treatment': 'பரிந்துரைக்கப்பட்ட சிகிச்சை',
      'prevention': 'தடுப்பு',
      'settings_language': 'மொழி',
      'not_pomegranate':
          'இது மாதுளை பழம் போல் தெரியவில்லை. தெளிவான புகைப்படத்தை எடுக்கவும்.',
      'sign_in_required': 'கண்டறிதலை இயக்க நீங்கள் உள்நுழைந்திருக்க வேண்டும்.',
      'follow_up_due': 'பின்தொடர்தல் நிலுவையில்',
      'follow_up_completed': 'பின்தொடர்தல் முடிந்தது',
      'mark_follow_up_done': 'பின்தொடர்தலை முடிந்ததாகக் குறிக்கவும்',
    },
    'si': {
      'app_name': 'මාදුළු රැකවරණය',
      'dashboard_title': 'අකරන් ගොවිපොළ',
      'start_detection': 'හඳුනාගැනීම ආරම්භ කරන්න',
      'analyze_subtitle': 'ගෙඩිය විශ්ලේෂණය කරන්න',
      'history': 'ඉතිහාසය',
      'history_subtitle': 'පෙර ප්‍රතිඵල බලන්න',
      'capture_photo': 'ඡායාරූපය ගන්න',
      'choose_gallery': 'ගැලරියෙන් තෝරන්න',
      'analyze_image': 'රූපය විශ්ලේෂණය කරන්න',
      'analyzing': 'විශ්ලේෂණය කරමින්...',
      'detection_result': 'හඳුනාගැනීමේ ප්‍රතිඵලය',
      'confidence_score': 'විශ්වාසනීයත්ව ලකුණු',
      'view_severity': 'තීව්‍රතා විශ්ලේෂණය බලන්න',
      'view_treatment': 'ප්‍රතිකාර විකල්ප බලන්න',
      'recommended_treatment': 'නිර්දේශිත ප්‍රතිකාරය',
      'prevention': 'වැළැක්වීම',
      'settings_language': 'භාෂාව',
      'not_pomegranate':
          'මෙය මාදුළු ගෙඩියක් ලෙස පෙනෙන්නේ නැත. පැහැදිලි ඡායාරූපයක් ගන්න.',
      'sign_in_required': 'හඳුනාගැනීම ක්‍රියාත්මක කිරීමට ඔබ පිවිසිය යුතුය.',
      'follow_up_due': 'පසු විපරම් කල් ඉකුත්',
      'follow_up_completed': 'පසු විපරම සම්පූර්ණයි',
      'mark_follow_up_done': 'පසු විපරම සම්පූර්ණ ලෙස සලකුණු කරන්න',
    },
  };
}
