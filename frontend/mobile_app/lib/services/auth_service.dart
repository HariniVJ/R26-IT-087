import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farmer_account.dart';

/// Offline farmer accounts stored only on this phone.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _farmersKey = 'farmer_accounts';
  static const _sessionKey = 'current_farmer_id';

  FarmerAccount? currentFarmer;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionKey);
    if (id == null) {
      currentFarmer = null;
      return;
    }
    final farmers = await _readFarmers();
    currentFarmer = farmers.where((f) => f.id == id).firstOrNull;
  }

  bool get isLoggedIn => currentFarmer != null;

  AuthValidationResult validateRegistration({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <String, String>{};

    if (fullName.trim().length < 2) {
      errors['fullName'] = 'Please enter your full name.';
    }

    final mobileClean = mobile.trim();
    if (!_validMobile(mobileClean)) {
      errors['mobile'] =
          'Enter a valid mobile number. Example: 0771234567 or +94771234567.';
    }

    if (!_validEmail(email.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }

    if (password.length < 8) {
      errors['password'] = 'Password must be at least 8 characters.';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      errors['password'] = 'Password must include letters and numbers.';
    }

    if (confirmPassword != password) {
      errors['confirmPassword'] = 'Passwords do not match.';
    }

    return AuthValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }

  AuthValidationResult validateLogin({
    required String identifier,
    required String password,
  }) {
    final errors = <String, String>{};
    if (identifier.trim().isEmpty) {
      errors['identifier'] = 'Enter your email or mobile number.';
    }
    if (password.isEmpty) {
      errors['password'] = 'Enter your password.';
    }
    return AuthValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }

  Future<String?> register({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
  }) async {
    final farmers = await _readFarmers();
    final emailLower = email.trim().toLowerCase();
    final mobileClean = mobile.trim();

    if (farmers.any((f) => f.email.toLowerCase() == emailLower)) {
      return 'An account with this email already exists.';
    }
    if (farmers.any((f) => f.mobile == mobileClean)) {
      return 'An account with this mobile number already exists.';
    }

    final salt = _randomSalt();
    final farmer = FarmerAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName.trim(),
      mobile: mobileClean,
      email: emailLower,
      passwordSalt: salt,
      passwordHash: _hashPassword(password, salt),
    );

    farmers.add(farmer);
    await _writeFarmers(farmers);
    await _setSession(farmer);
    return null;
  }

  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    final farmers = await _readFarmers();
    final key = identifier.trim().toLowerCase();
    final farmer = farmers
        .where(
          (f) => f.email.toLowerCase() == key || f.mobile == identifier.trim(),
        )
        .firstOrNull;

    if (farmer == null) {
      return 'No farmer account found for that email or mobile number.';
    }

    final hash = _hashPassword(password, farmer.passwordSalt);
    if (hash != farmer.passwordHash) {
      return 'Incorrect password.';
    }

    await _setSession(farmer);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    currentFarmer = null;
  }

  Future<List<FarmerAccount>> _readFarmers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_farmersKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => FarmerAccount.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeFarmers(List<FarmerAccount> farmers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _farmersKey,
      jsonEncode(farmers.map((f) => f.toJson()).toList()),
    );
  }

  Future<void> _setSession(FarmerAccount farmer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, farmer.id);
    currentFarmer = farmer;
  }

  bool _validEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _validMobile(String mobile) {
    final compact = mobile.replaceAll(' ', '');
    return RegExp(r'^(\+94|0)?7\d{8}$').hasMatch(compact) ||
        RegExp(r'^\+?\d{9,12}$').hasMatch(compact);
  }

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }
}
