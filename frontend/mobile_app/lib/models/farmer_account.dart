class FarmerAccount {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String passwordHash;
  final String passwordSalt;

  const FarmerAccount({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
    };
  }

  factory FarmerAccount.fromJson(Map<String, dynamic> json) {
    return FarmerAccount(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['password_hash']?.toString() ?? '',
      passwordSalt: json['password_salt']?.toString() ?? '',
    );
  }
}

class AuthValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;

  const AuthValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
  });
}
