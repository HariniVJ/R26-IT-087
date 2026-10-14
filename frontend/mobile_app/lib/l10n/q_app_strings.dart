// lib/l10n/q_app_strings.dart
//
// ═══════════════════════════════════════════════════════════════════════════
//  ALL TEXT FOR THE QUALITY GRADING MODULE — 3 LANGUAGES (en / ta / si)
//
//  • This file does NOT keep its own language. It reads the ONE app-wide
//    language from l10n/app_strings.dart (Profile page / bottom nav), the
//    same way the disease module (d_app_strings.dart) does.
//  • Add every new key to all three maps. A missing key falls back to
//    English, and an unknown key returns the key itself.
//  • Class name is QStrings (NOT AppStrings) so it never clashes with the
//    disease module's AppStrings in d_app_strings.dart.
//
//  USE IN SCREENS
//     Text(qt('quality_grading'))
//     Text(qtf('weight_value', {'g': '250'}))      → "250 g"
//     Text(qQuality(result.quality))                → "Low Quality"
//     Text(qDefect(result.defectType))              → "Disease"
//
//  REBUILD ON LANGUAGE CHANGE
//     ListenableBuilder(listenable: QStrings.listenable, builder: ...)
//     (or addListener in initState → setState)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

import 'app_strings.dart' as app;

class QStrings {
  QStrings._();

  /// Notifies when the app language changes (Profile page).
  static Listenable get listenable => app.LanguageController.instance;

  /// 'en' | 'ta' | 'si' — always the app-wide language.
  static String get currentLang {
    switch (app.LanguageController.instance.lang) {
      case app.AppLang.ta:
        return 'ta';
      case app.AppLang.si:
        return 'si';
      default:
        return 'en';
    }
  }

  /// Old API kept so existing calls still compile: QStrings.get('key').
  static String get(String key) => translate(key, currentLang);

