import 'package:flutter/foundation.dart';

// The app-wide language (Profile page + bottom nav bar) lives here.
// The disease module now FOLLOWS it, so there is only ONE language setting.
import 'app_strings.dart' as app;

// ═══════════════════════════════════════════════════════════════════════════
//  ALL TEXT FOR THE DISEASE MODULE — 3 LANGUAGES (English / Tamil / Sinhala)
//  Add a key to all three maps. Missing keys fall back to English.
//  Treatments & chemicals are NOT here — they are in treatment_data.dart.
//
//  LANGUAGE: this file no longer stores its own language. It reads the
//  app-wide LanguageController (l10n/app_strings.dart). Changing the
//  language on the Profile page changes the disease screens, treatment
//  data and prevention tips too.
// ═══════════════════════════════════════════════════════════════════════════

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

/// Disease-module view of the ONE app language.
/// Same API as before (language / setLanguage / load / t), so no disease
/// screen or service has to change.
class LanguageController extends ChangeNotifier {
  LanguageController._() {
    // Rebuild disease screens whenever the Profile page changes the language.
    app.LanguageController.instance.addListener(notifyListeners);
  }
  static final LanguageController instance = LanguageController._();

  /// Current app language (read from the app-wide controller).
  AppLanguage get language {
    switch (app.LanguageController.instance.lang) {
      case app.AppLang.ta:
        return AppLanguage.tamil;
      case app.AppLang.si:
        return AppLanguage.sinhala;
      default:
        return AppLanguage.english;
    }
  }

  /// Kept for old calls — the app-wide controller already loads the
  /// saved language, so nothing extra is needed here.
  Future<void> load() async => notifyListeners();

  /// Changes the language for the WHOLE app.
  Future<void> setLanguage(AppLanguage lang) async {
    switch (lang) {
      case AppLanguage.tamil:
        app.LanguageController.instance.setLang(app.AppLang.ta);
      case AppLanguage.sinhala:
        app.LanguageController.instance.setLang(app.AppLang.si);
      case AppLanguage.english:
        app.LanguageController.instance.setLang(app.AppLang.en);
    }
  }

  /// Shortcut: LanguageController.instance.t('key')
  String t(String key) => AppStrings.translate(key, language);

  /// "Bacterial_Blight" → translated disease name.
  String disease(String name) =>
      _orFallback('disease_$name', name.replaceAll('_', ' '));

  /// "Mild" / "Moderate" / "Severe" / "Healthy" → translated level.
  String severity(String level) => _orFallback('severity_$level', level);

  String _orFallback(String key, String fallback) {
    final value = t(key);
    return value == key ? fallback : value;
  }
}

/// Disease-module text helper (named `dt` so it never clashes with the
/// app-wide `t()` from app_strings.dart).
///   Text(dt('detection_result'))
String dt(String key) => LanguageController.instance.t(key);

/// Text with values:  dtf('days_ago', {'n': '3'})  →  "3 days ago"
String dtf(String key, Map<String, String> vars) {
  var value = dt(key);
  vars.forEach((name, v) => value = value.replaceAll('{$name}', v));
  return value;
}

/// Today / Yesterday / 3 days ago / 12/10/2026 — translated.
String dRelativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays == 0) return dt('today');
  if (diff.inDays == 1) return dt('yesterday');
  if (diff.inDays < 7) return dtf('days_ago', {'n': '${diff.inDays}'});
  return '${date.day}/${date.month}/${date.year}';
}

/// "14 Oct 2026" with translated month names.
String dShortDate(DateTime d) {
  final months = dt('months').split(',');
  final m = months.length == 12 ? months[d.month - 1] : '${d.month}';
  return '${d.day} $m ${d.year}';
}

class AppStrings {
  AppStrings._();

