import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/farmer_account.dart';
import '../firebase/firestore_service.dart';

/// Firebase Authentication for separate farmer accounts.
/// Passwords are stored by Firebase Auth, never in Firestore.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FarmerAccount? currentFarmer;

  bool get isConfigured => Firebase.apps.isNotEmpty;
  bool get isLoggedIn =>
      isConfigured && _auth.currentUser != null && currentFarmer != null;
  String? get uid => isConfigured ? _auth.currentUser?.uid : null;

  Future<void> loadSession() async {
    if (!isConfigured) {
      currentFarmer = null;
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      currentFarmer = null;
      return;
    }
    currentFarmer = await FirestoreService.instance.getUser(user.uid);
    currentFarmer ??= FarmerAccount(
      id: user.uid,
      fullName: user.displayName ?? '',
      mobile: '',
      email: user.email ?? '',
    );
    try {
      await FirestoreService.instance.ensureDefaultFarm(
        farmerId: user.uid,
        farmName: currentFarmer!.fullName.isEmpty
            ? 'My Farm'
            : "${currentFarmer!.fullName}'s Farm",
      );
      currentFarmer = await FirestoreService.instance.getUser(user.uid) ??
          currentFarmer;
    } catch (e) {
      debugPrint('ensureDefaultFarm failed: $e');
    }
  }

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

    if (password.isEmpty) {
      errors['password'] = 'Password is required.';
    } else if (password.length < 8) {
      errors['password'] = 'Password must be at least 8 characters.';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      errors['password'] = 'Password must include letters and numbers.';
    }

    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Please confirm your password.';
    } else if (confirmPassword != password) {
      errors['confirmPassword'] = 'Passwords do not match.';
    }

    return AuthValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }

  AuthValidationResult validateLogin({
    required String email,
    required String password,
  }) {
    final errors = <String, String>{};
    if (!_validEmail(email.trim())) {
      errors['email'] = 'Enter the email address you registered with.';
    }
    if (password.isEmpty) {
      errors['password'] = 'Enter your password.';
    }
    return AuthValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }

  AuthValidationResult validatePasswordReset({required String email}) {
    final errors = <String, String>{};
    if (!_validEmail(email.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
    return AuthValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }

  Future<String?> register({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      return 'Firebase is not configured. Restart the app after a full rebuild.';
    }

    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final cleanMobile = mobile.trim();

    try {
      User? user;
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        user = credential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') {
          return _authMessage(e);
        }
        // Auth user was created on a previous tap, then Firestore failed.
        // Sign in with the same password and finish the profile.
        try {
          final credential = await _auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
          user = credential.user;
        } on FirebaseAuthException {
          return 'An account with this email already exists. Please log in.';
        }
      }

      if (user == null) {
        return 'Could not create the farmer account. Please try again.';
      }

      try {
        await user.updateDisplayName(cleanName);
      } catch (e) {
        debugPrint('updateDisplayName failed: $e');
      }

      final farmer = FarmerAccount(
        id: user.uid,
        fullName: cleanName,
        mobile: cleanMobile,
        email: cleanEmail,
        createdAt: DateTime.now().toUtc(),
      );
      currentFarmer = farmer;
      await _saveProfileBestEffort(farmer);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Register error: $e');
      if (currentFarmer != null && _auth.currentUser != null) {
        return null;
      }
      return 'Could not create the account. Check your internet connection.';
    }
  }

  Future<void> _saveProfileBestEffort(FarmerAccount farmer) async {
    try {
      await FirestoreService.instance.saveUser(farmer);
    } catch (e) {
      debugPrint('saveUser failed: $e');
    }
    try {
      await FirestoreService.instance.ensureDefaultFarm(
        farmerId: farmer.id,
        farmName: farmer.fullName.isEmpty
            ? 'My Farm'
            : "${farmer.fullName}'s Farm",
      );
      currentFarmer =
          await FirestoreService.instance.getUser(farmer.id) ?? farmer;
    } catch (e) {
      debugPrint('ensureDefaultFarm failed: $e');
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      return 'Firebase is not configured. Restart the app after a full rebuild.';
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return 'Login failed. Please try again.';
      }

      currentFarmer = await FirestoreService.instance.getUser(user.uid);
      currentFarmer ??= FarmerAccount(
        id: user.uid,
        fullName: user.displayName ?? '',
        mobile: '',
        email: user.email ?? email.trim().toLowerCase(),
      );
      await _saveProfileBestEffort(currentFarmer!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Could not log in. Check your internet connection.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    if (!isConfigured) {
      return 'Firebase is not configured. Restart the app after a full rebuild.';
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Could not send the reset email. Check your internet connection.';
    }
  }

  Future<void> logout() async {
    if (isConfigured) {
      await _auth.signOut();
    }
    currentFarmer = null;
  }

  bool _validEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _validMobile(String mobile) {
    final compact = mobile.replaceAll(' ', '');
    return RegExp(r'^(\+94|0)?7\d{8}$').hasMatch(compact) ||
        RegExp(r'^\+?\d{9,12}$').hasMatch(compact);
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with letters and numbers.';
      case 'user-not-found':
        return 'No farmer account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This farmer account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Connect to the internet to sign in.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not enabled for this project yet.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
