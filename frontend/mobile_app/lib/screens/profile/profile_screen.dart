import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/farmer_account.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../login_screen.dart';

/// Profile page — header with avatar, account details, language picker
/// and logout. Language change here updates the WHOLE app (including the
/// disease module, which follows this controller).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FarmerAccount? _farmer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.loadSession();
      final farmer = AuthService.instance.currentFarmer;
      if (!mounted) return;
      setState(() {
        _farmer = farmer;
        _loading = false;
        if (farmer == null) _error = t('notLoggedIn');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _farmer = AuthService.instance.currentFarmer;
        _loading = false;
        _error = t('profileUpdateFailed');
      });
    }
  }

  Future<void> _editProfile() async {
    final farmer = _farmer;
    if (farmer == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(farmer: farmer)),
    );
    if (updated == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        final farmer = _farmer;
        return Scaffold(
          backgroundColor: BrandColor.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: BrandColor.darkText,
            elevation: 0,
            title: Text(
              t('profile'),
              style: const TextStyle(
                color: BrandColor.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(
            current: AppNavTab.profile,
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: BrandColor.primary),
                )
              : RefreshIndicator(
                  color: BrandColor.primary,
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      if (_error != null && farmer == null)
                        AppBanner(
                          message: _error!,
                          color: BrandColor.primary,
                          icon: Icons.error_outline,
                        )
                      else if (farmer != null) ...[
                        _header(farmer),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Account details ──
                            _sectionTitle(
                              Icons.badge_outlined,
                              t('accountInfo'),
                            ),
                            const SizedBox(height: 10),
                            _detailsCard(farmer),
                            const SizedBox(height: 24),

                            // ── Language ──
                            _sectionTitle(
                              Icons.translate_rounded,
                              t('language'),
                            ),
                            const SizedBox(height: 10),
                            _languageSelector(),
                            const SizedBox(height: 28),

                            // ── Logout ──
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(
                                  t('logout'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: BrandColor.primary,
                                  side: const BorderSide(
                                    color: BrandColor.primary,
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ── Header: compact white card — avatar, name, email, edit button ──
  Widget _header(FarmerAccount farmer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandColor.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: BrandColor.primary,
            child: Text(
              farmer.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmer.fullName.isEmpty ? t('profile') : farmer.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: BrandColor.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  farmer.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BrandColor.lightText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: BrandColor.primary.withOpacity(0.08),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: t('editProfile'),
              onPressed: _editProfile,
              icon: const Icon(
                Icons.edit_outlined,
                color: BrandColor.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: BrandColor.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: BrandColor.darkText,
          ),
        ),
      ],
    );
  }

  // ── One card with all details, divided rows ──
  Widget _detailsCard(FarmerAccount farmer) {
    final rows = [
      (Icons.person_outline, t('farmerName'), farmer.fullName),
      (Icons.email_outlined, t('email'), farmer.email),
      (Icons.phone_outlined, t('mobile'), farmer.mobile),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColor.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 64, color: BrandColor.border),
            _detailRow(rows[i].$1, rows[i].$2, rows[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BrandColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BrandColor.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: BrandColor.lightText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '--' : value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: BrandColor.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented language selector (full language names) ──
  Widget _languageSelector() {
    final current = LanguageController.instance.lang;
    const options = [
      ('English', AppLang.en),
      ('සිංහල', AppLang.si),
      ('தமிழ்', AppLang.ta),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        children: [
          for (final (label, lang) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => LanguageController.instance.setLang(lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: current == lang
                        ? BrandColor.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (current == lang) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: current == lang
                                ? Colors.white
                                : BrandColor.darkText,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  EDIT PROFILE (unchanged logic)
// ═══════════════════════════════════════════════════════════════════════════
class EditProfileScreen extends StatefulWidget {
  final FarmerAccount farmer;

  const EditProfileScreen({super.key, required this.farmer});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  Map<String, String> _errors = {};
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farmer.fullName);
    _mobileController = TextEditingController(text: widget.farmer.mobile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final validation = AuthService.instance.validateProfile(
      fullName: _nameController.text,
      mobile: _mobileController.text,
    );
    if (!validation.isValid) {
      setState(() {
        _errors = validation.fieldErrors;
        _formError = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errors = {};
      _formError = null;
    });

    final error = await AuthService.instance.updateProfile(
      fullName: _nameController.text,
      mobile: _mobileController.text,
      location: widget.farmer.location,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _formError = error;
      });
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('profileUpdated'))));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BrandColor.background,
          appBar: AppBar(
            backgroundColor: BrandColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              t('editProfile'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
            child: Column(
              children: [
                AppTextField(
                  label: t('farmerName'),
                  controller: _nameController,
                  icon: Icons.person_outline,
                  errorText: _errors['fullName'],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: t('mobile'),
                  controller: _mobileController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  errorText: _errors['mobile'],
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: BrandColor.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('email'),
                              style: const TextStyle(
                                color: BrandColor.lightText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.farmer.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: BrandColor.lightText,
                      ),
                    ],
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  AppBanner(
                    message: _formError!,
                    color: BrandColor.primary,
                    icon: Icons.error_outline,
                  ),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: t('saveProfile'),
                  icon: Icons.check,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