  static String translate(String key, AppLanguage lang) {
    return _values[lang.code]?[key] ?? _values['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _values = {
    // ───────────────────────────── ENGLISH ─────────────────────────────
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
      // NEW — honest confidence / rejection / offline
      'no_fruit_detected':
          'No pomegranate fruit detected. Capture a clear photo with the fruit in the centre.',
      'result_uncertain': 'Result uncertain',
      'second_possibility': 'Second possibility',
      'severity_not_applicable': 'Not applicable (healthy fruit)',
      'warn_uncertain':
          'Not confident — retake the photo from another angle or consult an expert.',
      'warn_healthy_but_lesions':
          'Predicted healthy, but some affected area was found — please have it checked.',
      'warn_no_lesion_segmented':
          'Affected area could not be measured — severity may be shown lower than actual.',
      'warn_multiple_fruits':
          'Several fruits found — only the largest fruit was analysed.',
      'uncertain_treatment':
          'The result is uncertain, so no treatment is recommended. Retake a clear photo or consult an agriculture officer.',
      'saved_offline': 'Saved on phone — will sync when online',
      // ── Result screen ──
      'confidence_label': 'Confidence',
      'severity_label': 'Severity',
      'no_disease': 'No Disease',
      'severity_Mild': 'Mild',
      'severity_Moderate': 'Moderate',
      'severity_Severe': 'Severe',
      'severity_Healthy': 'Healthy',
      'disease_Alternaria': 'Alternaria',
      'disease_Anthracnose': 'Anthracnose',
      'disease_Bacterial_Blight': 'Bacterial Blight',
      'disease_Cercospora': 'Cercospora',
      'disease_Healthy': 'Healthy',
      'healthy_fruit': 'Healthy Fruit',
      'note': 'Note',
      'healthy_no_action':
          'No disease detected. Continue regular care and monitoring.',
      'treatment_options': 'Treatment Options',
      'treatment_options_subtitle':
          'Choose a treatment approach that fits your farm',
      'prevention_tips': 'Prevention Tips',
      'proceed_to_reminder': 'Proceed to Reminder',
      'back_to_home': 'Back to Home',
      'organic': 'Organic',
      'chemical': 'Chemical',
      // ── Detection home / history / detail ──
      'step_quality': 'Checking image quality',
      'step_find': 'Finding the pomegranate',
      'step_validate': 'Validating pomegranate',
      'step_identify': 'Identifying disease',
      'step_severity': 'Calculating severity',
      'analysis_timeout_title': 'Analysis Timeout',
      'analysis_timeout_msg': 'The analysis took too long. Please try again.',
      'analysis_failed': 'Analysis Failed',
      'ok': 'OK',
      'home_label': 'Home',
      'disease_detection': 'Disease Detection',
      'detection_history': 'Detection History',
      'checking_image': 'Checking image...',
      'analyzing_short': 'Analyzing...',
      'ready_to_scan': 'Ready to scan',
      'scanner': 'SCANNER',
      'tap_to_upload': 'Tap to upload',
      'ready_to_analyze': 'Ready to Analyze',
      'scan_your_pomegranate': 'Scan Your Pomegranate',
      'ready_hint': 'Check the preview, then tap "Analyze Image"',
      'scan_hint':
          'Position the fruit in frame and capture,\nor tap the frame to upload from gallery',
      'original': 'Original',
      'preprocessed': 'Preprocessed',
      'analyzing_your_image': 'Analyzing your image',
      'capture': 'Capture',
      'retake': 'Retake',
      'gallery': 'Gallery',
      'five_classes': '5 Classes',
      'disease_types': 'Disease types',
      'auto_analysis': 'Auto analysis',
      'treatment': 'Treatment',
      'care_guide': 'Care guide',
      'recent_detections': 'Recent Detections',
      'view_all': 'View all',
      'no_detections': 'No detections yet',
      'invalid_image': 'Invalid Image',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'days_ago': '{n} days ago',
      'months': 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec',
      'selected_count': '{n} selected',
      'select_items': 'Select items',
      'delete_selected': 'Delete selected',
      'filter_all': 'All',
      'delete_one_title': 'Delete this record?',
      'delete_one_msg':
          'This detection record for "{name}" will be permanently deleted. This cannot be undone.',
      'record_deleted': 'Record deleted successfully',
      'delete_failed': 'Delete failed: {error}',
      'delete_many_title': 'Delete {n} record(s)?',
      'delete_many_msg':
          'These detection records will be permanently deleted. This cannot be undone.',
      'records_deleted': '{n} record(s) deleted',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'select_all': 'Select all',
      'total_scans': 'Total Scans',
      'healthy_label': 'Healthy',
      'diseased': 'Diseased',
      'no_detections_hint':
          'Your scanned pomegranates will show up here\nonce you run a detection.',
      'no_results_for': 'No results for "{name}"',
      'try_other_filter': 'Try a different filter above.',
      'setting_up': 'Setting things up…',
      'access_issue': 'Access issue',
      'could_not_load': 'Could not load history',
      'index_building_msg':
          'The database index is still building. This usually takes a minute — pull down to refresh shortly.',
      'permission_msg':
          'You may need to sign in again, or the database permissions need to be updated.',
      'retry': 'Retry',
      'detection_detail': 'Detection Detail',
      'disease_label': 'Disease',
      'detected': 'Detected',
      'follow_up_schedule': 'Follow-up Schedule',
      'treatment_plan': 'Treatment Plan',
      'organic_treatment': 'Organic Treatment',
      'chemical_treatment': 'Chemical Treatment',
      'days': 'days',
      'times': 'times',
      'apply_every': 'Apply every',
      'applications': 'Applications',
      'total_period': 'Total period',
      'next_follow_up': 'Next follow-up',
      // ── Reminder screen ──
      'follow_up_reminder': 'Follow-up Reminder',
      'reapply_after': 'Re-apply treatment after',
      'n_days': '{n} Days',
      'n_days_lower': '{n} days',
      'n_times': '{n} times',
      'reminder_set_title': 'Reminder Set!',
      'reminder_set_msg':
          'We\'ll notify you on {date} to check your pomegranate again.',
      'continue_btn': 'Continue',
      'reminder_set_btn': 'Reminder Set',
      'set_reminder': 'Set Reminder',
      'skip_for_now': 'Skip for Now',
      'reminder_scheduled': 'Reminder scheduled',
      'reminder_failed': 'Could not set reminder: {error}',
      'disease_with_name': 'Disease: {name}',
      'number_of_applications': 'Number of applications',
      'total_treatment_period': 'Total treatment period',
    },

    // ───────────────────────────── TAMIL ─────────────────────────────
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
      // NEW
      'no_fruit_detected':
          'மாதுளை பழம் கண்டறியப்படவில்லை. பழம் நடுவில் தெளிவாகத் தெரியும்படி படம் எடுக்கவும்.',
      'result_uncertain': 'முடிவு உறுதியில்லை',
      'second_possibility': 'இரண்டாவது வாய்ப்பு',
      'severity_not_applicable': 'பொருந்தாது (ஆரோக்கியமான பழம்)',
      'warn_uncertain':
          'உறுதியில்லை — வேறு கோணத்தில் மீண்டும் படம் எடுக்கவும் அல்லது நிபுணரை அணுகவும்.',
      'warn_healthy_but_lesions':
          'ஆரோக்கியம் எனக் கணிக்கப்பட்டது, ஆனால் சில பாதிப்புப் பகுதி தெரிகிறது — சரிபார்க்கவும்.',
      'warn_no_lesion_segmented':
          'பாதிப்புப் பகுதியை அளக்க முடியவில்லை — தீவிரத்தன்மை குறைவாகக் காட்டப்படலாம்.',
      'warn_multiple_fruits':
          'பல பழங்கள் உள்ளன — மிகப் பெரிய பழம் மட்டும் பகுப்பாய்வு செய்யப்பட்டது.',
      'uncertain_treatment':
          'முடிவு உறுதியில்லாததால் சிகிச்சை பரிந்துரைக்கப்படவில்லை. தெளிவான படம் மீண்டும் எடுக்கவும் அல்லது விவசாய அலுவலரை அணுகவும்.',
      'saved_offline':
          'தொலைபேசியில் சேமிக்கப்பட்டது — இணையம் கிடைத்ததும் ஒத்திசைக்கப்படும்',
      // ── Result screen ──
      'confidence_label': 'நம்பகத்தன்மை',
      'severity_label': 'தீவிரத்தன்மை',
      'no_disease': 'நோய் இல்லை',
      'severity_Mild': 'லேசானது',
      'severity_Moderate': 'மிதமானது',
      'severity_Severe': 'கடுமையானது',
      'severity_Healthy': 'ஆரோக்கியமானது',
      'disease_Alternaria': 'ஆல்டர்நேரியா',
      'disease_Anthracnose': 'ஆந்த்ராக்னோஸ்',
      'disease_Bacterial_Blight': 'பாக்டீரியா கருகல்',
      'disease_Cercospora': 'செர்கோஸ்போரா',
      'disease_Healthy': 'ஆரோக்கியமானது',
      'healthy_fruit': 'ஆரோக்கியமான பழம்',
      'note': 'குறிப்பு',
      'healthy_no_action':
          'நோய் எதுவும் கண்டறியப்படவில்லை. வழக்கமான பராமரிப்பையும் கண்காணிப்பையும் தொடரவும்.',
      'treatment_options': 'சிகிச்சை விருப்பங்கள்',
      'treatment_options_subtitle':
          'உங்கள் பண்ணைக்கு ஏற்ற சிகிச்சை முறையைத் தேர்வு செய்யவும்',
      'prevention_tips': 'தடுப்பு குறிப்புகள்',
      'proceed_to_reminder': 'நினைவூட்டலுக்குச் செல்',
      'back_to_home': 'முகப்புக்குத் திரும்பு',
      'organic': 'இயற்கை',
      'chemical': 'இரசாயனம்',
      // ── Detection home / history / detail ──
      'step_quality': 'படத்தின் தரத்தைச் சரிபார்க்கிறது',
      'step_find': 'மாதுளையைக் கண்டறிகிறது',
      'step_validate': 'மாதுளையா என உறுதிசெய்கிறது',
      'step_identify': 'நோயைக் கண்டறிகிறது',
      'step_severity': 'தீவிரத்தன்மையைக் கணக்கிடுகிறது',
      'analysis_timeout_title': 'பகுப்பாய்வு நேரம் முடிந்தது',
      'analysis_timeout_msg':
          'பகுப்பாய்வுக்கு அதிக நேரம் ஆனது. மீண்டும் முயலவும்.',
      'analysis_failed': 'பகுப்பாய்வு தோல்வியடைந்தது',
      'ok': 'சரி',
      'home_label': 'முகப்பு',
      'disease_detection': 'நோய் கண்டறிதல்',
      'detection_history': 'கண்டறிதல் வரலாறு',
      'checking_image': 'படம் சரிபார்க்கப்படுகிறது...',
      'analyzing_short': 'பகுப்பாய்வு செய்கிறது...',
      'ready_to_scan': 'ஸ்கேன் செய்யத் தயார்',
      'scanner': 'ஸ்கேனர்',
      'tap_to_upload': 'பதிவேற்றத் தட்டவும்',
      'ready_to_analyze': 'பகுப்பாய்வுக்குத் தயார்',
      'scan_your_pomegranate': 'உங்கள் மாதுளையை ஸ்கேன் செய்யவும்',
      'ready_hint':
          'முன்னோட்டத்தைச் சரிபார்த்து, "படத்தை பகுப்பாய்வு செய்" என்பதைத் தட்டவும்',
      'scan_hint':
          'பழத்தை சட்டகத்துக்குள் வைத்து படம் எடுக்கவும்,\nஅல்லது கேலரியிலிருந்து பதிவேற்ற சட்டகத்தைத் தட்டவும்',
      'original': 'அசல்',
      'preprocessed': 'முன்செயலாக்கம்',
      'analyzing_your_image': 'உங்கள் படம் பகுப்பாய்வு செய்யப்படுகிறது',
      'capture': 'படம் எடு',
      'retake': 'மீண்டும் எடு',
      'gallery': 'கேலரி',
      'five_classes': '5 வகைகள்',
      'disease_types': 'நோய் வகைகள்',
      'auto_analysis': 'தானியங்கி பகுப்பாய்வு',
      'treatment': 'சிகிச்சை',
      'care_guide': 'பராமரிப்பு வழிகாட்டி',
      'recent_detections': 'சமீபத்திய கண்டறிதல்கள்',
      'view_all': 'அனைத்தையும் காண்க',
      'no_detections': 'இதுவரை கண்டறிதல்கள் இல்லை',
      'invalid_image': 'தவறான படம்',
      'today': 'இன்று',
      'yesterday': 'நேற்று',
      'days_ago': '{n} நாட்களுக்கு முன்',
      'months': 'ஜன,பிப்,மார்,ஏப்,மே,ஜூன்,ஜூலை,ஆக,செப்,அக்,நவ,டிச',
      'selected_count': '{n} தேர்ந்தெடுக்கப்பட்டது',
      'select_items': 'உருப்படிகளைத் தேர்வு செய்',
      'delete_selected': 'தேர்ந்தவற்றை நீக்கு',
      'filter_all': 'அனைத்தும்',
      'delete_one_title': 'இந்தப் பதிவை நீக்கவா?',
      'delete_one_msg':
          '"{name}" க்கான இந்தக் கண்டறிதல் பதிவு நிரந்தரமாக நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.',
      'record_deleted': 'பதிவு வெற்றிகரமாக நீக்கப்பட்டது',
      'delete_failed': 'நீக்க முடியவில்லை: {error}',
      'delete_many_title': '{n} பதிவுகளை நீக்கவா?',
      'delete_many_msg':
          'இந்தக் கண்டறிதல் பதிவுகள் நிரந்தரமாக நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.',
      'records_deleted': '{n} பதிவுகள் நீக்கப்பட்டன',
      'cancel': 'ரத்து',
      'delete': 'நீக்கு',
      'select_all': 'அனைத்தையும் தேர்வு செய்',
      'total_scans': 'மொத்த ஸ்கேன்கள்',
      'healthy_label': 'ஆரோக்கியம்',
      'diseased': 'நோயுற்றவை',
      'no_detections_hint':
          'நீங்கள் ஸ்கேன் செய்த மாதுளைகள்\nகண்டறிதலுக்குப் பிறகு இங்கே காட்டப்படும்.',
      'no_results_for': '"{name}" க்கு முடிவுகள் இல்லை',
      'try_other_filter': 'மேலே வேறு வடிகட்டியை முயற்சிக்கவும்.',
      'setting_up': 'அமைக்கப்படுகிறது…',
      'access_issue': 'அணுகல் சிக்கல்',
      'could_not_load': 'வரலாற்றை ஏற்ற முடியவில்லை',
      'index_building_msg':
          'தரவுத்தள குறியீடு இன்னும் உருவாக்கப்படுகிறது. இது பொதுவாக ஒரு நிமிடம் ஆகும் — சிறிது நேரத்தில் கீழே இழுத்துப் புதுப்பிக்கவும்.',
      'permission_msg':
          'நீங்கள் மீண்டும் உள்நுழைய வேண்டியிருக்கலாம், அல்லது தரவுத்தள அனுமதிகள் புதுப்பிக்கப்பட வேண்டும்.',
      'retry': 'மீண்டும் முயல்',
      'detection_detail': 'கண்டறிதல் விவரம்',
      'disease_label': 'நோய்',
      'detected': 'கண்டறிந்த நாள்',
      'follow_up_schedule': 'பின்தொடர்தல் அட்டவணை',
      'treatment_plan': 'சிகிச்சைத் திட்டம்',
      'organic_treatment': 'இயற்கை சிகிச்சை',
      'chemical_treatment': 'இரசாயன சிகிச்சை',
      'days': 'நாட்கள்',
      'times': 'முறை',
      'apply_every': 'இடைவெளி',
      'applications': 'தெளிப்புகள்',
      'total_period': 'மொத்த காலம்',
      'next_follow_up': 'அடுத்த பின்தொடர்தல்',
      // ── Reminder screen ──
      'follow_up_reminder': 'பின்தொடர்தல் நினைவூட்டல்',
      'reapply_after': 'மீண்டும் சிகிச்சை அளிக்க வேண்டியது',
      'n_days': '{n} நாட்கள்',
      'n_days_lower': '{n} நாட்கள்',
      'n_times': '{n} முறை',
      'reminder_set_title': 'நினைவூட்டல் அமைக்கப்பட்டது!',
      'reminder_set_msg':
          '{date} அன்று உங்கள் மாதுளையை மீண்டும் சரிபார்க்க நினைவூட்டுவோம்.',
      'continue_btn': 'தொடரவும்',
      'reminder_set_btn': 'நினைவூட்டல் அமைக்கப்பட்டது',
      'set_reminder': 'நினைவூட்டலை அமை',
      'skip_for_now': 'இப்போது தவிர்',
      'reminder_scheduled': 'நினைவூட்டல் திட்டமிடப்பட்டது',
      'reminder_failed': 'நினைவூட்டலை அமைக்க முடியவில்லை: {error}',
      'disease_with_name': 'நோய்: {name}',
      'number_of_applications': 'தெளிப்புகளின் எண்ணிக்கை',
      'total_treatment_period': 'மொத்த சிகிச்சைக் காலம்',
    },

