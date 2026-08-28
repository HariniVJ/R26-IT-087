import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../auth/login_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String get _initials {
    final name = AuthService.instance.currentFarmer?.fullName ?? 'AK';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance.lang;
        return Scaffold(
          backgroundColor: BrandColor.background,
          bottomNavigationBar:
              const AppBottomNavBar(current: AppNavTab.profile),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
            title: Text(
              t('profile'),
              style: const TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AuthService.instance.currentFarmer?.fullName ?? t('profile'),
                  style: const TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BrandColor.lightText, fontSize: 13),
                ),
                const SizedBox(height: 32),
                _LanguageCard(current: lang),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: t('email'),
                  value: AuthService.instance.currentFarmer?.email ?? '-',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: t('mobile'),
                  value: AuthService.instance.currentFarmer?.mobile ?? '-',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: t('location'),
                  value: t('sriLanka'),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.eco_outlined,
                  label: t('cropType'),
                  value: t('cropValue'),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.smart_toy_outlined,
                  label: t('aiModel'),
                  value: 'PomCare v1.0',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService.instance.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(
                      t('logout'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BrandColor.primary,
                      side: const BorderSide(color: BrandColor.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final AppLang current;

  const _LanguageCard({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('language'),
            style: TextStyle(color: BrandColor.softText, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill('EN', t('english'), AppLang.en, current == AppLang.en),
              const SizedBox(width: 8),
              _pill('සි', t('sinhala'), AppLang.si, current == AppLang.si),
              const SizedBox(width: 8),
              _pill('த', t('tamil'), AppLang.ta, current == AppLang.ta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String short, String label, AppLang value, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => LanguageController.instance.setLang(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? BrandColor.primary
                : BrandColor.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                short,
                style: TextStyle(
                  color: active ? Colors.white : BrandColor.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : BrandColor.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
