class FarmerAccount {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final DateTime? createdAt;

  const FarmerAccount({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory FarmerAccount.fromJson(String id, Map<String, dynamic> json) {
    return FarmerAccount(
      id: id,
      fullName: (json['fullName'] ?? json['full_name'])?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      createdAt: _parseTime(json['createdAt']),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.tryParse(value.toString());
    }
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
