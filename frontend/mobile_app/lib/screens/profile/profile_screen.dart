import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../common/common_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../models/farmer_account.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../login_screen.dart';

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
          bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.profile),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: BrandColor.primary),
                )
              : RefreshIndicator(
                  color: BrandColor.primary,
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                    children: [
                      if (_error != null && farmer == null)
                        AppBanner(
                          message: _error!,
                          color: BrandColor.primary,
                          icon: Icons.error_outline,
                        )
                      else if (farmer != null) ...[
                        _avatar(farmer),
                        const SizedBox(height: 16),
                        Text(
                          farmer.fullName.isEmpty ? t('profile') : farmer.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: BrandColor.darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          farmer.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: BrandColor.lightText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _info(Icons.person_outline, t('farmerName'), farmer.fullName),
                        _info(Icons.email_outlined, t('email'), farmer.email),
                        _info(Icons.phone_outlined, t('mobile'), farmer.mobile),
                        const SizedBox(height: 8),
                        AppPrimaryButton(
                          label: t('editProfile'),
                          icon: Icons.edit_outlined,
                          onPressed: _editProfile,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t('language'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _languageRow(),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(t('logout')),
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
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _avatar(FarmerAccount farmer) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          color: BrandColor.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            farmer.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColor.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: BrandColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: BrandColor.lightText),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageRow() {
    final current = LanguageController.instance.lang;
    return Row(
      children: [
        _langChip('EN', AppLang.en, current == AppLang.en),
        const SizedBox(width: 8),
        _langChip('සි', AppLang.si, current == AppLang.si),
        const SizedBox(width: 8),
        _langChip('த', AppLang.ta, current == AppLang.ta),
      ],
    );
  }

  Widget _langChip(String label, AppLang lang, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => LanguageController.instance.setLang(lang),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? BrandColor.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? BrandColor.primary : BrandColor.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : BrandColor.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('profileUpdated'))),
    );
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
            backgroundColor: Colors.white,
            foregroundColor: BrandColor.darkText,
            elevation: 0,
            title: Text(
              t('editProfile'),
              style: const TextStyle(
                color: BrandColor.darkText,
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
                      const Icon(Icons.email_outlined, color: BrandColor.primary),
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
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
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