    // ───────────────────────────── SINHALA ─────────────────────────────
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
      // NEW
      'no_fruit_detected':
          'මාදුළු ගෙඩියක් හඳුනාගත නොහැක. ගෙඩිය මැදට සිටින සේ පැහැදිලි ඡායාරූපයක් ගන්න.',
      'result_uncertain': 'ප්‍රතිඵලය නිශ්චිත නැත',
      'second_possibility': 'දෙවන හැකියාව',
      'severity_not_applicable': 'අදාළ නොවේ (නිරෝගී ගෙඩිය)',
      'warn_uncertain':
          'විශ්වාසය අඩුයි — වෙනත් කෝණයකින් නැවත ඡායාරූපයක් ගන්න හෝ විශේෂඥයෙකුගෙන් විමසන්න.',
      'warn_healthy_but_lesions':
          'නිරෝගී ලෙස හඳුනාගත්තද, බලපෑමට ලක් වූ ප්‍රදේශයක් දක්නට ඇත — කරුණාකර පරීක්ෂා කරවන්න.',
      'warn_no_lesion_segmented':
          'බලපෑමට ලක් වූ ප්‍රදේශය මැනිය නොහැකි විය — තීව්‍රතාවය අඩුවෙන් පෙන්විය හැක.',
      'warn_multiple_fruits':
          'ගෙඩි කිහිපයක් ඇත — විශාලතම ගෙඩිය පමණක් විශ්ලේෂණය කරන ලදී.',
      'uncertain_treatment':
          'ප්‍රතිඵලය නිශ්චිත නොවන බැවින් ප්‍රතිකාරයක් නිර්දේශ නොකෙරේ. පැහැදිලි ඡායාරූපයක් නැවත ගන්න හෝ කෘෂිකර්ම නිලධාරියෙකු හමුවන්න.',
      'saved_offline':
          'දුරකථනයේ සුරකින ලදී — අන්තර්ජාලය ලැබුණු විට සමමුහුර්ත වේ',
      // ── Result screen ──
      'confidence_label': 'විශ්වාසනීයත්වය',
      'severity_label': 'තීව්‍රතාව',
      'no_disease': 'රෝගයක් නැත',
      'severity_Mild': 'මෘදු',
      'severity_Moderate': 'මධ්‍යස්ථ',
      'severity_Severe': 'දරුණු',
      'severity_Healthy': 'නිරෝගී',
      'disease_Alternaria': 'ඇල්ටර්නේරියා',
      'disease_Anthracnose': 'ඇන්ත්‍රැක්නෝස්',
      'disease_Bacterial_Blight': 'බැක්ටීරියා අංගමාරය',
      'disease_Cercospora': 'සර්කොස්පෝරා',
      'disease_Healthy': 'නිරෝගී',
      'healthy_fruit': 'නිරෝගී ගෙඩිය',
      'note': 'සටහන',
      'healthy_no_action':
          'රෝගයක් හඳුනාගෙන නැත. සාමාන්‍ය රැකවරණය සහ නිරීක්ෂණය දිගටම කරගෙන යන්න.',
      'treatment_options': 'ප්‍රතිකාර විකල්ප',
      'treatment_options_subtitle':
          'ඔබේ ගොවිපොළට ගැළපෙන ප්‍රතිකාර ක්‍රමයක් තෝරන්න',
      'prevention_tips': 'වැළැක්වීමේ උපදෙස්',
      'proceed_to_reminder': 'සිහිකැඳවීමට යන්න',
      'back_to_home': 'මුල් පිටුවට යන්න',
      'organic': 'කාබනික',
      'chemical': 'රසායනික',
      // ── Detection home / history / detail ──
      'step_quality': 'රූපයේ ගුණාත්මකභාවය පරීක්ෂා කරමින්',
      'step_find': 'මාදුළු ගෙඩිය සොයමින්',
      'step_validate': 'මාදුළු ගෙඩියක්දැයි තහවුරු කරමින්',
      'step_identify': 'රෝගය හඳුනාගනිමින්',
      'step_severity': 'තීව්‍රතාව ගණනය කරමින්',
      'analysis_timeout_title': 'විශ්ලේෂණ කාලය ඉකුත් විය',
      'analysis_timeout_msg':
          'විශ්ලේෂණයට වැඩි කාලයක් ගත විය. නැවත උත්සාහ කරන්න.',
      'analysis_failed': 'විශ්ලේෂණය අසාර්ථක විය',
      'ok': 'හරි',
      'home_label': 'මුල් පිටුව',
      'disease_detection': 'රෝග හඳුනාගැනීම',
      'detection_history': 'හඳුනාගැනීම් ඉතිහාසය',
      'checking_image': 'රූපය පරීක්ෂා කරමින්...',
      'analyzing_short': 'විශ්ලේෂණය කරමින්...',
      'ready_to_scan': 'ස්කෑන් කිරීමට සූදානම්',
      'scanner': 'ස්කෑනරය',
      'tap_to_upload': 'උඩුගත කිරීමට තට්ටු කරන්න',
      'ready_to_analyze': 'විශ්ලේෂණයට සූදානම්',
      'scan_your_pomegranate': 'ඔබේ මාදුළු ගෙඩිය ස්කෑන් කරන්න',
      'ready_hint': 'පෙරදසුන පරීක්ෂා කර, "රූපය විශ්ලේෂණය කරන්න" තට්ටු කරන්න',
      'scan_hint':
          'ගෙඩිය රාමුව තුළ තබා ඡායාරූපයක් ගන්න,\nනැතහොත් ගැලරියෙන් උඩුගත කිරීමට රාමුව තට්ටු කරන්න',
      'original': 'මුල් රූපය',
      'preprocessed': 'පෙර සැකසූ',
      'analyzing_your_image': 'ඔබේ රූපය විශ්ලේෂණය කරමින්',
      'capture': 'ඡායාරූපය ගන්න',
      'retake': 'නැවත ගන්න',
      'gallery': 'ගැලරිය',
      'five_classes': 'වර්ග 5',
      'disease_types': 'රෝග වර්ග',
      'auto_analysis': 'ස්වයංක්‍රීය විශ්ලේෂණය',
      'treatment': 'ප්‍රතිකාර',
      'care_guide': 'රැකවරණ මාර්ගෝපදේශය',
      'recent_detections': 'මෑත හඳුනාගැනීම්',
      'view_all': 'සියල්ල බලන්න',
      'no_detections': 'තවම හඳුනාගැනීම් නැත',
      'invalid_image': 'වලංගු නොවන රූපය',
      'today': 'අද',
      'yesterday': 'ඊයේ',
      'days_ago': 'දින {n} කට පෙර',
      'months': 'ජන,පෙබ,මාර්,අප්‍රේ,මැයි,ජූනි,ජූලි,අගෝ,සැප්,ඔක්,නොවැ,දෙසැ',
      'selected_count': '{n} ක් තෝරා ඇත',
      'select_items': 'අයිතම තෝරන්න',
      'delete_selected': 'තෝරාගත් ඒවා මකන්න',
      'filter_all': 'සියල්ල',
      'delete_one_title': 'මෙම වාර්තාව මකන්නද?',
      'delete_one_msg':
          '"{name}" සඳහා වන මෙම හඳුනාගැනීමේ වාර්තාව ස්ථිරවම මකා දැමේ. මෙය අහෝසි කළ නොහැක.',
      'record_deleted': 'වාර්තාව සාර්ථකව මකා දැමිණි',
      'delete_failed': 'මැකීම අසාර්ථකයි: {error}',
      'delete_many_title': 'වාර්තා {n} ක් මකන්නද?',
      'delete_many_msg':
          'මෙම හඳුනාගැනීමේ වාර්තා ස්ථිරවම මකා දැමේ. මෙය අහෝසි කළ නොහැක.',
      'records_deleted': 'වාර්තා {n} ක් මකා දැමිණි',
      'cancel': 'අවලංගු කරන්න',
      'delete': 'මකන්න',
      'select_all': 'සියල්ල තෝරන්න',
      'total_scans': 'මුළු ස්කෑන්',
      'healthy_label': 'නිරෝගී',
      'diseased': 'රෝගී',
      'no_detections_hint':
          'ඔබ ස්කෑන් කළ මාදුළු ගෙඩි\nහඳුනාගැනීමකින් පසු මෙහි පෙන්වයි.',
      'no_results_for': '"{name}" සඳහා ප්‍රතිඵල නැත',
      'try_other_filter': 'ඉහත වෙනත් පෙරහනක් උත්සාහ කරන්න.',
      'setting_up': 'සකසමින්…',
      'access_issue': 'ප්‍රවේශ ගැටලුවක්',
      'could_not_load': 'ඉතිහාසය පූරණය කළ නොහැක',
      'index_building_msg':
          'දත්ත ගබඩා දර්ශකය තවමත් සකසමින් පවතී. සාමාන්‍යයෙන් මිනිත්තුවක් ගතවේ — ටික වේලාවකින් පහළට ඇද නැවුම් කරන්න.',
      'permission_msg':
          'ඔබට නැවත පිවිසීමට අවශ්‍ය විය හැක, නැතහොත් දත්ත ගබඩා අවසර යාවත්කාලීන කළ යුතුය.',
      'retry': 'නැවත උත්සාහ කරන්න',
      'detection_detail': 'හඳුනාගැනීමේ විස්තර',
      'disease_label': 'රෝගය',
      'detected': 'හඳුනාගත් දිනය',
      'follow_up_schedule': 'පසු විපරම් කාලසටහන',
      'treatment_plan': 'ප්‍රතිකාර සැලැස්ම',
      'organic_treatment': 'කාබනික ප්‍රතිකාරය',
      'chemical_treatment': 'රසායනික ප්‍රතිකාරය',
      'days': 'දින',
      'times': 'වාර',
      'apply_every': 'යොදන පරතරය',
      'applications': 'යෙදීම් ගණන',
      'total_period': 'මුළු කාලය',
      'next_follow_up': 'ඊළඟ පසු විපරම',
      // ── Reminder screen ──
      'follow_up_reminder': 'පසු විපරම් සිහිකැඳවීම',
      'reapply_after': 'නැවත ප්‍රතිකාර කළ යුත්තේ',
      'n_days': 'දින {n}',
      'n_days_lower': 'දින {n}',
      'n_times': 'වාර {n}',
      'reminder_set_title': 'සිහිකැඳවීම සකසා ඇත!',
      'reminder_set_msg':
          '{date} දින ඔබේ මාදුළු ගෙඩිය නැවත පරීක්ෂා කිරීමට අපි ඔබට දන්වන්නෙමු.',
      'continue_btn': 'ඉදිරියට',
      'reminder_set_btn': 'සිහිකැඳවීම සකසා ඇත',
      'set_reminder': 'සිහිකැඳවීම සකසන්න',
      'skip_for_now': 'දැනට මඟ හරින්න',
      'reminder_scheduled': 'සිහිකැඳවීම සැලසුම් කර ඇත',
      'reminder_failed': 'සිහිකැඳවීම සැකසිය නොහැක: {error}',
      'disease_with_name': 'රෝගය: {name}',
      'number_of_applications': 'යෙදීම් ගණන',
      'total_treatment_period': 'මුළු ප්‍රතිකාර කාලය',
    },
  };
}