  static String translate(String key, String lang) {
    return _strings[lang]?[key] ?? _strings['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    // ─────────────────────────────── ENGLISH ───────────────────────────────
    'en': {
      // Main screen
      'quality_grading': 'Quality Grading',
      'tap_to_upload': 'Tap to upload a pomegranate image',
      'analyse_quality': 'Analyse Quality',
      'analysing': 'Analysing...',
      'detected_result': 'Detected Result',
      'recommendation': 'Recommendation',
      'defect_detected': 'Defect Detected',
      'defect_type': 'Defect Type',
      'severity': 'Severity',
      'severity_estimate': 'Severity (estimate)',
      'scan_another': 'Scan Another',
      'not_pomegranate':
          'This does not look like a pomegranate. Please try another image.',
      'enter_weight': 'Enter weight (grams)',
      'weight': 'Weight',
      'weight_value': '{g} g',
      'weight_optional': 'Weight (optional)',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'select_source': 'Select image source',
      'save_to_history': 'Save to History',
      'saving': 'Saving...',
      'saved': 'Saved to history',
      'save_failed': 'Could not save. Please try again.',
      'analyse_failed': 'Analysis failed. Please try again.',
      'select_image_first': 'Please select an image first',
      'login_required': 'Please log in to save results',
      'explanation': 'Explanation',
      'waste_usage': 'Waste Usage',
      'safety_note': 'Safety Note',
      'no_defect': 'No defect detected',
      'na': 'N/A',

      // Quality / confidence
      'quality': 'Quality',
      'quality_confidence': 'Quality confidence',
      'confidence': 'Confidence',
      'high_quality': 'High Quality',
      'medium_quality': 'Medium Quality',
      'low_quality': 'Low Quality',

      // Defects
      'defect_crack': 'Crack',
      'defect_disease': 'Disease',
      'defect_rot': 'Rot',
      'defect_sunburn': 'Sunburn',

      // History
      'grading_history': 'Grading History',
      'no_results': 'No results found',
      'history_detail': 'Grading Details',
      'delete': 'Delete',
      'delete_all': 'Delete All',
      'delete_confirm': 'Delete this record?',
      'delete_all_confirm': 'Delete all grading records?',
      'cancel': 'Cancel',
      'deleted': 'Deleted',
      'all': 'All',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'date': 'Date',
      'view_disease': 'View disease details',

      // Disease (low quality → disease)
      'disease_check': 'Disease Check',
      'checking_disease': 'Checking for disease...',
      'disease_detected': 'Disease Detected',
      'disease_name': 'Disease',
      'disease_confidence': 'Disease confidence',
      'disease_severity': 'Disease severity',
      'disease_uncertain_note':
          'The model is not fully sure about this disease. Please check the fruit again or ask an expert.',
      'disease_healthy_note':
          'The disease model did not find a disease on this fruit. The low quality may be caused by another defect.',
      'disease_not_detected_note':
          'The disease model could not find a pomegranate fruit clearly in this photo. Try a closer, clearer photo.',
      'disease_failed_note': 'Disease check failed. Please try again.',
      'physical_defect_title': 'Physical Defect',
      'physical_defect_note':
          'This fruit has a physical defect ({defect}). No disease treatment is needed.',
      'treatment': 'Treatment',
      'treatment_type': 'Treatment type',
      'organic': 'Organic',
      'chemical': 'Chemical',
      'organic_treatment': 'Organic Treatment',
      'chemical_treatment': 'Chemical Treatment',
      'prevention_tips': 'Prevention Tips',
      'schedule_every': 'Apply every {d} days · {n} times',
      'close': 'Close',
      'ok': 'OK',
      'low_quality_title': 'Low Quality Fruit',

      // Screen text (main + history)
      'ai_detection_sub': 'AI-powered pomegranate quality detection',
      'analysing_quality': 'Analyzing Quality...',
      'cannot_undo': 'This cannot be undone.',
      'checking_image': 'Checking image...',
      'clear_all_msg': 'All {n} results will be permanently deleted.',
      'clear_all_title': 'Clear all history?',
      'could_not_save': 'Could not save result: {msg}',
      'delete_failed': 'Delete failed — check your connection',
      'delete_n_title': 'Delete {n} result(s)?',
      'delete_selected': 'Delete selected',
      'delete_this_result': 'Delete this result?',
      'failed_connection': 'Failed — check your connection',
      'file_types': 'JPG · PNG · Max 10 MB',
      'fruit_weight': 'Fruit Weight',
      'graded_on': 'Graded On',
      'graded_range': 'graded {range}',
      'high': 'High',
      'low': 'Low',
      'medium': 'Medium',
      'history_cleared': 'All history cleared',
      'image_ready': 'Image ready — tap Analyse',
      'login_analyse': 'Please log in before analysing a fruit.',
      'login_history': 'Please log in to view history.',
      'model_error': 'Model error: {msg}',
      'n_deleted': '{n} result(s) deleted',
      'n_selected': '{n} selected',
      'offline_cached': 'Weak or no connection — showing cached results',
      'original': 'Original',
      'preprocessed': 'Preprocessed (224×224)',
      'result_deleted': 'Result deleted',
      'retake_hint': 'Please retake a clear photo showing the whole fruit.',
      'retake_photo': 'Retake Photo',
      'rules_subtitle': 'Generated using the configured recommendation rules',
      'scan_to_view': 'Scan a fruit to view grading history',
      'select_all': 'Select All',
      'unselect_all': 'Unselect All',
      'step_cnn': 'CNN classification',
      'step_features': 'Feature extraction',
      'step_preprocess': 'Image preprocessing',
      'step_result': 'Generating result',
      'storage_overview': 'Storage Overview',
      'utilization_recommendation': 'Utilization Recommendation',
      'view_all': 'View All',
      'waste_method': 'Waste Utilization Method',
      'why_recommendation': 'Why this recommendation?',

      // Popups + history detail
      'disease_details': 'Disease Details',
      'disease_not_captured':
          'Detailed disease information was not captured for this result. Scan the fruit again to get the disease name and treatment.',
      'got_it': 'Got It',
      'healthy': 'Healthy',
      'low_quality_detected': 'Low Quality Detected',
      'lq_disease_title': 'Low Quality — Disease Detected',
      'lq_fallback_body':
          'The fruit was graded low quality due to a possible disease, but we could not confirm the exact type from this photo. Please try capturing a clearer image of the affected area.',
      'lq_healthy_body':
          'The fruit was graded low quality due to a disease category, but the disease model found it healthy on closer inspection — you may want to re-check the fruit manually.',
      'recommended_usage': 'Recommended Usage',
      'result_details': 'Result Details',
      'unknown': 'Unknown',
    },

    // ─────────────────────────────── TAMIL ────────────────────────────────
    'ta': {
      'quality_grading': 'தர மதிப்பீடு',
      'tap_to_upload': 'மாதுளை படத்தை பதிவேற்ற தட்டவும்',
      'analyse_quality': 'தரத்தை பகுப்பாய்வு செய்',
      'analysing': 'பகுப்பாய்வு செய்கிறது...',
      'detected_result': 'கண்டறிந்த முடிவு',
      'recommendation': 'பரிந்துரை',
      'defect_detected': 'குறைபாடு கண்டறியப்பட்டது',
      'defect_type': 'குறைபாட்டு வகை',
      'severity': 'தீவிரம்',
      'severity_estimate': 'தீவிரம் (மதிப்பீடு)',
      'scan_another': 'மற்றொன்றை ஸ்கேன் செய்',
      'not_pomegranate':
          'இது மாதுளை போல் தெரியவில்லை. வேறு படத்தை முயற்சிக்கவும்.',
      'enter_weight': 'எடையை உள்ளிடவும் (கிராம்)',
      'weight': 'எடை',
      'weight_value': '{g} கி',
      'weight_optional': 'எடை (விருப்பம்)',
      'camera': 'கேமரா',
      'gallery': 'கேலரி',
      'select_source': 'பட மூலத்தைத் தேர்வு செய்யவும்',
      'save_to_history': 'வரலாற்றில் சேமி',
      'saving': 'சேமிக்கிறது...',
      'saved': 'வரலாற்றில் சேமிக்கப்பட்டது',
      'save_failed': 'சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      'analyse_failed': 'பகுப்பாய்வு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      'select_image_first': 'முதலில் ஒரு படத்தைத் தேர்வு செய்யவும்',
      'login_required': 'முடிவுகளைச் சேமிக்க உள்நுழையவும்',
      'explanation': 'விளக்கம்',
      'waste_usage': 'கழிவு பயன்பாடு',
      'safety_note': 'பாதுகாப்பு குறிப்பு',
      'no_defect': 'குறைபாடு இல்லை',
      'na': 'இல்லை',

      'quality': 'தரம்',
      'quality_confidence': 'தர நம்பகத்தன்மை',
      'confidence': 'நம்பகத்தன்மை',
      'high_quality': 'உயர் தரம்',
      'medium_quality': 'நடுத்தர தரம்',
      'low_quality': 'குறைந்த தரம்',

      'defect_crack': 'வெடிப்பு',
      'defect_disease': 'நோய்',
      'defect_rot': 'அழுகல்',
      'defect_sunburn': 'வெயில் எரிவு',

      'grading_history': 'தர மதிப்பீட்டு வரலாறு',
      'no_results': 'முடிவுகள் எதுவும் இல்லை',
      'history_detail': 'தர மதிப்பீட்டு விவரங்கள்',
      'delete': 'நீக்கு',
      'delete_all': 'அனைத்தையும் நீக்கு',
      'delete_confirm': 'இந்தப் பதிவை நீக்கவா?',
      'delete_all_confirm': 'அனைத்து தர பதிவுகளையும் நீக்கவா?',
      'cancel': 'ரத்து',
      'deleted': 'நீக்கப்பட்டது',
      'all': 'அனைத்தும்',
      'today': 'இன்று',
      'this_week': 'இந்த வாரம்',
      'this_month': 'இந்த மாதம்',
      'date': 'தேதி',
      'view_disease': 'நோய் விவரங்களைப் பார்',

      'disease_check': 'நோய் சோதனை',
      'checking_disease': 'நோய் சோதிக்கப்படுகிறது...',
      'disease_detected': 'நோய் கண்டறியப்பட்டது',
      'disease_name': 'நோய்',
      'disease_confidence': 'நோய் நம்பகத்தன்மை',
      'disease_severity': 'நோய் தீவிரம்',
      'disease_uncertain_note':
          'இந்த நோய் பற்றி மாடல் முழுமையாக உறுதியாக இல்லை. பழத்தை மீண்டும் சரிபார்க்கவும் அல்லது நிபுணரிடம் கேட்கவும்.',
      'disease_healthy_note':
          'நோய் மாடல் இந்தப் பழத்தில் நோயைக் கண்டறியவில்லை. குறைந்த தரத்திற்கு வேறு குறைபாடு காரணமாக இருக்கலாம்.',
      'disease_not_detected_note':
          'இந்தப் படத்தில் மாதுளைப் பழத்தை நோய் மாடல் தெளிவாகக் கண்டறிய முடியவில்லை. அருகில், தெளிவான படத்தை முயற்சிக்கவும்.',
      'disease_failed_note':
          'நோய் சோதனை தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
      'physical_defect_title': 'உடல் குறைபாடு',
      'physical_defect_note':
          'இந்தப் பழத்தில் உடல் குறைபாடு ({defect}) உள்ளது. நோய் சிகிச்சை தேவையில்லை.',
      'treatment': 'சிகிச்சை',
      'treatment_type': 'சிகிச்சை வகை',
      'organic': 'இயற்கை',
      'chemical': 'இரசாயன',
      'organic_treatment': 'இயற்கை சிகிச்சை',
      'chemical_treatment': 'இரசாயன சிகிச்சை',
      'prevention_tips': 'தடுப்பு குறிப்புகள்',
      'schedule_every': '{d} நாட்களுக்கு ஒருமுறை · {n} முறை',
      'close': 'மூடு',
      'ok': 'சரி',
      'low_quality_title': 'குறைந்த தரப் பழம்',

      // Screen text (main + history)
      'ai_detection_sub': 'AI மூலம் மாதுளை தரக் கண்டறிதல்',
      'analysing_quality': 'தரம் பகுப்பாய்வு செய்யப்படுகிறது...',
      'cannot_undo': 'இதைத் திரும்பப் பெற முடியாது.',
      'checking_image': 'படம் சரிபார்க்கப்படுகிறது...',
      'clear_all_msg': 'அனைத்து {n} முடிவுகளும் நிரந்தரமாக நீக்கப்படும்.',
      'clear_all_title': 'முழு வரலாற்றையும் நீக்கவா?',
      'could_not_save': 'முடிவைச் சேமிக்க முடியவில்லை: {msg}',
      'delete_failed': 'நீக்க முடியவில்லை — இணைப்பைச் சரிபார்க்கவும்',
      'delete_n_title': '{n} முடிவு(களை) நீக்கவா?',
      'delete_selected': 'தேர்ந்தெடுத்தவற்றை நீக்கு',
      'delete_this_result': 'இந்த முடிவை நீக்கவா?',
      'failed_connection': 'தோல்வி — இணைப்பைச் சரிபார்க்கவும்',
      'file_types': 'JPG · PNG · அதிகபட்சம் 10 MB',
      'fruit_weight': 'பழத்தின் எடை',
      'graded_on': 'மதிப்பிட்ட தேதி',
      'graded_range': 'மதிப்பிடப்பட்டது ({range})',
      'high': 'உயர்',
      'low': 'குறைந்த',
      'medium': 'நடுத்தர',
      'history_cleared': 'முழு வரலாறும் நீக்கப்பட்டது',
      'image_ready': 'படம் தயார் — பகுப்பாய்வு செய்ய தட்டவும்',
      'login_analyse': 'பழத்தைப் பகுப்பாய்வு செய்யும் முன் உள்நுழையவும்.',
      'login_history': 'வரலாற்றைப் பார்க்க உள்நுழையவும்.',
      'model_error': 'மாடல் பிழை: {msg}',
      'n_deleted': '{n} முடிவு(கள்) நீக்கப்பட்டன',
      'n_selected': '{n} தேர்ந்தெடுக்கப்பட்டது',
      'offline_cached':
          'இணைப்பு பலவீனம் / இல்லை — சேமித்த முடிவுகள் காட்டப்படுகின்றன',
      'original': 'அசல்',
      'preprocessed': 'முன்செயலாக்கம் (224×224)',
      'result_deleted': 'முடிவு நீக்கப்பட்டது',
      'retake_hint':
          'முழுப் பழமும் தெரியும்படி தெளிவான படத்தை மீண்டும் எடுக்கவும்.',
      'retake_photo': 'மீண்டும் படம் எடு',
      'rules_subtitle':
          'அமைக்கப்பட்ட பரிந்துரை விதிகளைப் பயன்படுத்தி உருவாக்கப்பட்டது',
      'scan_to_view': 'தர வரலாற்றைப் பார்க்க ஒரு பழத்தை ஸ்கேன் செய்யவும்',
      'select_all': 'அனைத்தையும் தேர்வு செய்',
      'unselect_all': 'தேர்வை நீக்கு',
      'step_cnn': 'CNN வகைப்படுத்தல்',
      'step_features': 'அம்சப் பிரித்தெடுப்பு',
      'step_preprocess': 'பட முன்செயலாக்கம்',
      'step_result': 'முடிவு உருவாக்கப்படுகிறது',
      'storage_overview': 'சேமிப்பு மேலோட்டம்',
      'utilization_recommendation': 'பயன்பாட்டுப் பரிந்துரை',
      'view_all': 'அனைத்தையும் பார்',
      'waste_method': 'கழிவு பயன்பாட்டு முறை',
      'why_recommendation': 'இந்தப் பரிந்துரை ஏன்?',

      // Popups + history detail
      'disease_details': 'நோய் விவரங்கள்',
      'disease_not_captured':
          'இந்த முடிவுக்கு விரிவான நோய் தகவல் சேமிக்கப்படவில்லை. நோயின் பெயர் மற்றும் சிகிச்சையைப் பெற பழத்தை மீண்டும் ஸ்கேன் செய்யவும்.',
      'got_it': 'சரி, புரிந்தது',
      'healthy': 'ஆரோக்கியமானது',
      'low_quality_detected': 'குறைந்த தரம் கண்டறியப்பட்டது',
      'lq_disease_title': 'குறைந்த தரம் — நோய் கண்டறியப்பட்டது',
      'lq_fallback_body':
          'சாத்தியமான நோய் காரணமாக இந்தப் பழம் குறைந்த தரமாக மதிப்பிடப்பட்டது, ஆனால் இந்தப் படத்திலிருந்து சரியான நோய் வகையை உறுதிப்படுத்த முடியவில்லை. பாதிக்கப்பட்ட பகுதியின் தெளிவான படத்தை எடுக்கவும்.',
      'lq_healthy_body':
          'நோய் வகை காரணமாக இந்தப் பழம் குறைந்த தரமாக மதிப்பிடப்பட்டது, ஆனால் நோய் மாடல் இதை ஆரோக்கியமானதாகக் கண்டது — பழத்தை நேரில் மீண்டும் சரிபார்க்கவும்.',
      'recommended_usage': 'பரிந்துரைக்கப்பட்ட பயன்பாடு',
      'result_details': 'முடிவு விவரங்கள்',
      'unknown': 'தெரியவில்லை',
    },

    // ────────────────────────────── SINHALA ───────────────────────────────
    'si': {
      'quality_grading': 'ගුණාත්මක ශ්‍රේණිගත කිරීම',
      'tap_to_upload': 'දෙළුම් රූපයක් උඩුගත කිරීමට තට්ටු කරන්න',
      'analyse_quality': 'ගුණාත්මකභාවය විශ්ලේෂණය කරන්න',
      'analysing': 'විශ්ලේෂණය කරමින්...',
      'detected_result': 'හඳුනාගත් ප්‍රතිඵලය',
      'recommendation': 'නිර්දේශය',
      'defect_detected': 'දෝෂයක් හඳුනාගන්නා ලදී',
      'defect_type': 'දෝෂ වර්ගය',
      'severity': 'බරපතලකම',
      'severity_estimate': 'බරපතලකම (ඇස්තමේන්තුව)',
      'scan_another': 'තවත් එකක් ස්කෑන් කරන්න',
      'not_pomegranate':
          'මෙය දෙළුම් ගෙඩියක් ලෙස නොපෙනේ. වෙනත් රූපයක් උත්සාහ කරන්න.',
      'enter_weight': 'බර ඇතුළත් කරන්න (ග්‍රෑම්)',
      'weight': 'බර',
      'weight_value': '{g} ග්‍රෑ',
      'weight_optional': 'බර (විකල්ප)',
      'camera': 'කැමරාව',
      'gallery': 'ගැලරිය',
      'select_source': 'රූප මූලාශ්‍රය තෝරන්න',
      'save_to_history': 'ඉතිහාසයට සුරකින්න',
      'saving': 'සුරකිමින්...',
      'saved': 'ඉතිහාසයට සුරකින ලදී',
      'save_failed': 'සුරැකීමට නොහැකි විය. නැවත උත්සාහ කරන්න.',
      'analyse_failed': 'විශ්ලේෂණය අසාර්ථක විය. නැවත උත්සාහ කරන්න.',
      'select_image_first': 'කරුණාකර පළමුව රූපයක් තෝරන්න',
      'login_required': 'ප්‍රතිඵල සුරැකීමට පිවිසෙන්න',
      'explanation': 'පැහැදිලි කිරීම',
      'waste_usage': 'අපද්‍රව්‍ය භාවිතය',
      'safety_note': 'ආරක්ෂක සටහන',
      'no_defect': 'දෝෂයක් නැත',
      'na': 'නැත',

      'quality': 'ගුණාත්මකභාවය',
      'quality_confidence': 'ගුණාත්මක විශ්වාසය',
      'confidence': 'විශ්වාසය',
      'high_quality': 'ඉහළ ගුණාත්මක',
      'medium_quality': 'මධ්‍යම ගුණාත්මක',
      'low_quality': 'අඩු ගුණාත්මක',

      'defect_crack': 'පිපිරීම',
      'defect_disease': 'රෝගය',
      'defect_rot': 'කුණුවීම',
      'defect_sunburn': 'හිරු පිළිස්සීම',

      'grading_history': 'ශ්‍රේණිගත කිරීමේ ඉතිහාසය',
      'no_results': 'ප්‍රතිඵල හමු නොවීය',
      'history_detail': 'ශ්‍රේණිගත කිරීමේ විස්තර',
      'delete': 'මකන්න',
      'delete_all': 'සියල්ල මකන්න',
      'delete_confirm': 'මෙම වාර්තාව මකන්නද?',
      'delete_all_confirm': 'සියලුම ශ්‍රේණිගත වාර්තා මකන්නද?',
      'cancel': 'අවලංගු කරන්න',
      'deleted': 'මකා දමන ලදී',
      'all': 'සියල්ල',
      'today': 'අද',
      'this_week': 'මෙම සතිය',
      'this_month': 'මෙම මාසය',
      'date': 'දිනය',
      'view_disease': 'රෝග විස්තර බලන්න',

      'disease_check': 'රෝග පරීක්ෂාව',
      'checking_disease': 'රෝග පරීක්ෂා කරමින්...',
      'disease_detected': 'රෝගයක් හඳුනාගන්නා ලදී',
      'disease_name': 'රෝගය',
      'disease_confidence': 'රෝග විශ්වාසය',
      'disease_severity': 'රෝග බරපතලකම',
      'disease_uncertain_note':
          'මෙම රෝගය ගැන ආකෘතිය සම්පූර්ණයෙන් විශ්වාස නැත. ගෙඩිය නැවත පරීක්ෂා කරන්න හෝ විශේෂඥයෙකුගෙන් විමසන්න.',
      'disease_healthy_note':
          'රෝග ආකෘතියට මෙම ගෙඩියේ රෝගයක් හමු නොවීය. අඩු ගුණාත්මකභාවයට වෙනත් දෝෂයක් හේතු විය හැක.',
      'disease_not_detected_note':
          'මෙම ඡායාරූපයේ දෙළුම් ගෙඩිය රෝග ආකෘතියට පැහැදිලිව හඳුනාගත නොහැකි විය. සමීප, පැහැදිලි ඡායාරූපයක් උත්සාහ කරන්න.',
      'disease_failed_note': 'රෝග පරීක්ෂාව අසාර්ථක විය. නැවත උත්සාහ කරන්න.',
      'physical_defect_title': 'භෞතික දෝෂය',
      'physical_defect_note':
          'මෙම ගෙඩියේ භෞතික දෝෂයක් ({defect}) ඇත. රෝග ප්‍රතිකාර අවශ්‍ය නැත.',
      'treatment': 'ප්‍රතිකාරය',
      'treatment_type': 'ප්‍රතිකාර වර්ගය',
      'organic': 'කාබනික',
      'chemical': 'රසායනික',
      'organic_treatment': 'කාබනික ප්‍රතිකාරය',
      'chemical_treatment': 'රසායනික ප්‍රතිකාරය',
      'prevention_tips': 'වැළැක්වීමේ උපදෙස්',
      'schedule_every': 'දින {d} කට වරක් · වාර {n}',
      'close': 'වසන්න',
      'ok': 'හරි',
      'low_quality_title': 'අඩු ගුණාත්මක ගෙඩිය',

      // Screen text (main + history)
      'ai_detection_sub': 'AI මගින් දෙළුම් ගුණාත්මකභාවය හඳුනාගැනීම',
      'analysing_quality': 'ගුණාත්මකභාවය විශ්ලේෂණය කරමින්...',
      'cannot_undo': 'මෙය අහෝසි කළ නොහැක.',
      'checking_image': 'රූපය පරීක්ෂා කරමින්...',
      'clear_all_msg': 'ප්‍රතිඵල {n} සියල්ල ස්ථිරවම මකා දමනු ඇත.',
      'clear_all_title': 'සියලු ඉතිහාසය මකන්නද?',
      'could_not_save': 'ප්‍රතිඵලය සුරැකිය නොහැකි විය: {msg}',
      'delete_failed': 'මැකීම අසාර්ථකයි — සම්බන්ධතාවය පරීක්ෂා කරන්න',
      'delete_n_title': 'ප්‍රතිඵල {n} ක් මකන්නද?',
      'delete_selected': 'තෝරාගත් ඒවා මකන්න',
      'delete_this_result': 'මෙම ප්‍රතිඵලය මකන්නද?',
      'failed_connection': 'අසාර්ථකයි — සම්බන්ධතාවය පරීක්ෂා කරන්න',
      'file_types': 'JPG · PNG · උපරිම 10 MB',
      'fruit_weight': 'ගෙඩියේ බර',
      'graded_on': 'ශ්‍රේණිගත කළ දිනය',
      'graded_range': 'ශ්‍රේණිගත කළ ({range})',
      'high': 'ඉහළ',
      'low': 'අඩු',
      'medium': 'මධ්‍යම',
      'history_cleared': 'සියලු ඉතිහාසය මකා දමන ලදී',
      'image_ready': 'රූපය සූදානම් — විශ්ලේෂණයට තට්ටු කරන්න',
      'login_analyse': 'ගෙඩියක් විශ්ලේෂණයට පෙර පිවිසෙන්න.',
      'login_history': 'ඉතිහාසය බැලීමට පිවිසෙන්න.',
      'model_error': 'ආකෘති දෝෂය: {msg}',
      'n_deleted': 'ප්‍රතිඵල {n} ක් මකා දමන ලදී',
      'n_selected': '{n} ක් තෝරා ඇත',
      'offline_cached': 'දුර්වල / සම්බන්ධතාවයක් නැත — සුරැකි ප්‍රතිඵල පෙන්වයි',
      'original': 'මුල් රූපය',
      'preprocessed': 'පූර්ව සැකසූ (224×224)',
      'result_deleted': 'ප්‍රතිඵලය මකා දමන ලදී',
      'retake_hint': 'සම්පූර්ණ ගෙඩිය පෙනෙන පැහැදිලි ඡායාරූපයක් නැවත ගන්න.',
      'retake_photo': 'නැවත ඡායාරූපය ගන්න',
      'rules_subtitle': 'සකසා ඇති නිර්දේශ නීති භාවිතයෙන් සාදන ලදී',
      'scan_to_view': 'ශ්‍රේණිගත ඉතිහාසය බැලීමට ගෙඩියක් ස්කෑන් කරන්න',
      'select_all': 'සියල්ල තෝරන්න',
      'unselect_all': 'තේරීම ඉවත් කරන්න',
      'step_cnn': 'CNN වර්ගීකරණය',
      'step_features': 'ලක්ෂණ නිස්සාරණය',
      'step_preprocess': 'රූප පූර්ව සැකසීම',
      'step_result': 'ප්‍රතිඵලය සාදමින්',
      'storage_overview': 'ගබඩා දළ විශ්ලේෂණය',
      'utilization_recommendation': 'භාවිත නිර්දේශය',
      'view_all': 'සියල්ල බලන්න',
      'waste_method': 'අපද්‍රව්‍ය භාවිත ක්‍රමය',
      'why_recommendation': 'මෙම නිර්දේශය ඇයි?',

      // Popups + history detail
      'disease_details': 'රෝග විස්තර',
      'disease_not_captured':
          'මෙම ප්‍රතිඵලය සඳහා සවිස්තරාත්මක රෝග තොරතුරු සුරැකී නැත. රෝගයේ නම සහ ප්‍රතිකාර ලබා ගැනීමට ගෙඩිය නැවත ස්කෑන් කරන්න.',
      'got_it': 'තේරුණා',
      'healthy': 'නිරෝගී',
      'low_quality_detected': 'අඩු ගුණාත්මකභාවයක් හඳුනාගන්නා ලදී',
      'lq_disease_title': 'අඩු ගුණාත්මක — රෝගයක් හඳුනාගන්නා ලදී',
      'lq_fallback_body':
          'විය හැකි රෝගයක් නිසා මෙම ගෙඩිය අඩු ගුණාත්මක ලෙස ශ්‍රේණිගත කළ නමුත්, මෙම ඡායාරූපයෙන් නිශ්චිත රෝග වර්ගය තහවුරු කළ නොහැකි විය. බලපෑමට ලක් වූ ප්‍රදේශයේ පැහැදිලි රූපයක් ගන්න.',
      'lq_healthy_body':
          'රෝග කාණ්ඩයක් නිසා මෙම ගෙඩිය අඩු ගුණාත්මක ලෙස ශ්‍රේණිගත කළ නමුත්, රෝග ආකෘතිය එය නිරෝගී බව සොයා ගත්තේය — ගෙඩිය අතින් නැවත පරීක්ෂා කරන්න.',
      'recommended_usage': 'නිර්දේශිත භාවිතය',
      'result_details': 'ප්‍රතිඵල විස්තර',
      'unknown': 'නොදනී',
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHORT HELPERS (named q… so they never clash with t() / dt())
// ═══════════════════════════════════════════════════════════════════════════

/// Text(qt('quality_grading'))
String qt(String key) => QStrings.get(key);

/// qtf('weight_value', {'g': '250'}) → "250 g"
String qtf(String key, Map<String, String> vars) {
  var value = qt(key);
  vars.forEach((name, v) => value = value.replaceAll('{$name}', v));
  return value;
}

/// 'high_quality' / 'medium_quality' / 'low_quality' → translated label.
/// Also accepts 'high' / 'medium' / 'low'.
String qQuality(String? quality) {
  if (quality == null || quality.isEmpty) return qt('na');
  final key = quality.endsWith('_quality') ? quality : '${quality}_quality';
  final value = qt(key);
  return value == key ? quality.replaceAll('_', ' ') : value;
}

/// 'crack' / 'disease' / 'rot' / 'sunburn' → translated defect name.
String qDefect(String? defect) {
  if (defect == null || defect.isEmpty) return qt('no_defect');
  final key = 'defect_$defect';
  final value = qt(key);
  return value == key ? defect : value;
}
