import 'package:flutter/material.dart';
import '../../common/brand_color.dart';

// Bilingual string set
class _LangStrings {
  final String profile;
  final String farmName;
  final String subtitle;
  final String location;
  final String locationValue;
  final String cropType;
  final String cropValue;
  final String aiModel;
  final String aiValue;
  final String language;
  final String languageValue;

  const _LangStrings({
    required this.profile,
    required this.farmName,
    required this.subtitle,
    required this.location,
    required this.locationValue,
    required this.cropType,
    required this.cropValue,
    required this.aiModel,
    required this.aiValue,
    required this.language,
    required this.languageValue,
  });
}

const _english = _LangStrings(
  profile: 'Profile',
  farmName: 'Pomegranate Farm',
  subtitle: 'AI-Based Intelligent Farming System',
  location: 'Location',
  locationValue: 'Sri Lanka',
  cropType: 'Crop Type',
  cropValue: 'Pomegranate',
  aiModel: 'AI Model',
  aiValue: 'Disease Detection v1.0',
  language: 'Language',
  languageValue: 'English',
);

const _tamil = _LangStrings(
  profile: 'சுயவிவரம்',
  farmName: 'மாதுளை பண்ணை',
  subtitle: 'AI அடிப்படையிலான நுண்ணிய விவசாய அமைப்பு',
  location: 'இடம்',
  locationValue: 'இலங்கை',
  cropType: 'பயிர் வகை',
  cropValue: 'மாதுளை',
  aiModel: 'AI மாதிரி',
  aiValue: 'நோய் கண்டறிதல் v1.0',
  language: 'மொழி',
  languageValue: 'தமிழ்',
);

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isTamil = false;

  _LangStrings get _s => _isTamil ? _tamil : _english;

  void _toggleLanguage() => setState(() => _isTamil = !_isTamil);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _s.profile,
          style: const TextStyle(
            color: BrandColor.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // AppBar language toggle chip
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _toggleLanguage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: BrandColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BrandColor.primary.withOpacity(0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      _isTamil ? 'EN' : 'த',
                      style: const TextStyle(
                        color: BrandColor.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BrandColor.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: BrandColor.primary.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'PK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _s.farmName,
              style: const TextStyle(
                color: BrandColor.darkText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _s.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: BrandColor.lightText, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // Language switch card
            _LanguageCard(
              isTamil: _isTamil,
              label: _s.language,
              currentLang: _s.languageValue,
              onToggle: _toggleLanguage,
            ),
            const SizedBox(height: 12),

            // Info cards
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: _s.location,
              value: _s.locationValue,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.eco_outlined,
              label: _s.cropType,
              value: _s.cropValue,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.smart_toy_outlined,
              label: _s.aiModel,
              value: _s.aiValue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language switch card ──────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final bool isTamil;
  final String label;
  final String currentLang;
  final VoidCallback onToggle;

  const _LanguageCard({
    required this.isTamil,
    required this.label,
    required this.currentLang,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Center(
              child: Text('🌐', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),

          // Label + current language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: BrandColor.softText, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  currentLang,
                  style: const TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // EN / த toggle pill
          GestureDetector(
            onTap: onToggle,
            child: Container(
              decoration: BoxDecoration(
                color: BrandColor.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: BrandColor.primary.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangPill(label: 'EN', active: !isTamil),
                  _LangPill(label: 'த', active: isTamil),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;

  const _LangPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? BrandColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : BrandColor.primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Shared info row ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: BrandColor.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: BrandColor.softText, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
