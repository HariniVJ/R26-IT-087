import '../../l10n/d_app_strings.dart';

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

class TreatmentData {
  TreatmentData._();

  static DiseaseTreatmentInfo forDisease(
    String diseaseName,
    AppLanguage language,
  ) {
    final table = _data[language.code] ?? _data['en']!;
    return table[diseaseName] ?? table['Healthy']!;
  }

  static final Map<String, Map<String, DiseaseTreatmentInfo>> _data = {
    'en': {
      'Healthy': const DiseaseTreatmentInfo(
        treatment: 'No disease detected. Continue regular care and monitoring.',
        prevention: [
          'Maintain balanced irrigation and fertilization',
          'Prune regularly for good air circulation',
          'Inspect fruit weekly for early signs of disease',
        ],
        followUpDays: 14,
      ),
      'Alternaria': const DiseaseTreatmentInfo(
        treatment:
            'Remove and destroy infected fruit and leaves. Apply a recommended '
            'copper-based fungicide every 10-14 days until symptoms subside.',
        prevention: [
          'Avoid overhead irrigation that wets fruit surface',
          'Improve canopy ventilation through pruning',
          'Remove fallen infected debris from the orchard floor',
        ],
        followUpDays: 10,
      ),
      'Anthracnose': const DiseaseTreatmentInfo(
        treatment:
            'Prune and destroy affected twigs and fruit. Apply a suitable '
            'fungicide spray at early symptom onset, per local extension advice.',
        prevention: [
          'Avoid injuring fruit during handling',
          'Thin fruit clusters to reduce humidity',
          'Store harvested fruit in a cool, dry place',
        ],
        followUpDays: 10,
      ),
      'Bacterial_Blight': const DiseaseTreatmentInfo(
        treatment:
            'Remove and burn infected plant parts. Apply copper-based '
            'bactericide sprays; disinfect pruning tools between plants.',
        prevention: [
          'Avoid orchard work during wet weather',
          'Use disease-free planting material',
          'Disinfect tools regularly',
        ],
        followUpDays: 7,
      ),
      'Cercospora': const DiseaseTreatmentInfo(
        treatment:
            'Remove heavily spotted leaves and apply a recommended foliar '
            'fungicide. Ensure good drainage and avoid excess nitrogen.',
        prevention: [
          'Avoid excess nitrogen fertilizer',
          'Improve field drainage',
          'Rotate fungicide types to prevent resistance',
        ],
        followUpDays: 12,
      ),
    },
    'ta': {
      'Healthy': const DiseaseTreatmentInfo(
        treatment:
            'நோய் எதுவும் கண்டறியப்படவில்லை. வழக்கமான பராமரிப்பைத் தொடரவும்.',
        prevention: [
          'சீரான நீர்ப்பாசனம் மற்றும் உரமிடுதல்',
          'நல்ல காற்றோட்டத்திற்காக வழக்கமாக கத்தரிக்கவும்',
          'ஆரம்ப அறிகுறிகளுக்காக வாரந்தோறும் பரிசோதிக்கவும்',
        ],
        followUpDays: 14,
      ),
      'Alternaria': const DiseaseTreatmentInfo(
        treatment:
            'பாதிக்கப்பட்ட பழங்கள், இலைகளை அகற்றி அழிக்கவும். செம்பு அடிப்படையிலான '
            'பூஞ்சைக்கொல்லியை 10-14 நாட்களுக்கு ஒருமுறை தெளிக்கவும்.',
        prevention: [
          'மேலிருந்து நீர் பாய்ச்சுவதைத் தவிர்க்கவும்',
          'கத்தரித்தல் மூலம் காற்றோட்டத்தை மேம்படுத்தவும்',
          'விழுந்த பாதிக்கப்பட்ட இலைகளை அகற்றவும்',
        ],
        followUpDays: 10,
      ),
      'Anthracnose': const DiseaseTreatmentInfo(
        treatment:
            'பாதிக்கப்பட்ட கிளைகள், பழங்களை கத்தரித்து அழிக்கவும். ஆரம்ப அறிகுறியில் '
            'பொருத்தமான பூஞ்சைக்கொல்லியை தெளிக்கவும்.',
        prevention: [
          'பழங்களை கையாளும்போது காயப்படுத்தாதீர்கள்',
          'கொத்துகளை நீர்த்துப்போக்கி ஈரப்பதத்தைக் குறைக்கவும்',
          'அறுவடை செய்த பழத்தை குளிர்ந்த இடத்தில் சேமிக்கவும்',
        ],
        followUpDays: 10,
      ),
      'Bacterial_Blight': const DiseaseTreatmentInfo(
        treatment:
            'பாதிக்கப்பட்ட பகுதிகளை அகற்றி எரிக்கவும். செம்பு அடிப்படையிலான '
            'பாக்டீரியா கொல்லியை தெளிக்கவும்; கருவிகளை தூய்மைப்படுத்தவும்.',
        prevention: [
          'ஈரமான வானிலையில் தோட்ட வேலை தவிர்க்கவும்',
          'நோய் இல்லாத நடவு பொருளைப் பயன்படுத்தவும்',
          'கருவிகளை தவறாமல் தூய்மைப்படுத்தவும்',
        ],
        followUpDays: 7,
      ),
      'Cercospora': const DiseaseTreatmentInfo(
        treatment:
            'கடுமையாக பாதிக்கப்பட்ட இலைகளை அகற்றி பூஞ்சைக்கொல்லியை தெளிக்கவும். '
            'நல்ல வடிகால் மற்றும் மிதமான நைட்ரஜன் உரமிடுதலை உறுதி செய்யவும்.',
        prevention: [
          'அதிக நைட்ரஜன் உரத்தைத் தவிர்க்கவும்',
          'வயல் வடிகாலை மேம்படுத்தவும்',
          'பூஞ்சைக்கொல்லி வகைகளை மாற்றி பயன்படுத்தவும்',
        ],
        followUpDays: 12,
      ),
    },
    'si': {
      'Healthy': const DiseaseTreatmentInfo(
        treatment: 'රෝගයක් හඳුනාගෙන නැත. සාමාන්‍ය රැකවරණය දිගටම කරගෙන යන්න.',
        prevention: [
          'සමතුලිත ජල සම්පාදනය සහ පොහොර යෙදීම පවත්වා ගන්න',
          'හොඳ වායු සංසරණය සඳහා නිතිපතා කප්පාදු කරන්න',
          'මුල් රෝග ලක්ෂණ සඳහා සතිපතා පරීක්ෂා කරන්න',
        ],
        followUpDays: 14,
      ),
      'Alternaria': const DiseaseTreatmentInfo(
        treatment:
            'බලපෑමට ලක් වූ ගෙඩි, කොළ ඉවත් කර විනාශ කරන්න. තඹ පදනම් වූ දිලීර නාශකයක් '
            'දින 10-14 කට වරක් ඉසින්න.',
        prevention: [
          'මතුපිට තෙත් කරන ජල සම්පාදනය වළක්වන්න',
          'කප්පාදුව මගින් වායු සංසරණය වැඩි දියුණු කරන්න',
          'වැටුණු බලපෑමට ලක් වූ කොළ ඉවත් කරන්න',
        ],
        followUpDays: 10,
      ),
      'Anthracnose': const DiseaseTreatmentInfo(
        treatment:
            'බලපෑමට ලක් වූ අතු, ගෙඩි කප්පාදු කර විනාශ කරන්න. මුල් අවධියේදීම '
            'සුදුසු දිලීර නාශකයක් ඉසින්න.',
        prevention: [
          'ගෙඩි හැසිරවීමේදී හානි නොකරන්න',
          'තුනීකරණය මගින් තෙතමනය අඩු කරන්න',
          'අස්වනු නෙළූ ගෙඩි සිසිල් ස්ථානයක ගබඩා කරන්න',
        ],
        followUpDays: 10,
      ),
      'Bacterial_Blight': const DiseaseTreatmentInfo(
        treatment:
            'බලපෑමට ලක් වූ කොටස් ඉවත් කර පුළුස්සන්න. තඹ පදනම් වූ බැක්ටීරියා නාශකයක් '
            'ඉසින්න; මෙවලම් නිසි ලෙස පිරිසිදු කරන්න.',
        prevention: [
          'තෙත් කාලගුණයේදී ගොවිපොළේ වැඩ කිරීම වළක්වන්න',
          'රෝග රහිත රෝපණ ද්‍රව්‍ය භාවිතා කරන්න',
          'මෙවලම් නිතිපතා පිරිසිදු කරන්න',
        ],
        followUpDays: 7,
      ),
      'Cercospora': const DiseaseTreatmentInfo(
        treatment:
            'දැඩි ලෙස පැල්ලම් වූ කොළ ඉවත් කර දිලීර නාශකයක් ඉසින්න. '
            'හොඳ ජලාපවහනය සහ මධ්‍යස්ථ නයිට්‍රජන් සහතික කරන්න.',
        prevention: [
          'අධික නයිට්‍රජන් පොහොර වළක්වන්න',
          'කෙත් ජලාපවහනය වැඩි දියුණු කරන්න',
          'දිලීර නාශක වර්ග මාරුවෙන් මාරුවට භාවිතා කරන්න',
        ],
        followUpDays: 12,
      ),
    },
  };
}
